package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.BuscarVeterinariasUseCase;
import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.infraestructure.dto.request.BuscarVeterinariasRequest;
import com.kmd.patitas_care.infraestructure.dto.response.VeterinariaResponse;
import com.kmd.patitas_care.infraestructure.mapper.VeterinariaMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/veterinarias")
@CrossOrigin(origins = "*")
@Slf4j
public class VeterinariaController {
    private final BuscarVeterinariasUseCase buscarVeterinariasUseCase;
    private final VeterinariaMapper mapper;

    public VeterinariaController(BuscarVeterinariasUseCase buscarVeterinariasUseCase, VeterinariaMapper mapper) {
        this.buscarVeterinariasUseCase = buscarVeterinariasUseCase;
        this.mapper = mapper;
    }

    @GetMapping("/cercanas")
    public ResponseEntity<?> buscarVeterinariosCercanos(
            @RequestParam double latitud,
            @RequestParam double longitud,
            @RequestParam(defaultValue = "10") int radio
    ) {
        try {
            List<Veterinaria> veterinarias = buscarVeterinariasUseCase.ejecutar(latitud, longitud, radio);
            List<VeterinariaResponse> response = veterinarias.stream()
                    .map(mapper::toResponse)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.warn("Parámetros inválidos: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Error interno", e);
            return ResponseEntity.internalServerError().body(Map.of("error", "Error interno del servidor"));
        }
    }

    @PostMapping("/cercanas")
    public ResponseEntity<?> buscarVeterinariosCercanosPost(@RequestBody BuscarVeterinariasRequest request) {
        try {
            List<Veterinaria> veterinarias = buscarVeterinariasUseCase.ejecutar(
                    request.getLatitud(),
                    request.getLongitud(),
                    request.getRadio()
            );

            List<VeterinariaResponse> response = veterinarias.stream()
                    .map(mapper::toResponse)
                    .collect(Collectors.toList());

            return ResponseEntity.ok(response);

        } catch (IllegalArgumentException e) {
            log.warn("Parámetros inválidos: {}", e.getMessage());
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            log.error("Error interno", e);
            return ResponseEntity.internalServerError().body(Map.of("error", "Error interno del servidor"));
        }
    }
}
