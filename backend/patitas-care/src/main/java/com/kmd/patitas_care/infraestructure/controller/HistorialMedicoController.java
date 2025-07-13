package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.AuthService;
import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import com.kmd.patitas_care.domain.service.HistorialMedicoService;
import com.kmd.patitas_care.infraestructure.dto.request.HistorialMedicoRequest;
import com.kmd.patitas_care.infraestructure.dto.response.HistorialMedicoResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/historial-medico")
@RequiredArgsConstructor
public class HistorialMedicoController {
    private final HistorialMedicoService historialMedicoService;
    private final AuthService authService;

    @PostMapping
    public ResponseEntity<HistorialMedicoResponse> crearHistorial(
            @RequestBody @Valid HistorialMedicoRequest request,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.crearHistorial(request, userEmail));
    }

    @PutMapping("/{id}")
    public ResponseEntity<HistorialMedicoResponse> actualizarHistorial(
            @PathVariable String id,
            @RequestBody @Valid HistorialMedicoRequest request,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.actualizarHistorial(id, request, userEmail));
    }

    @GetMapping("/{id}")
    public ResponseEntity<HistorialMedicoResponse> obtenerPorId(
            @PathVariable String id,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.obtenerHistorialPorId(id, userEmail));
    }

    @GetMapping("/mascota/{mascotaId}")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerPorMascota(
            @PathVariable String mascotaId,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.obtenerHistorialPorMascota(mascotaId, userEmail));
    }

    @GetMapping("/mascota/{mascotaId}/paginado")
    public ResponseEntity<Page<HistorialMedicoResponse>> obtenerPorMascotaPaginado(
            @PathVariable String mascotaId,
            Pageable pageable,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.obtenerHistorialPorMascotaPaginado(mascotaId, pageable, userEmail));
    }

    @GetMapping("/mascota/{mascotaId}/tipo")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerPorMascotaYTipo(
            @PathVariable String mascotaId,
            @RequestParam TipoEventoMedico tipo,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.obtenerHistorialPorMascotaYTipo(mascotaId, tipo, userEmail));
    }

    @GetMapping("/mascota/{mascotaId}/fechas")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerPorMascotaYFechas(
            @PathVariable String mascotaId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaInicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaFin,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.obtenerHistorialPorMascotaYFechas(mascotaId, fechaInicio, fechaFin, userEmail));
    }

    @GetMapping("/mascota/{mascotaId}/peso")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerHistorialPesoPorMascota(
            @PathVariable String mascotaId,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.obtenerHistorialPesoPorMascota(mascotaId, userEmail));
    }

    @GetMapping("/mascota/{mascotaId}/peso/ultimo")
    public ResponseEntity<HistorialMedicoResponse> obtenerUltimoPesoPorMascota(
            @PathVariable String mascotaId,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.obtenerUltimoPesoPorMascota(mascotaId, userEmail));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarHistorial(
            @PathVariable String id,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        historialMedicoService.eliminarHistorial(id, userEmail);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/mascota/{mascotaId}/contar")
    public ResponseEntity<Long> contarHistorialPorMascota(
            @PathVariable String mascotaId,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.contarHistorialPorMascota(mascotaId, userEmail));
    }

    @GetMapping("/mascota/{mascotaId}/contar-tipo")
    public ResponseEntity<Long> contarHistorialPorMascotaYTipo(
            @PathVariable String mascotaId,
            @RequestParam TipoEventoMedico tipo,
            HttpServletRequest httpRequest) {
        String userEmail = authService.obtenerClienteDesdeToken(httpRequest);
        return ResponseEntity.ok(historialMedicoService.contarHistorialPorMascotaYTipo(mascotaId, tipo, userEmail));
    }
}

