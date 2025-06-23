package com.kmd.patitas_care.infraestructure.repository.jpa;

import com.kmd.patitas_care.domain.model.entity.Veterinario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface VeterinarioJpaRepository extends JpaRepository<Veterinario, String> {
    Optional<Veterinario> findByCorreo(String id);
    List<Veterinario> findAll();
}
