package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.AuthService;
import com.kmd.patitas_care.domain.model.entity.enums.EstadoCita;
import com.kmd.patitas_care.domain.service.CitaService;
import com.kmd.patitas_care.infraestructure.dto.request.CitaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.request.CitaUpdateDTO;
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
            @ApiResponse(responseCode = "201", description = "Cita agendada correctamente"),
            @ApiResponse(responseCode = "400", description = "Datos inválidos o campos faltantes"),
            @ApiResponse(responseCode = "404", description = "Mascota o cliente no encontrado")
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
            description = "Devuelve todas las citas activas (no canceladas) del cliente autenticado.")
    @ApiResponse(responseCode = "200", description = "Lista de citas obtenida correctamente")
    @GetMapping("/mis-citas")
    public ResponseEntity<List<CitaResponseDTO>> obtenerMisCitas(HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        List<CitaResponseDTO> citas = citaService.obtenerCitasPorCliente(clienteId);
        return ResponseEntity.ok(citas);
    }

    @Operation(summary = "Obtener todas mis citas",
            description = "Devuelve TODAS las citas del cliente incluyendo las canceladas.")
    @ApiResponse(responseCode = "200", description = "Lista completa de citas obtenida correctamente")
    @GetMapping("/mis-citas/todas")
    public ResponseEntity<List<CitaResponseDTO>> obtenerTodasMisCitas(HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        List<CitaResponseDTO> citas = citaService.obtenerTodasLasCitas(clienteId);
        return ResponseEntity.ok(citas);
    }

    @Operation(summary = "Obtener citas por estado",
            description = "Devuelve las citas del cliente filtradas por estado específico.")
    @ApiResponse(responseCode = "200", description = "Lista de citas filtradas obtenida correctamente")
    @GetMapping("/mis-citas/estado/{estado}")
    public ResponseEntity<List<CitaResponseDTO>> obtenerCitasPorEstado(
            @PathVariable EstadoCita estado,
            HttpServletRequest request
    ) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        List<CitaResponseDTO> citas = citaService.obtenerCitasPorEstado(clienteId, estado);
        return ResponseEntity.ok(citas);
    }

    @Operation(summary = "Obtener cita por ID",
            description = "Devuelve los detalles de una cita específica del cliente autenticado.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Cita encontrada"),
            @ApiResponse(responseCode = "404", description = "Cita no encontrada"),
            @ApiResponse(responseCode = "403", description = "No tienes permisos para ver esta cita")
    })
    @GetMapping("/{citaId}")
    public ResponseEntity<CitaResponseDTO> obtenerCitaPorId(
            @PathVariable String citaId,
            HttpServletRequest request
    ) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        CitaResponseDTO cita = citaService.obtenerCitaPorId(citaId, clienteId);
        return ResponseEntity.ok(cita);
    }

    @Operation(summary = "Actualizar cita",
            description = "Permite actualizar los datos de una cita existente.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Cita actualizada correctamente"),
            @ApiResponse(responseCode = "400", description = "Datos inválidos"),
            @ApiResponse(responseCode = "404", description = "Cita no encontrada"),
            @ApiResponse(responseCode = "403", description = "No tienes permisos para modificar esta cita")
    })
    @PutMapping("/{citaId}")
    public ResponseEntity<CitaResponseDTO> actualizarCita(
            @PathVariable String citaId,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Nuevos datos de la cita", required = true
            )
            @RequestBody CitaUpdateDTO dto,
            HttpServletRequest request
    ) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        CitaResponseDTO citaActualizada = citaService.actualizarCita(citaId, dto, clienteId);
        return ResponseEntity.ok(citaActualizada);
    }

    @Operation(summary = "Marcar cita como completada",
            description = "Permite marcar una cita como completada después de que haya ocurrido.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Cita marcada como completada"),
            @ApiResponse(responseCode = "404", description = "Cita no encontrada"),
            @ApiResponse(responseCode = "403", description = "No tienes permisos para modificar esta cita")
    })
    @PatchMapping("/{citaId}/completar")
    public ResponseEntity<CitaResponseDTO> marcarComoCompletada(
            @PathVariable String citaId,
            HttpServletRequest request
    ) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        CitaResponseDTO citaCompletada = citaService.marcarComoCompletada(citaId, clienteId);
        return ResponseEntity.ok(citaCompletada);
    }

    @Operation(summary = "Cancelar cita",
            description = "Cancela una cita cambiando su estado a CANCELADA (eliminación lógica).")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Cita cancelada correctamente"),
            @ApiResponse(responseCode = "404", description = "Cita no encontrada"),
            @ApiResponse(responseCode = "403", description = "No tienes permisos para cancelar esta cita")
    })
    @DeleteMapping("/{citaId}")
    public ResponseEntity<CitaResponseDTO> cancelarCita(
            @PathVariable String citaId,
            HttpServletRequest request
    ) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        citaService.eliminarCita(citaId, clienteId);

        // Devolver la cita cancelada para confirmación
        CitaResponseDTO citaCancelada = citaService.obtenerCitaPorIdIncluirCanceladas(citaId, clienteId);
        return ResponseEntity.ok(citaCancelada);
    }
}
