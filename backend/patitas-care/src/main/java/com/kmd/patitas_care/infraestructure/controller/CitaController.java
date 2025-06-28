package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.AuthService;
import com.kmd.patitas_care.domain.service.CitaService;
import com.kmd.patitas_care.infraestructure.dto.request.CitaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.CitaResponseDTO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/citas")
@RequiredArgsConstructor
public class CitaController {
    private final CitaService citaService;
    private final AuthService authService;

    @PostMapping("/agendar")
    public ResponseEntity<CitaResponseDTO> agendarCita(
            @RequestBody @Valid CitaRequestDTO dto,
            HttpServletRequest request
    ) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        CitaResponseDTO cita = citaService.agendarCita(dto, clienteId);
        return ResponseEntity.status(HttpStatus.CREATED).body(cita);
    }

    @GetMapping("/mis-citas")
    public ResponseEntity<List<CitaResponseDTO>> obtenerMisCitas(HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        List<CitaResponseDTO> citas = citaService.obtenerCitasPorCliente(clienteId);
        return ResponseEntity.ok(citas);
    }
}
