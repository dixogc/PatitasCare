package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import com.kmd.patitas_care.domain.service.HistorialMedicoService;
import com.kmd.patitas_care.domain.service.MascotaService;
import com.kmd.patitas_care.infraestructure.dto.request.HistorialMedicoRequest;
import com.kmd.patitas_care.infraestructure.dto.response.HistorialMedicoResponse;
import com.kmd.patitas_care.infraestructure.exception.ResourceNotFoundException;
import com.kmd.patitas_care.infraestructure.mapper.HistorialMedicoMapper;
import com.kmd.patitas_care.infraestructure.repository.jpa.HistorialMedicoRepositoryJpa;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Slf4j
public class HistorialMedicoServiceImpl implements HistorialMedicoService {

    private final HistorialMedicoRepositoryJpa historialMedicoRepository;
    private final HistorialMedicoMapper historialMedicoMapper;
    private final MascotaService mascotaService;

    @Override
    public HistorialMedicoResponse crearHistorial(HistorialMedicoRequest request, String userEmail) {
        log.info("Creando historial médico para mascota ID: {}", request.getMascotaId());
        HistorialMedico historial = historialMedicoMapper.toEntity(request);
        HistorialMedico savedHistorial = historialMedicoRepository.save(historial);

        log.info("Historial médico creado con ID: {}", savedHistorial.getId());
        return historialMedicoMapper.toResponse(savedHistorial);
    }

    @Override
    public HistorialMedicoResponse actualizarHistorial(String id, HistorialMedicoRequest request, String userEmail) {
        log.info("Actualizando historial médico ID: {}", id);
        HistorialMedico historial = obtenerHistorialPorId(id);
        historialMedicoMapper.updateEntityFromRequest(historial, request);
        HistorialMedico updatedHistorial = historialMedicoRepository.save(historial);

        log.info("Historial médico actualizado: {}", updatedHistorial.getId());
        return historialMedicoMapper.toResponse(updatedHistorial);
    }

    @Override
    public HistorialMedicoResponse obtenerHistorialPorId(String id, String userEmail) {
        log.info("Obteniendo historial médico ID: {}", id);
        HistorialMedico historial = obtenerHistorialPorId(id);
        return historialMedicoMapper.toResponse(historial);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPorMascota(String mascotaId, String userEmail) {
        log.info("Obteniendo historial médico para mascota ID: {}", mascotaId);
        List<HistorialMedico> historial = historialMedicoRepository.findByMascotaIdOrderByFechaDesc(mascotaId);
        return historialMedicoMapper.toResponseList(historial);
    }

    @Override
    public Page<HistorialMedicoResponse> obtenerHistorialPorMascotaPaginado(String mascotaId, Pageable pageable, String userEmail) {
        log.info("Obteniendo historial médico paginado para mascota ID: {}", mascotaId);
        Page<HistorialMedico> historialPage = historialMedicoRepository.findByMascotaIdOrderByFechaDesc(mascotaId, pageable);
        return historialPage.map(historialMedicoMapper::toResponse);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPorMascotaYTipo(String mascotaId, TipoEventoMedico tipo, String userEmail) {
        log.info("Obteniendo historial médico para mascota ID: {} y tipo: {}", mascotaId, tipo);
        List<HistorialMedico> historial = historialMedicoRepository.findByMascotaIdAndTipoOrderByFechaDesc(mascotaId, tipo);
        return historialMedicoMapper.toResponseList(historial);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPorMascotaYFechas(String mascotaId, LocalDate fechaInicio, LocalDate fechaFin, String userEmail) {
        log.info("Obteniendo historial médico para mascota ID: {} entre {} y {}", mascotaId, fechaInicio, fechaFin);
        List<HistorialMedico> historial = historialMedicoRepository.findByMascotaIdAndFechaBetweenOrderByFechaDesc(
                mascotaId, fechaInicio, fechaFin);
        return historialMedicoMapper.toResponseList(historial);
    }

    @Override
    public List<HistorialMedicoResponse> obtenerHistorialPesoPorMascota(String mascotaId, String userEmail) {
        log.info("Obteniendo historial de peso para mascota ID: {}", mascotaId);
        List<HistorialMedico> historial = historialMedicoRepository.findHistorialConPesoByMascotaId(mascotaId);
        return historialMedicoMapper.toResponseList(historial);
    }

    @Override
    public HistorialMedicoResponse obtenerUltimoPesoPorMascota(String mascotaId, String userEmail) {
        log.info("Obteniendo último peso para mascota ID: {}", mascotaId);
        Optional<HistorialMedico> ultimoPeso = historialMedicoRepository.findUltimoPesoByMascotaId(mascotaId);
        if (ultimoPeso.isEmpty()) {
            throw new ResourceNotFoundException("No se encontró registro de peso para la mascota con ID: " + mascotaId);
        }

        return historialMedicoMapper.toResponse(ultimoPeso.get());
    }

    @Override
    public void eliminarHistorial(String id, String userEmail) {
        log.info("Eliminando historial médico ID: {}", id);
        HistorialMedico historial = obtenerHistorialPorId(id);
        historialMedicoRepository.delete(historial);
        log.info("Historial médico eliminado: {}", id);
    }

    @Override
    public long contarHistorialPorMascota(String mascotaId, String userEmail) {
        log.info("Contando historial médico para mascota ID: {}", mascotaId);
        return historialMedicoRepository.countByMascotaId(mascotaId);
    }

    @Override
    public long contarHistorialPorMascotaYTipo(String mascotaId, TipoEventoMedico tipo, String userEmail) {
        log.info("Contando historial médico para mascota ID: {} y tipo: {}", mascotaId, tipo);
        return historialMedicoRepository.countByMascotaIdAndTipo(mascotaId, tipo);
    }

    private HistorialMedico obtenerHistorialPorId(String id) {
        return historialMedicoRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Historial médico no encontrado con ID: " + id));
    }
}
