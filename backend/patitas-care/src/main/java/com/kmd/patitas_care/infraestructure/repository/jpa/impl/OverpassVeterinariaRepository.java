package com.kmd.patitas_care.infraestructure.repository.jpa.impl;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.domain.repository.VeterinariaRepository;
import com.kmd.patitas_care.domain.service.VeterinariaService;
import org.springframework.http.*;
import org.springframework.stereotype.Repository;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Repository
public class OverpassVeterinariaRepository implements VeterinariaRepository {
    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper;
    private final VeterinariaService veterinariaService;

    private static final String OVERPASS_URL = "https://overpass-api.de/api/interpreter";

    public OverpassVeterinariaRepository(RestTemplate restTemplate, ObjectMapper objectMapper, VeterinariaService veterinariaService) {
        this.restTemplate = restTemplate;
        this.objectMapper = objectMapper;
        this.veterinariaService = veterinariaService;
    }

    @Override
    public List<Veterinaria> buscarVeterinariosCercanos(double latitud, double longitud, int radio) {
        try {
            // Convertir el radio de km a grados aproximados
            double radiusInMeters = radio * 1000;

            String query = """
                [out:json];
                node
                  ["amenity"="veterinary"]
                  (around:%s,%s,%s);
                out body;
            """.formatted((int) radiusInMeters, latitud, longitud);

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_FORM_URLENCODED);
            HttpEntity<String> entity = new HttpEntity<>("data=" + URLEncoder.encode(query, StandardCharsets.UTF_8), headers);

            ResponseEntity<String> response = restTemplate.exchange(
                    OVERPASS_URL,
                    HttpMethod.POST,
                    entity,
                    String.class
            );

            JsonNode root = objectMapper.readTree(response.getBody());
            ArrayNode elements = (ArrayNode) root.path("elements");

            List<Veterinaria> veterinarias = new ArrayList<>();

            for (JsonNode node : elements) {
                double lat = node.path("lat").asDouble();
                double lon = node.path("lon").asDouble();
                JsonNode tags = node.path("tags");

                String nombre = extraerCampo(tags, "name", "operator");
                String direccion = extraerCampo(tags, "addr:full", "addr:street");
                String telefono = extraerCampo(tags, "phone", "contact:phone");
                String horario = extraerCampo(tags, "opening_hours");
                String tipo = extraerCampo(tags, "amenity");

                double distancia = veterinariaService.calcularDistancia(latitud, longitud, lat, lon);

                Veterinaria veterinaria = new Veterinaria(
                        nombre, direccion, lat, lon, telefono, horario, distancia, tipo
                );

                if (distancia <= radio) {
                    veterinarias.add(veterinaria);
                }
            }

            veterinarias.sort(Comparator.comparingDouble(Veterinaria::getDistancia));
            return veterinarias;

        } catch (Exception e) {
            throw new RuntimeException("Error al consultar Overpass API: " + e.getMessage(), e);
        }
    }

    private String extraerCampo(JsonNode node, String... campos) {
        for (String campo : campos) {
            JsonNode fieldNode = node.get(campo);
            if (fieldNode != null && !fieldNode.isNull()) {
                return fieldNode.asText();
            }
        }
        return null;
    }
}
