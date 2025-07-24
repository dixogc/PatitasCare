package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import java.util.List;
import java.util.Optional;

public interface HistorialMedicoService {

    HistorialMedico guardar(HistorialMedico historialMedico);

    Optional<HistorialMedico> buscarPorId(String id);

    List<HistorialMedico> listarPorMascota(String mascotaId);

    void eliminar(String id);

    HistorialMedico actualizar(HistorialMedico historialMedico);
}
