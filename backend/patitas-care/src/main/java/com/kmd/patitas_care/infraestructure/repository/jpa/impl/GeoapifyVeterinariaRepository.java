package com.kmd.patitas_care.infraestructure.repository.jpa.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.domain.repository.VeterinariaRepository;
import com.kmd.patitas_care.utils.GeolocationUtils;
import org.springframework.beans.factory.annotation.Value;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Repository;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Repository
@Slf4j
public class GeoapifyVeterinariaRepository implements VeterinariaRepository {
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    @Value("${GEO_API}")
    private String geoApiKey;

    private static final String GEOAPIFY_URL = "https://api.geoapify.com/v2/places";

    public GeoapifyVeterinariaRepository(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }
    @Override
    public List<Veterinaria> buscarVeterinariosCercanos(double latitud, double longitud, int radioKm) {
        try {
            validarApiKey();
            String url = construirUrl(latitud, longitud, radioKm);
            log.info("Consultando Geoapify: {}", url);

            String response = restTemplate.getForObject(url, String.class);
            return procesarRespuesta(response, latitud, longitud);

        } catch (Exception e) {
            log.error("Error consultando Geoapify", e);
            throw new RuntimeException("Error al consultar Geoapify: " + e.getMessage(), e);
        }
    }

    private void validarApiKey() {
        if (geoApiKey == null || geoApiKey.trim().isEmpty()) {
            throw new IllegalStateException("API Key de Geoapify no configurada");
        }
    }

    private String construirUrl(double latitud, double longitud, int radioKm) {
        int radioMetros = radioKm * 1000;
        return String.format(
                "%s?categories=healthcare.veterinary&filter=circle:%f,%f,%d&bias=proximity:%f,%f&limit=20&apiKey=%s",
                GEOAPIFY_URL, longitud, latitud, radioMetros, longitud, latitud, geoApiKey
        );
    }

    private List<Veterinaria> procesarRespuesta(String response, double latitudBusqueda, double longitudBusqueda) {
        try {
            JsonNode root = objectMapper.readTree(response);
            List<Veterinaria> veterinarias = new ArrayList<>();

            JsonNode features = root.get("features");
            if (features != null && features.isArray()) {
                for (JsonNode feature : features) {
                    Veterinaria veterinaria = extraerVeterinaria(feature, latitudBusqueda, longitudBusqueda);
                    if (veterinaria != null) {
                        veterinarias.add(veterinaria);
                    }
                }
            }

            return veterinarias.stream()
                    .sorted(Comparator.comparingDouble(Veterinaria::getDistancia))
                    .collect(Collectors.toList());

        } catch (Exception e) {
            log.error("Error procesando respuesta de Geoapify", e);
            throw new RuntimeException("Error procesando respuesta de API", e);
        }
    }

    private Veterinaria extraerVeterinaria(JsonNode feature, double latitudBusqueda, double longitudBusqueda) {
        try {
            JsonNode props = feature.get("properties");
            JsonNode geometry = feature.get("geometry");

            if (geometry == null || geometry.get("coordinates") == null) {
                return null;
            }

            String nombre = obtenerTextoSeguro(props, "name");
            String direccion = obtenerTextoSeguro(props, "formatted");
            String telefono = obtenerTextoSeguro(props, "datasource", "raw", "phone");
            String horario = obtenerTextoSeguro(props, "opening_hours");
            String tipo = obtenerCategoria(props);

            double lat = geometry.get("coordinates").get(1).asDouble();
            double lon = geometry.get("coordinates").get(0).asDouble();

            double distancia = GeolocationUtils.calcularDistancia(latitudBusqueda, longitudBusqueda, lat, lon);

            return Veterinaria.builder()
                    .nombre(nombre)
                    .direccion(direccion)
                    .latitud(lat)
                    .longitud(lon)
                    .telefono(telefono)
                    .horario(horario)
                    .distancia(distancia)
                    .tipo(tipo)
                    .build();

        } catch (Exception e) {
            log.warn("Error extrayendo veterinaria de feature", e);
            return null;
        }
    }

    private String obtenerTextoSeguro(JsonNode node, String... paths) {
        JsonNode current = node;
        for (String path : paths) {
            if (current == null || !current.has(path)) {
                return "No disponible";
            }
            current = current.get(path);
        }
        return current.asText("No disponible");
    }

    private String obtenerCategoria(JsonNode props) {
        JsonNode categories = props.get("categories");
        if (categories != null && categories.isArray() && categories.size() > 0) {
            return categories.get(0).asText("Veterinaria");
        }
        return "Veterinaria";
    }
}
