package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import com.kmd.patitas_care.infraestructure.dto.request.HistorialMedicoRequest;
import com.kmd.patitas_care.infraestructure.dto.response.HistorialMedicoResponse;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import java.time.LocalDate;
import java.util.List;

public interface HistorialMedicoService {

    HistorialMedicoResponse crearHistorial(HistorialMedicoRequest request, String userEmail);

    HistorialMedicoResponse actualizarHistorial(String id, HistorialMedicoRequest request, String userEmail);

    HistorialMedicoResponse obtenerHistorialPorId(String id, String userEmail);

    List<HistorialMedicoResponse> obtenerHistorialPorMascota(String mascotaId, String userEmail);

    Page<HistorialMedicoResponse> obtenerHistorialPorMascotaPaginado(String mascotaId, Pageable pageable, String userEmail);

    List<HistorialMedicoResponse> obtenerHistorialPorMascotaYTipo(String mascotaId, TipoEventoMedico tipo, String userEmail);

    List<HistorialMedicoResponse> obtenerHistorialPorMascotaYFechas(String mascotaId, LocalDate fechaInicio, LocalDate fechaFin, String userEmail);

    void eliminarHistorial(String id, String userEmail);

    long contarHistorialPorMascota(String mascotaId, String userEmail);
}
