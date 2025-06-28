package com.kmd.patitas_care.infraestructure.repository.jpa;

import com.kmd.patitas_care.domain.model.entity.Cita;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CitaRepositoryJpa extends JpaRepository<Cita, String> {
    List<Cita> findByClienteId(String clienteId);
    List<Cita> findByVeterinarioId(String veterinarioId);
    List<Cita> findByMascotaId(String mascotaId);
    List<Cita> findByVeterinarioIsNullAndEstado(String estado);

}
