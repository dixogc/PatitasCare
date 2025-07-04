package com.kmd.patitas_care.infraestructure.repository.jpa.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.domain.repository.VeterinariaRepository;
import com.kmd.patitas_care.utils.GeolocationUtils;
import org.springframework.stereotype.Repository;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Repository
public class GeopifyVeterinariaRepository implements VeterinariaRepository {
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;

    private static final String GEO_API = "${GEO_API}";
    private static final String GEOAPIFY_URL = "https://api.geoapify.com/v2/places";

    public GeopifyVeterinariaRepository(RestTemplate restTemplate, ObjectMapper objectMapper) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
    }
    @Override
    public List<Veterinaria> buscarVeterinariosCercanos(double latitud, double longitud, int radioKm) {
        try {
            int radioMetros = radioKm * 1000;
            String url = String.format(
                    "%s?categories=healthcare.veterinary&filter=circle:%f,%f,%d&bias=proximity:%f,%f&limit=20&apiKey=%s",
                    GEOAPIFY_URL, longitud, latitud, radioMetros, longitud, latitud, GEO_API
            );

            String response = restTemplate.getForObject(url, String.class);
            JsonNode root = objectMapper.readTree(response);

            List<Veterinaria> lista = new ArrayList<>();
            JsonNode features = root.get("features");
            if (features != null) {
                for (JsonNode feature : features) {
                    JsonNode props = feature.get("properties");
                    JsonNode geometry = feature.get("geometry");

                    String nombre = props.path("name").asText(null);
                    String direccion = props.path("formatted").asText(null);
                    String telefono = props.path("tel").asText(null);
                    String horario = props.path("opening_hours").asText(null);
                    String tipo = props.path("categories").get(0).asText(null);

                    double lat = geometry.get("coordinates").get(1).asDouble();
                    double lon = geometry.get("coordinates").get(0).asDouble();

                    double distancia = GeolocationUtils.calcularDistancia(latitud, longitud, lat, lon);

                    Veterinaria v = new Veterinaria(nombre, direccion, lat, lon, telefono, horario, distancia, tipo);
                    lista.add(v);
                }
            }

            // Ordenar por distancia
            lista.sort(Comparator.comparingDouble(Veterinaria::getDistancia));
            return lista;

        } catch (Exception e) {
            throw new RuntimeException("Error al consultar Geoapify: " + e.getMessage(), e);
        }
    }
}
