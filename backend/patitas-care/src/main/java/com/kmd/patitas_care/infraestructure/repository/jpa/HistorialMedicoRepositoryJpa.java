package com.kmd.patitas_care.infraestructure.repository.jpa;

import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface HistorialMedicoRepositoryJpa extends JpaRepository<HistorialMedico, String> {
    List<HistorialMedico> findByMascotaIdOrderByFechaDesc(String mascotaId);

    Page<HistorialMedico> findByMascotaIdOrderByFechaDesc(String mascotaId, Pageable pageable);

    List<HistorialMedico> findByMascotaIdAndTipoOrderByFechaDesc(String mascotaId, TipoEventoMedico tipo);

    List<HistorialMedico> findByMascotaIdAndFechaBetweenOrderByFechaDesc(
            String mascotaId, LocalDate fechaInicio, LocalDate fechaFin);

    @Query("SELECT h FROM HistorialMedico h WHERE h.mascotaId = :mascotaId AND h.peso IS NOT NULL ORDER BY h.fecha DESC")
    List<HistorialMedico> findHistorialConPesoByMascotaId(@Param("mascotaId") String mascotaId);

    @Query("SELECT h FROM HistorialMedico h WHERE h.mascotaId = :mascotaId AND h.peso IS NOT NULL ORDER BY h.fecha DESC LIMIT 1")
    Optional<HistorialMedico> findUltimoPesoByMascotaId(@Param("mascotaId") String mascotaId);

    boolean existsByMascotaId(String mascotaId);

    long countByMascotaId(String mascotaId);

    @Query("SELECT COUNT(h) FROM HistorialMedico h WHERE h.mascotaId = :mascotaId AND h.tipo = :tipo")
    long countByMascotaIdAndTipo(@Param("mascotaId") String mascotaId, @Param("tipo") TipoEventoMedico tipo);
}
