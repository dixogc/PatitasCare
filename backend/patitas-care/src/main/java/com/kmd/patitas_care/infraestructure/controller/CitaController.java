package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.AuthService;
import com.kmd.patitas_care.domain.service.CitaService;
import com.kmd.patitas_care.infraestructure.dto.request.CitaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.CitaResponseDTO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Citas", description = "Operaciones para agendar y consultar citas del cliente")
@RestController
@RequestMapping("/citas")
@RequiredArgsConstructor
public class CitaController {
    private final CitaService citaService;
    private final AuthService authService;

    @Operation(summary = "Agendar una cita",
            description = "Permite al cliente autenticado agendar una nueva cita para una mascota.")
    @ApiResponses({
            @ApiResponse(responseCode = "201",
                    description = "Cita agendada correctamente"),
            @ApiResponse(responseCode = "400",
                    description = "Datos inválidos o campos faltantes")
    })

    @PostMapping("/agendar")
    public ResponseEntity<CitaResponseDTO> agendarCita(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Datos de la cita a agendar", required = true
            )
            @RequestBody @Valid CitaRequestDTO dto,
            HttpServletRequest request
    ) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        CitaResponseDTO cita = citaService.agendarCita(dto, clienteId);
        return ResponseEntity.status(HttpStatus.CREATED).body(cita);
    }

    @Operation(summary = "Obtener mis citas",
            description = "Devuelve todas las citas agendadas por el cliente autenticado.")
    @ApiResponse(responseCode = "200",
            description = "Lista de citas obtenida correctamente")

    @GetMapping("/mis-citas")
    public ResponseEntity<List<CitaResponseDTO>> obtenerMisCitas(HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        List<CitaResponseDTO> citas = citaService.obtenerCitasPorCliente(clienteId);
        return ResponseEntity.ok(citas);
    }
}
