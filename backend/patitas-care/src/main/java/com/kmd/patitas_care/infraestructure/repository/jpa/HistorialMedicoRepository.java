package com.kmd.patitas_care.infraestructure.repository.jpa;

import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import com.kmd.patitas_care.domain.model.entity.Mascota;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface HistorialMedicoRepository extends JpaRepository<HistorialMedico, String> {

    List<HistorialMedico> findByMascota(Mascota mascota);

    List<HistorialMedico> findByMascotaIdOrderByFechaEventoDesc(String mascotaId);
}
