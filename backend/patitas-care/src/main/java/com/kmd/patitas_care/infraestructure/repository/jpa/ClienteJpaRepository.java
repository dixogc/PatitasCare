package com.kmd.patitas_care.infraestructure.repository.jpa;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface ClienteJpaRepository extends JpaRepository<Cliente, String> {
    Optional<Cliente> findByCorreo(String correo);

}
