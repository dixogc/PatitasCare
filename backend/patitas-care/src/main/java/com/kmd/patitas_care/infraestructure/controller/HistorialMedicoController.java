package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.AuthService;
import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import com.kmd.patitas_care.domain.service.HistorialMedicoService;
import com.kmd.patitas_care.infraestructure.dto.request.HistorialMedicoRequest;
import com.kmd.patitas_care.infraestructure.dto.response.HistorialMedicoResponse;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/historial-medico")
@RequiredArgsConstructor
@Slf4j
@Validated
public class HistorialMedicoController {

    private final HistorialMedicoService historialMedicoService;
    private final AuthService authService;

    @PostMapping
    public ResponseEntity<HistorialMedicoResponse> crearHistorial(
            @RequestBody @Valid HistorialMedicoRequest request,
            HttpServletRequest httpRequest) {

        String clienteId = authService.obtenerClienteDesdeToken(httpRequest);
        HistorialMedicoResponse response = historialMedicoService.crearHistorial(request, clienteId);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @PutMapping("/{id}")
    public ResponseEntity<HistorialMedicoResponse> actualizarHistorial(
            @PathVariable String id,
            @RequestBody @Valid HistorialMedicoRequest request,
            HttpServletRequest httpRequest) {

        String clienteId = authService.obtenerClienteDesdeToken(httpRequest);
        HistorialMedicoResponse response = historialMedicoService.actualizarHistorial(id, request, clienteId);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<HistorialMedicoResponse> obtenerPorId(
            @PathVariable String id,
            HttpServletRequest httpRequest) {

        String clienteId = authService.obtenerClienteDesdeToken(httpRequest);
        HistorialMedicoResponse response = historialMedicoService.obtenerHistorialPorId(id, clienteId);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerPorMascota(
            @PathVariable String mascotaId,
            HttpServletRequest httpRequest) {

        String clienteId = authService.obtenerClienteDesdeToken(httpRequest);
        List<HistorialMedicoResponse> response = historialMedicoService.obtenerHistorialPorMascota(mascotaId, clienteId);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}/paginado")
    public ResponseEntity<Page<HistorialMedicoResponse>> obtenerPorMascotaPaginado(
            @PathVariable String mascotaId,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(defaultValue = "fecha") String sortBy,
            @RequestParam(defaultValue = "desc") String sortDir,
            HttpServletRequest httpRequest) {

        String clienteId = authService.obtenerClienteDesdeToken(httpRequest);

        Sort sort = sortDir.equalsIgnoreCase("desc") ?
                Sort.by(sortBy).descending() :
                Sort.by(sortBy).ascending();

        Pageable pageable = PageRequest.of(page, size, sort);
        Page<HistorialMedicoResponse> response = historialMedicoService.obtenerHistorialPorMascotaPaginado(mascotaId, pageable, clienteId);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}/tipo")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerPorMascotaYTipo(
            @PathVariable String mascotaId,
            @RequestParam TipoEventoMedico tipo,
            HttpServletRequest httpRequest) {

        String clienteId = authService.obtenerClienteDesdeToken(httpRequest);
        List<HistorialMedicoResponse> response = historialMedicoService.obtenerHistorialPorMascotaYTipo(mascotaId, tipo, clienteId);

        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}/fechas")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerPorMascotaYFechas(
            @PathVariable String mascotaId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaInicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaFin,
            HttpServletRequest httpRequest) {

        String clienteId = authService.obtenerClienteDesdeToken(httpRequest);
        List<HistorialMedicoResponse> response = historialMedicoService.obtenerHistorialPorMascotaYFechas(
                mascotaId, fechaInicio, fechaFin, clienteId);

        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarHistorial(
            @PathVariable String id,
            HttpServletRequest httpRequest) {

        String clienteId = authService.obtenerClienteDesdeToken(httpRequest);
        historialMedicoService.eliminarHistorial(id, clienteId);

        return ResponseEntity.noContent().build();
    }

    @GetMapping("/mascota/{mascotaId}/contar")
    public ResponseEntity<Long> contarHistorialPorMascota(
            @PathVariable String mascotaId,
            HttpServletRequest httpRequest) {

        String clienteId = authService.obtenerClienteDesdeToken(httpRequest);
        long count = historialMedicoService.contarHistorialPorMascota(mascotaId, clienteId);

        return ResponseEntity.ok(count);
    }
}