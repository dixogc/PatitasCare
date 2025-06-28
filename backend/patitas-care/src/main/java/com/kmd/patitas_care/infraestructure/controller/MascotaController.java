package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.AuthService;
import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.service.MascotaService;
import com.kmd.patitas_care.infraestructure.dto.request.MascotaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.request.cliente.RegistroClienteRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.MascotaResponseDTO;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Tag(name = "Mascotas", description = "Operaciones relacionadas con las mascotas del cliente")
@RestController
@RequestMapping("/mascotas")
public class MascotaController {

    @Autowired
    private final MascotaService mascotaService;
    @Autowired
    private final AuthService authService;

    public MascotaController(MascotaService mascotaService, AuthService authService) {
        this.mascotaService = mascotaService;
        this.authService = authService;
    }

    @Operation(summary = "Listar mis mascotas",
            description = "Obtiene todas las mascotas registradas por el cliente autenticado.")
    @ApiResponse(responseCode = "200",
            description = "Lista de mascotas obtenida correctamente")


    @GetMapping("/mis-mascotas")
    public ResponseEntity<List<MascotaResponseDTO>> misMascotas(HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        List<MascotaResponseDTO> mascotas = mascotaService.obtenerMascotasPorCliente(clienteId);
        return ResponseEntity.ok(mascotas);
    }

    @Operation(summary = "Obtener una mascota",
            description = "Obtiene los datos de una mascota específica del cliente autenticado.")
    @ApiResponses({
            @ApiResponse(responseCode = "200",
                    description = "Mascota obtenida correctamente"),
            @ApiResponse(responseCode = "404",
                    description = "Mascota no encontrada o no pertenece al cliente")
    })

    @GetMapping("/mis-mascotas/{mascotaId}")
    public ResponseEntity<MascotaResponseDTO> miMascota(
            @Parameter(description = "ID de la mascota", required = true)
            @PathVariable String mascotaId,
            HttpServletRequest request
    ) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        MascotaResponseDTO mascota = mascotaService.obtenerMascotaDelCliente(mascotaId, clienteId);
        return ResponseEntity.ok(mascota);
    }

    @Operation(summary = "Registrar una nueva mascota",
            description = "Permite al cliente autenticado registrar una nueva mascota.")
    @ApiResponses({
            @ApiResponse(responseCode = "201",
                    description = "Mascota registrada correctamente"),
            @ApiResponse(responseCode = "400",
                    description = "Datos inválidos o faltantes")
    })

    @PostMapping("/mis-mascotas")
    public ResponseEntity<MascotaResponseDTO> crearMiMascota(
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Datos de la mascota a registrar", required = true
            )
            @RequestBody @Valid MascotaRequestDTO dto,
            HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        dto.setClienteId(clienteId);
        MascotaResponseDTO mascota = mascotaService.crearMascota(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(mascota);
    }

    @Operation(summary = "Actualizar una mascota",
            description = "Actualiza los datos de una mascota del cliente autenticado.")
    @ApiResponses({
            @ApiResponse(responseCode = "200",
                    description = "Mascota actualizada correctamente"),
            @ApiResponse(responseCode = "400",
                    description = "Datos inválidos"),
            @ApiResponse(responseCode = "404",
                    description = "Mascota no encontrada o no pertenece al cliente")
    })

    @PutMapping("/mis-mascotas/{mascotaId}")
    public ResponseEntity<MascotaResponseDTO> actualizarMiMascota(
            @Parameter(description = "ID de la mascota", required = true)
            @PathVariable String mascotaId,
            @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Datos actualizados de la mascota", required = true
            )
            @RequestBody @Valid MascotaRequestDTO dto,
            HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        dto.setClienteId(clienteId);
        MascotaResponseDTO mascota = mascotaService.actualizarMascotaDelCliente(mascotaId, dto, clienteId);
        return ResponseEntity.ok(mascota);
    }

    @Operation(summary = "Eliminar una mascota",
            description = "Elimina una mascota del cliente autenticado.")
    @ApiResponses({
            @ApiResponse(responseCode = "204",
                    description = "Mascota eliminada correctamente"),
            @ApiResponse(responseCode = "404",
                    description = "Mascota no encontrada o no pertenece al cliente")
    })

    @DeleteMapping("/mis-mascotas/{mascotaId}")
    public ResponseEntity<Void> eliminarMiMascota(
            @Parameter(description = "ID de la mascota", required = true)
            @PathVariable String mascotaId,
            HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        mascotaService.eliminarMascotaDelCliente(mascotaId, clienteId);
        return ResponseEntity.noContent().build();
    }

}
