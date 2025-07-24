package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import com.kmd.patitas_care.domain.service.HistorialMedicoService;
import com.kmd.patitas_care.infraestructure.repository.jpa.HistorialMedicoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@RequiredArgsConstructor
@Slf4j
@Service
public class HistorialMedicoServiceImpl implements HistorialMedicoService {

    private final HistorialMedicoRepository historialMedicoRepository;

    @Override
    public HistorialMedico guardar(HistorialMedico historialMedico) {
        log.info("Guardando historial médico para mascota: {}", historialMedico.getMascota().getId());
        return historialMedicoRepository.save(historialMedico);
    }

    @Override
    public Optional<HistorialMedico> buscarPorId(String id) {
        log.debug("Buscando historial médico por ID: {}", id);
        return historialMedicoRepository.findById(id);
    }

    @Override
    public List<HistorialMedico> listarPorMascota(String mascotaId) {
        log.debug("Listando historial médico para mascota: {}", mascotaId);
        return historialMedicoRepository.findByMascotaIdOrderByFechaEventoDesc(mascotaId);
    }

    @Override
    public void eliminar(String id) {
        log.info("Eliminando historial médico con ID: {}", id);
        historialMedicoRepository.deleteById(id);
    }

    @Override
    public HistorialMedico actualizar(HistorialMedico historialMedico) {
        log.info("Actualizando historial médico con ID: {}", historialMedico.getId());
        return historialMedicoRepository.save(historialMedico);
    }
}