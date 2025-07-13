package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import com.kmd.patitas_care.domain.service.HistorialMedicoService;
import com.kmd.patitas_care.domain.service.MascotaService;
import com.kmd.patitas_care.infraestructure.dto.request.HistorialMedicoRequest;
import com.kmd.patitas_care.infraestructure.dto.response.HistorialMedicoResponse;
import com.kmd.patitas_care.infraestructure.exception.UnauthorizedException;
import com.kmd.patitas_care.infraestructure.mapper.HistorialMedicoMapper;
import com.kmd.patitas_care.infraestructure.repository.jpa.HistorialMedicoRepository;
import jakarta.persistence.EntityNotFoundException;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import java.nio.file.AccessDeniedException;
import java.time.LocalDate;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class HistorialMedicoServiceImpl implements HistorialMedicoService {

    private final HistorialMedicoRepository historialMedicoRepository;
    private final HistorialMedicoMapper historialMedicoMapper;
    private final MascotaService mascotaService; // Asume que tienes este servicio para validar la mascota

    @Override
    public HistorialMedicoResponse crearHistorial(HistorialMedicoRequest request, String userEmail) {
        log.info("Creando historial médico para mascota: {} por usuario: {}", request.getMascotaId(), userEmail);

        // Validar que la mascota pertenece al usuario
        validarMascotaPertenenceAlUsuario(request.getMascotaId(), userEmail);

        HistorialMedico historial = historialMedicoMapper.toEntity(request);
        HistorialMedico historialGuardado = historialMedicoRepository.save(historial);

        log.info("Historial médico creado exitosamente con ID: {}", historialGuardado.getId());
        return historialMedicoMapper.toResponse(historialGuardado);
    }

    @Override
    public HistorialMedicoResponse actualizarHistorial(String id, HistorialMedicoRequest request, String userEmail) {
        log.info("Actualizando historial médico ID: {} por usuario: {}", id, userEmail);

        HistorialMedico historial = obtenerHistorialYValidarPertenencia(id, userEmail);

        // Validar que la nueva mascota también pertenece al usuario
        if (!historial.getMascotaId().equals(request.getMascotaId())) {
            validarMascotaPertenenceAlUsuario(request.getMascotaId(), userEmail);
        }

        historialMedicoMapper.updateEntityFromRequest(historial, request);
        HistorialMedico historialActualizado = historialMedicoRepository.save(historial);

        log.info("Historial médico actualizado exitosamente");
        return historialMedicoMapper.toResponse(historialActualizado);
    }

    @Override
    public HistorialMedicoResponse obtenerHistorialPorId(String id, String userEmail) {
        log.info("Obteniendo historial médico ID: {} por usuario: {}", id, userEmail);

        HistorialMedico historial = obtenerHistorialYValidarPertenencia(id, userEmail);
        return historialMedicoMapper.toResponse(historial);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPorMascota(String mascotaId, String userEmail) {
        log.info("Obteniendo historial médico para mascota: {} por usuario: {}", mascotaId, userEmail);

        validarMascotaPertenenceAlUsuario(mascotaId, userEmail);

        List<HistorialMedico> historiales = historialMedicoRepository.findByMascotaIdOrderByFechaDesc(mascotaId);
        return historialMedicoMapper.toResponseList(historiales);
    }

    @Override
    public Page<HistorialMedicoResponse> obtenerHistorialPorMascotaPaginado(String mascotaId, Pageable pageable, String userEmail) {
        log.info("Obteniendo historial médico paginado para mascota: {} por usuario: {}", mascotaId, userEmail);

        validarMascotaPertenenceAlUsuario(mascotaId, userEmail);

        Page<HistorialMedico> page = historialMedicoRepository.findByMascotaIdOrderByFechaDesc(mascotaId, pageable);
        return page.map(historialMedicoMapper::toResponse);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPorMascotaYTipo(String mascotaId, TipoEventoMedico tipo, String userEmail) {
        log.info("Obteniendo historial médico para mascota: {} tipo: {} por usuario: {}", mascotaId, tipo, userEmail);

        validarMascotaPertenenceAlUsuario(mascotaId, userEmail);

        List<HistorialMedico> historiales = historialMedicoRepository.findByMascotaIdAndTipoOrderByFechaDesc(mascotaId, tipo);
        return historialMedicoMapper.toResponseList(historiales);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPorMascotaYFechas(String mascotaId, LocalDate fechaInicio, LocalDate fechaFin, String userEmail) {
        log.info("Obteniendo historial médico para mascota: {} entre fechas: {} - {} por usuario: {}",
                mascotaId, fechaInicio, fechaFin, userEmail);

        validarMascotaPertenenceAlUsuario(mascotaId, userEmail);

        List<HistorialMedico> historiales = historialMedicoRepository.findByMascotaIdAndFechaBetweenOrderByFechaDesc(
                mascotaId, fechaInicio, fechaFin);
        return historialMedicoMapper.toResponseList(historiales);
    }

    @Override
    public void eliminarHistorial(String id, String userEmail) {
        log.info("Eliminando historial médico ID: {} por usuario: {}", id, userEmail);

        HistorialMedico historial = obtenerHistorialYValidarPertenencia(id, userEmail);
        historialMedicoRepository.delete(historial);

        log.info("Historial médico eliminado exitosamente");
    }

    @Override
    public long contarHistorialPorMascota(String mascotaId, String userEmail) {
        log.info("Contando historial médico para mascota: {} por usuario: {}", mascotaId, userEmail);

        validarMascotaPertenenceAlUsuario(mascotaId, userEmail);

        return historialMedicoRepository.countByMascotaId(mascotaId);
    }

    private HistorialMedico obtenerHistorialYValidarPertenencia(String id, String userEmail) {
        HistorialMedico historial = historialMedicoRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Historial médico no encontrado"));

        validarMascotaPertenenceAlUsuario(historial.getMascotaId(), userEmail);

        return historial;
    }

    private void validarMascotaPertenenceAlUsuario(String mascotaId, String userEmail) {
        if (!mascotaService.mascotaPertenenceAlUsuario(mascotaId, userEmail)) {
            throw new UnauthorizedException("No tienes permisos para acceder a esta mascota");
        }
    }
}
