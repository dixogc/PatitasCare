package com.kmd.patitas_care.infraestructure.repository.jpa.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.domain.repository.VeterinariaRepository;
import com.kmd.patitas_care.utils.GeolocationUtils;
import org.springframework.beans.factory.annotation.Value;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Repository;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Repository
@Slf4j
public class OpenStreetMapVeterinariaRepository implements VeterinariaRepository {
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private static final String OVERPASS_URL = "https://overpass-api.de/api/interpreter";

    public OpenStreetMapVeterinariaRepository(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }

    @Override
    public List<Veterinaria> buscarVeterinariosCercanos(double latitud, double longitud, int radioKm) {
        try {
            String query = construirQuery(latitud, longitud, radioKm);
            log.info("Consultando OpenStreetMap con query: {}", query);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.TEXT_PLAIN);
            HttpEntity<String> request = new HttpEntity<>(query, headers);

            String response = restTemplate.postForObject(OVERPASS_URL, request, String.class);
            return procesarRespuesta(response, latitud, longitud);

        } catch (Exception e) {
            log.error("Error consultando OpenStreetMap", e);
            throw new RuntimeException("Error al consultar OpenStreetMap: " + e.getMessage(), e);
        }
    }

    private String construirQuery(double latitud, double longitud, int radioKm) {
        int radioMetros = radioKm * 1000;
        return String.format(
                "[out:json][timeout:25];\n" +
                        "(\n" +
                        "  node[\"amenity\"=\"veterinary\"](around:%d,%f,%f);\n" +
                        "  way[\"amenity\"=\"veterinary\"](around:%d,%f,%f);\n" +
                        "  relation[\"amenity\"=\"veterinary\"](around:%d,%f,%f);\n" +
                        ");\n" +
                        "out center meta;",
                radioMetros, latitud, longitud,
                radioMetros, latitud, longitud,
                radioMetros, latitud, longitud
        );
    }

    private List<Veterinaria> procesarRespuesta(String response, double latitudBusqueda, double longitudBusqueda) {
        try {
            JsonNode root = objectMapper.readTree(response);
            List<Veterinaria> veterinarias = new ArrayList<>();

            JsonNode elements = root.get("elements");
            if (elements != null && elements.isArray()) {
                for (JsonNode element : elements) {
                    Veterinaria veterinaria = extraerVeterinaria(element, latitudBusqueda, longitudBusqueda);
                    if (veterinaria != null) {
                        veterinarias.add(veterinaria);
                    }
                }
            }

            return veterinarias.stream()
                    .sorted(Comparator.comparingDouble(Veterinaria::getDistancia))
                    .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Error procesando respuesta de OpenStreetMap", e);
            throw new RuntimeException("Error procesando respuesta de OSM", e);
        }
    }

    private Veterinaria extraerVeterinaria(JsonNode element, double latitudBusqueda, double longitudBusqueda) {
        try {
            JsonNode tags = element.get("tags");
            if (tags == null) {
                return null;
            }

            // Obtener coordenadas
            double lat = obtenerLatitud(element);
            double lon = obtenerLongitud(element);

            if (lat == 0.0 && lon == 0.0) {
                return null; // Coordenadas inválidas
            }

            // Extraer información de las etiquetas
            String nombre = obtenerTextoSeguro(tags, "name");
            String direccion = construirDireccion(tags);
            String telefono = obtenerTextoSeguro(tags, "phone");
            String horario = obtenerTextoSeguro(tags, "opening_hours");
            String tipo = determinarTipo(tags);

            double distancia = GeolocationUtils.calcularDistancia(latitudBusqueda, longitudBusqueda, lat, lon);

            return Veterinaria.builder()
                    .nombre(nombre.equals("No disponible") ? "Veterinaria" : nombre)
                    .direccion(direccion)
                    .latitud(lat)
                    .longitud(lon)
                    .telefono(telefono)
                    .horario(horario)
                    .distancia(distancia)
                    .tipo(tipo)
                    .build();

        } catch (Exception e) {
            log.warn("Error extrayendo veterinaria de elemento OSM", e);
            return null;
        }
    }

    private double obtenerLatitud(JsonNode element) {
        // Para nodos, lat está directamente disponible
        if (element.has("lat")) {
            return element.get("lat").asDouble();
        }
        // Para ways y relations, usar center si está disponible
        if (element.has("center") && element.get("center").has("lat")) {
            return element.get("center").get("lat").asDouble();
        }
        return 0.0;
    }

    private double obtenerLongitud(JsonNode element) {
        // Para nodos, lon está directamente disponible
        if (element.has("lon")) {
            return element.get("lon").asDouble();
        }
        // Para ways y relations, usar center si está disponible
        if (element.has("center") && element.get("center").has("lon")) {
            return element.get("center").get("lon").asDouble();
        }
        return 0.0;
    }

    private String construirDireccion(JsonNode tags) {
        StringBuilder direccion = new StringBuilder();

        // Número de casa
        String numero = obtenerTextoSeguro(tags, "addr:housenumber");
        if (!numero.equals("No disponible")) {
            direccion.append(numero).append(" ");
        }

        // Calle
        String calle = obtenerTextoSeguro(tags, "addr:street");
        if (!calle.equals("No disponible")) {
            direccion.append(calle);
        }

        // Colonia/Barrio
        String colonia = obtenerTextoSeguro(tags, "addr:suburb");
        if (!colonia.equals("No disponible")) {
            if (direccion.length() > 0) direccion.append(", ");
            direccion.append(colonia);
        }

        // Ciudad
        String ciudad = obtenerTextoSeguro(tags, "addr:city");
        if (!ciudad.equals("No disponible")) {
            if (direccion.length() > 0) direccion.append(", ");
            direccion.append(ciudad);
        }

        return direccion.length() > 0 ? direccion.toString() : "Dirección no disponible";
    }

    private String obtenerTextoSeguro(JsonNode node, String path) {
        if (node == null || !node.has(path)) {
            return "No disponible";
        }
        return node.get(path).asText("No disponible");
    }

    private String determinarTipo(JsonNode tags) {
        // Revisar si hay información específica sobre el tipo de veterinaria
        if (tags.has("veterinary:treats:dogs") && tags.get("veterinary:treats:dogs").asText().equals("yes")) {
            if (tags.has("veterinary:treats:cats") && tags.get("veterinary:treats:cats").asText().equals("yes")) {
                return "Veterinaria para perros y gatos";
            }
            return "Veterinaria para perros";
        }

        if (tags.has("veterinary:treats:cats") && tags.get("veterinary:treats:cats").asText().equals("yes")) {
            return "Veterinaria para gatos";
        }

        if (tags.has("veterinary:treats:large_animals") && tags.get("veterinary:treats:large_animals").asText().equals("yes")) {
            return "Veterinaria para animales grandes";
        }

        return "Veterinaria";
    }
}
