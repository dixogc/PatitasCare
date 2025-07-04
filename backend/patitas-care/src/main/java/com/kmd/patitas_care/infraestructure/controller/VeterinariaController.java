package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.BuscarVeterinariasUseCase;
import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.infraestructure.dto.request.BuscarVeterinariasRequest;
import com.kmd.patitas_care.infraestructure.dto.response.VeterinariaResponse;
import com.kmd.patitas_care.infraestructure.mapper.VeterinariaMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/veterinarias")
@CrossOrigin(origins = "*")
public class VeterinariaController {
    private final BuscarVeterinariasUseCase buscarVeterinariasUseCase;
    private final VeterinariaMapper mapper;

    public VeterinariaController(BuscarVeterinariasUseCase buscarVeterinariasUseCase, VeterinariaMapper mapper) {
        this.buscarVeterinariasUseCase = buscarVeterinariasUseCase;
        this.mapper = mapper;
    }

    @GetMapping("/cercanas")
    public ResponseEntity<List<VeterinariaResponse>> buscarVeterinariosCercanos(
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
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }

    @PostMapping("/cercanas")
    public ResponseEntity<List<VeterinariaResponse>> buscarVeterinariosCercanosPost(
            @RequestBody BuscarVeterinariasRequest request
    ) {
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
            return ResponseEntity.badRequest().build();
        } catch (Exception e) {
            return ResponseEntity.internalServerError().build();
        }
    }
}
