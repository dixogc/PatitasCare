package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import com.kmd.patitas_care.domain.service.HistorialMedicoService;
import com.kmd.patitas_care.infraestructure.dto.request.HistorialMedicoRequest;
import com.kmd.patitas_care.infraestructure.dto.response.HistorialMedicoResponse;
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

    @PostMapping
    public ResponseEntity<HistorialMedicoResponse> crearHistorial(
            @Valid @RequestBody HistorialMedicoRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        HistorialMedicoResponse response = historialMedicoService.crearHistorial(request, userDetails.getUsername());
        return new ResponseEntity<>(response, HttpStatus.CREATED);
    }

    @PutMapping("/{id}")
    public ResponseEntity<HistorialMedicoResponse> actualizarHistorial(
            @PathVariable String id,
            @Valid @RequestBody HistorialMedicoRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        HistorialMedicoResponse response = historialMedicoService.actualizarHistorial(id, request, userDetails.getUsername());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/{id}")
    public ResponseEntity<HistorialMedicoResponse> obtenerHistorialPorId(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {

        HistorialMedicoResponse response = historialMedicoService.obtenerHistorialPorId(id, userDetails.getUsername());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerHistorialPorMascota(
            @PathVariable String mascotaId,
            @AuthenticationPrincipal UserDetails userDetails) {

        List<HistorialMedicoResponse> response = historialMedicoService.obtenerHistorialPorMascota(mascotaId, userDetails.getUsername());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}/paginado")
    public ResponseEntity<Page<HistorialMedicoResponse>> obtenerHistorialPorMascotaPaginado(
            @PathVariable String mascotaId,
            @PageableDefault(size = 10, sort = "fecha") Pageable pageable,
            @AuthenticationPrincipal UserDetails userDetails) {

        Page<HistorialMedicoResponse> response = historialMedicoService.obtenerHistorialPorMascotaPaginado(
                mascotaId, pageable, userDetails.getUsername());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}/tipo/{tipo}")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerHistorialPorMascotaYTipo(
            @PathVariable String mascotaId,
            @PathVariable TipoEventoMedico tipo,
            @AuthenticationPrincipal UserDetails userDetails) {

        List<HistorialMedicoResponse> response = historialMedicoService.obtenerHistorialPorMascotaYTipo(
                mascotaId, tipo, userDetails.getUsername());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}/fechas")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerHistorialPorMascotaYFechas(
            @PathVariable String mascotaId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaInicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate fechaFin,
            @AuthenticationPrincipal UserDetails userDetails) {

        List<HistorialMedicoResponse> response = historialMedicoService.obtenerHistorialPorMascotaYFechas(
                mascotaId, fechaInicio, fechaFin, userDetails.getUsername());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}/peso")
    public ResponseEntity<List<HistorialMedicoResponse>> obtenerHistorialPesoPorMascota(
            @PathVariable String mascotaId,
            @AuthenticationPrincipal UserDetails userDetails) {

        List<HistorialMedicoResponse> response = historialMedicoService.obtenerHistorialPesoPorMascota(
                mascotaId, userDetails.getUsername());
        return ResponseEntity.ok(response);
    }

    @GetMapping("/mascota/{mascotaId}/ultimo-peso")
    public ResponseEntity<HistorialMedicoResponse> obtenerUltimoPesoPorMascota(
            @PathVariable String mascotaId,
            @AuthenticationPrincipal UserDetails userDetails) {

        HistorialMedicoResponse response = historialMedicoService.obtenerUltimoPesoPorMascota(
                mascotaId, userDetails.getUsername());
        return ResponseEntity.ok(response);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarHistorial(
            @PathVariable String id,
            @AuthenticationPrincipal UserDetails userDetails) {

        historialMedicoService.eliminarHistorial(id, userDetails.getUsername());
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/mascota/{mascotaId}/estadisticas")
    public ResponseEntity<Map<String, Object>> obtenerEstadisticasMascota(
            @PathVariable String mascotaId,
            @AuthenticationPrincipal UserDetails userDetails) {

        long totalRegistros = historialMedicoService.contarHistorialPorMascota(mascotaId, userDetails.getUsername());
        long totalVacunas = historialMedicoService.contarHistorialPorMascotaYTipo(mascotaId, TipoEventoMedico.VACUNACION, userDetails.getUsername());
        long totalConsultas = historialMedicoService.contarHistorialPorMascotaYTipo(mascotaId, TipoEventoMedico.CONSULTA, userDetails.getUsername());
        long totalCirugias = historialMedicoService.contarHistorialPorMascotaYTipo(mascotaId, TipoEventoMedico.CIRUGIA, userDetails.getUsername());

        Map<String, Object> estadisticas = Map.of(
                "totalRegistros", totalRegistros,
                "totalVacunas", totalVacunas,
                "totalConsultas", totalConsultas,
                "totalCirugias", totalCirugias
        );

        return ResponseEntity.ok(estadisticas);
    }

    @GetMapping("/tipos-evento")
    public ResponseEntity<List<Map<String, String>>> obtenerTiposEvento() {
        List<Map<String, String>> tipos = List.of(
                Map.of("codigo", "VACUNACION", "descripcion", "Vacunación"),
                Map.of("codigo", "CONSULTA", "descripcion", "Consulta"),
                Map.of("codigo", "CIRUGIA", "descripcion", "Cirugía"),
                Map.of("codigo", "ALERGIA", "descripcion", "Alergia"),
                Map.of("codigo", "DESPARASITACION", "descripcion", "Desparasitación"),
                Map.of("codigo", "REVISION", "descripcion", "Revisión"),
                Map.of("codigo", "EMERGENCIA", "descripcion", "Emergencia"),
                Map.of("codigo", "EXAMEN", "descripcion", "Examen"),
                Map.of("codigo", "TRATAMIENTO", "descripcion", "Tratamiento"),
                Map.of("codigo", "ENFERMEDAD", "descripcion", "Enfermedad")
        );
        return ResponseEntity.ok(tipos);
    }
}
