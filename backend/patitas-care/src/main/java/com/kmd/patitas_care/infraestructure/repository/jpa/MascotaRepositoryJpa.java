package com.kmd.patitas_care.infraestructure.repository.jpa;

import com.kmd.patitas_care.domain.model.entity.Mascota;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface MascotaRepositoryJpa extends JpaRepository<Mascota, String> {
    List<Mascota> findByClienteId(String clienteId);
}

