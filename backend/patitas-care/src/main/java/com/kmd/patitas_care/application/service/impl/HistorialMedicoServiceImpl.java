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
    public HistorialMedicoResponse crearHistorial(HistorialMedicoRequest request, String clienteId) {
        log.info("Creando historial médico para mascota: {} por usuario: {}", request.getMascotaId(), clienteId);

        // Validar que la mascota pertenece al usuario
        validarMascotaPertenenceAlUsuario(request.getMascotaId(), clienteId);

        HistorialMedico historial = historialMedicoMapper.toEntity(request);
        HistorialMedico historialGuardado = historialMedicoRepository.save(historial);

        log.info("Historial médico creado exitosamente con ID: {}", historialGuardado.getId());
        return historialMedicoMapper.toResponse(historialGuardado);
    }

    @Override
    public HistorialMedicoResponse actualizarHistorial(String id, HistorialMedicoRequest request, String clienteId) {
        log.info("Actualizando historial médico ID: {} por usuario: {}", id, clienteId);

        HistorialMedico historial = obtenerHistorialYValidarPertenencia(id, clienteId);

        // Validar que la nueva mascota también pertenece al usuario
        if (!historial.getMascotaId().equals(request.getMascotaId())) {
            validarMascotaPertenenceAlUsuario(request.getMascotaId(), clienteId);
        }

        historialMedicoMapper.updateEntityFromRequest(historial, request);
        HistorialMedico historialActualizado = historialMedicoRepository.save(historial);

        log.info("Historial médico actualizado exitosamente");
        return historialMedicoMapper.toResponse(historialActualizado);
    }

    @Override
    public HistorialMedicoResponse obtenerHistorialPorId(String id, String clienteId) {
        log.info("Obteniendo historial médico ID: {} por usuario: {}", id, clienteId);

        HistorialMedico historial = obtenerHistorialYValidarPertenencia(id, clienteId);
        return historialMedicoMapper.toResponse(historial);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPorMascota(String mascotaId, String clienteId) {
        log.info("Obteniendo historial médico para mascota: {} por usuario: {}", mascotaId, clienteId);

        validarMascotaPertenenceAlUsuario(mascotaId, clienteId);

        List<HistorialMedico> historiales = historialMedicoRepository.findByMascotaIdOrderByFechaDesc(mascotaId);
        return historialMedicoMapper.toResponseList(historiales);
    }

    @Override
    public Page<HistorialMedicoResponse> obtenerHistorialPorMascotaPaginado(String mascotaId, Pageable pageable, String clienteId) {
        log.info("Obteniendo historial médico paginado para mascota: {} por usuario: {}", mascotaId, clienteId);

        validarMascotaPertenenceAlUsuario(mascotaId, clienteId);

        Page<HistorialMedico> page = historialMedicoRepository.findByMascotaIdOrderByFechaDesc(mascotaId, pageable);
        return page.map(historialMedicoMapper::toResponse);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPorMascotaYTipo(String mascotaId, TipoEventoMedico tipo, String clienteId) {
        log.info("Obteniendo historial médico para mascota: {} tipo: {} por usuario: {}", mascotaId, tipo, clienteId);

        validarMascotaPertenenceAlUsuario(mascotaId, clienteId);

        List<HistorialMedico> historiales = historialMedicoRepository.findByMascotaIdAndTipoOrderByFechaDesc(mascotaId, tipo);
        return historialMedicoMapper.toResponseList(historiales);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPorMascotaYFechas(String mascotaId, LocalDate fechaInicio, LocalDate fechaFin, String clienteId) {
        log.info("Obteniendo historial médico para mascota: {} entre fechas: {} - {} por usuario: {}",
                mascotaId, fechaInicio, fechaFin, clienteId);

        validarMascotaPertenenceAlUsuario(mascotaId, clienteId);

        List<HistorialMedico> historiales = historialMedicoRepository.findByMascotaIdAndFechaBetweenOrderByFechaDesc(
                mascotaId, fechaInicio, fechaFin);
        return historialMedicoMapper.toResponseList(historiales);
    }

    @Override
    public void eliminarHistorial(String id, String clienteId) {
        log.info("Eliminando historial médico ID: {} por usuario: {}", id, clienteId);

        HistorialMedico historial = obtenerHistorialYValidarPertenencia(id, clienteId);
        historialMedicoRepository.delete(historial);

        log.info("Historial médico eliminado exitosamente");
    }

    @Override
    public long contarHistorialPorMascota(String mascotaId, String clienteId) {
        log.info("Contando historial médico para mascota: {} por usuario: {}", mascotaId, clienteId);

        validarMascotaPertenenceAlUsuario(mascotaId, clienteId);

        return historialMedicoRepository.countByMascotaId(mascotaId);
    }

    private HistorialMedico obtenerHistorialYValidarPertenencia(String id, String clienteId) {
        HistorialMedico historial = historialMedicoRepository.findById(id)
                .orElseThrow(() -> new EntityNotFoundException("Historial médico no encontrado"));

        validarMascotaPertenenceAlUsuario(historial.getMascotaId(), clienteId);

        return historial;
    }

    private void validarMascotaPertenenceAlUsuario(String mascotaId, String clienteId) {
        if (!mascotaService.mascotaPertenenceAlUsuario(mascotaId, clienteId)) {
            throw new UnauthorizedException("No tienes permisos para acceder a esta mascota");
        }
    }
}
