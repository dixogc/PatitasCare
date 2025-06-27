package com.kmd.patitas_care.domain.repository;

import com.kmd.patitas_care.domain.model.entity.Usuario;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;


public interface VeterinarioRepository {
    Optional<Veterinario> buscarPorId(String id);
    Optional<Veterinario> buscarPorCorreo(String correo);
    void guardar(Veterinario veterinario);
    void eliminarPorId(String id);
    List<Veterinario> obtenerTodos();
}
