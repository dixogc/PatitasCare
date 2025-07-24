package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.AuthService;
import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import com.kmd.patitas_care.domain.service.HistorialMedicoService;
import com.kmd.patitas_care.domain.service.MascotaService;
import com.kmd.patitas_care.infraestructure.dto.request.HistorialMedicoRequest;
import com.kmd.patitas_care.infraestructure.dto.response.HistorialMedicoResponse;
import com.kmd.patitas_care.infraestructure.mapper.HistorialMedicoMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Tag(name = "Historial Médico", description = "Operaciones relacionadas con el historial médico de las mascotas")
@RestController
@RequestMapping("/historial-medico")
@RequiredArgsConstructor
@Slf4j
@Validated
public class HistorialMedicoController {

    private final HistorialMedicoService historialService;
    private final MascotaService mascotaService;
    private final AuthService authService;

    @Operation(summary = "Registrar una entrada al historial médico",
            description = "Permite al cliente registrar un evento médico para una de sus mascotas.")
    @ApiResponses({
            @ApiResponse(responseCode = "201", description = "Entrada registrada correctamente"),
            @ApiResponse(responseCode = "400", description = "Datos de entrada inválidos"),
            @ApiResponse(responseCode = "403", description = "La mascota no pertenece al usuario"),
            @ApiResponse(responseCode = "404", description = "Mascota no encontrada")
    })
    @PostMapping("/mis-mascotas/{mascotaId}")
    public ResponseEntity<HistorialMedicoResponse> crearHistorial(
            @Parameter(description = "ID de la mascota", required = true)
            @PathVariable String mascotaId,
            @RequestBody @Valid HistorialMedicoRequest dto,
            HttpServletRequest request) {

        log.info("Creando entrada de historial médico para mascota: {}", mascotaId);

        String clienteId = authService.obtenerClienteDesdeToken(request);

        if (!mascotaService.mascotaPertenenceAlUsuario(mascotaId, clienteId)) {
            log.warn("Usuario {} intentó acceder a mascota {} que no le pertenece", clienteId, mascotaId);
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        HistorialMedico historial = historialService.guardar(
                HistorialMedicoMapper.toEntity(dto, mascotaId)
        );

        log.info("Entrada de historial médico creada exitosamente con ID: {}", historial.getId());
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(HistorialMedicoMapper.toResponseDTO(historial));
    }

    @Operation(summary = "Obtener historial médico completo de una mascota",
            description = "Obtiene todas las entradas del historial médico para una mascota del cliente autenticado, ordenadas por fecha descendente.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Historial médico obtenido correctamente"),
            @ApiResponse(responseCode = "403", description = "La mascota no pertenece al usuario"),
            @ApiResponse(responseCode = "404", description = "Mascota no encontrada")
    })
    @GetMapping("/mis-mascotas/{mascotaId}")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerHistorialCompleto(
            @Parameter(description = "ID de la mascota", required = true)
            @PathVariable String mascotaId,
            HttpServletRequest request) {

        log.debug("Obteniendo historial médico completo para mascota: {}", mascotaId);

        String clienteId = authService.obtenerClienteDesdeToken(request);

        if (!mascotaService.mascotaPertenenceAlUsuario(mascotaId, clienteId)) {
            log.warn("Usuario {} intentó acceder a mascota {} que no le pertenece", clienteId, mascotaId);
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        List<HistorialMedicoResponse> historial = historialService
                .listarPorMascota(mascotaId)
                .stream()
                .map(HistorialMedicoMapper::toResponseDTO)
                .collect(Collectors.toList());

        log.debug("Se encontraron {} entradas de historial médico para mascota: {}", historial.size(), mascotaId);
        return ResponseEntity.ok(historial);
    }

    @Operation(summary = "Obtener una entrada específica del historial médico",
            description = "Obtiene una entrada específica del historial médico por su ID.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Entrada obtenida correctamente"),
            @ApiResponse(responseCode = "403", description = "La mascota no pertenece al usuario"),
            @ApiResponse(responseCode = "404", description = "Entrada no encontrada")
    })
    @GetMapping("/mis-mascotas/{mascotaId}/{historialId}")
    public ResponseEntity<HistorialMedicoResponse> obtenerEntradaHistorial(
            @Parameter(description = "ID de la mascota", required = true)
            @PathVariable String mascotaId,
            @Parameter(description = "ID de la entrada del historial", required = true)
            @PathVariable String historialId,
            HttpServletRequest request) {

        log.debug("Obteniendo entrada de historial médico: {} para mascota: {}", historialId, mascotaId);

        String clienteId = authService.obtenerClienteDesdeToken(request);

        if (!mascotaService.mascotaPertenenceAlUsuario(mascotaId, clienteId)) {
            log.warn("Usuario {} intentó acceder a mascota {} que no le pertenece", clienteId, mascotaId);
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        Optional<HistorialMedico> optional = historialService.buscarPorId(historialId);
        if (optional.isEmpty() || !optional.get().getMascota().getId().equals(mascotaId)) {
            log.warn("Entrada de historial médico {} no encontrada o no pertenece a mascota {}", historialId, mascotaId);
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(HistorialMedicoMapper.toResponseDTO(optional.get()));
    }

    @Operation(summary = "Actualizar una entrada del historial médico",
            description = "Actualiza una entrada del historial médico si pertenece a una mascota del cliente.")
    @ApiResponses({
            @ApiResponse(responseCode = "200", description = "Entrada actualizada correctamente"),
            @ApiResponse(responseCode = "400", description = "Datos de entrada inválidos"),
            @ApiResponse(responseCode = "403", description = "La mascota no pertenece al usuario"),
            @ApiResponse(responseCode = "404", description = "Entrada no encontrada")
    })
    @PutMapping("/mis-mascotas/{mascotaId}/{historialId}")
    public ResponseEntity<HistorialMedicoResponse> actualizarEntradaHistorial(
            @Parameter(description = "ID de la mascota", required = true)
            @PathVariable String mascotaId,
            @Parameter(description = "ID de la entrada del historial", required = true)
            @PathVariable String historialId,
            @RequestBody @Valid HistorialMedicoRequest dto,
            HttpServletRequest request) {

        log.info("Actualizando entrada de historial médico: {} para mascota: {}", historialId, mascotaId);

        String clienteId = authService.obtenerClienteDesdeToken(request);

        if (!mascotaService.mascotaPertenenceAlUsuario(mascotaId, clienteId)) {
            log.warn("Usuario {} intentó acceder a mascota {} que no le pertenece", clienteId, mascotaId);
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        Optional<HistorialMedico> optional = historialService.buscarPorId(historialId);
        if (optional.isEmpty() || !optional.get().getMascota().getId().equals(mascotaId)) {
            log.warn("Entrada de historial médico {} no encontrada o no pertenece a mascota {}", historialId, mascotaId);
            return ResponseEntity.notFound().build();
        }

        HistorialMedico historialExistente = optional.get();
        HistorialMedicoMapper.updateEntity(historialExistente, dto);

        HistorialMedico historialActualizado = historialService.actualizar(historialExistente);

        log.info("Entrada de historial médico {} actualizada exitosamente", historialId);
        return ResponseEntity.ok(HistorialMedicoMapper.toResponseDTO(historialActualizado));
    }

    @Operation(summary = "Eliminar una entrada del historial médico",
            description = "Elimina una entrada del historial médico si pertenece a una mascota del cliente.")
    @ApiResponses({
            @ApiResponse(responseCode = "204", description = "Entrada eliminada correctamente"),
            @ApiResponse(responseCode = "403", description = "La mascota no pertenece al usuario"),
            @ApiResponse(responseCode = "404", description = "Entrada no encontrada")
    })
    @DeleteMapping("/mis-mascotas/{mascotaId}/{historialId}")
    public ResponseEntity<Void> eliminarEntradaHistorial(
            @Parameter(description = "ID de la mascota", required = true)
            @PathVariable String mascotaId,
            @Parameter(description = "ID de la entrada del historial", required = true)
            @PathVariable String historialId,
            HttpServletRequest request) {

        log.info("Eliminando entrada de historial médico: {} para mascota: {}", historialId, mascotaId);

        String clienteId = authService.obtenerClienteDesdeToken(request);

        if (!mascotaService.mascotaPertenenceAlUsuario(mascotaId, clienteId)) {
            log.warn("Usuario {} intentó acceder a mascota {} que no le pertenece", clienteId, mascotaId);
            return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
        }

        Optional<HistorialMedico> optional = historialService.buscarPorId(historialId);
        if (optional.isEmpty() || !optional.get().getMascota().getId().equals(mascotaId)) {
            log.warn("Entrada de historial médico {} no encontrada o no pertenece a mascota {}", historialId, mascotaId);
            return ResponseEntity.notFound().build();
        }

        historialService.eliminar(historialId);
        log.info("Entrada de historial médico {} eliminada exitosamente", historialId);
        return ResponseEntity.noContent().build();
    }
}