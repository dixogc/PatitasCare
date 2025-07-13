package com.kmd.patitas_care.infraestructure.repository.jpa;

import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface HistorialMedicoRepository extends JpaRepository<HistorialMedico, String> {

    List<HistorialMedico> findByMascotaIdOrderByFechaDesc(String mascotaId);

    Page<HistorialMedico> findByMascotaIdOrderByFechaDesc(String mascotaId, Pageable pageable);

    List<HistorialMedico> findByMascotaIdAndTipoOrderByFechaDesc(String mascotaId, TipoEventoMedico tipo);

    List<HistorialMedico> findByMascotaIdAndFechaBetweenOrderByFechaDesc(
            String mascotaId, LocalDate fechaInicio, LocalDate fechaFin);

    long countByMascotaId(String mascotaId);

    boolean existsByMascotaId(String mascotaId);
}
