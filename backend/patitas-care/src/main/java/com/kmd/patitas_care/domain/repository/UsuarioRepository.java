package com.kmd.patitas_care.domain.repository;

import com.kmd.patitas_care.domain.model.entity.Usuario;

import java.util.List;
import java.util.Optional;

public interface UsuarioRepository {

    //TODO: implementar lógica en UsuarioRepositoryImpl

    <T extends Usuario> T guardar(T usuario);
    Optional<Usuario> buscarParaAutenticacion(String correo, String password);
    Optional<Usuario> buscarPorId(String id);
    Optional<Usuario> buscarPorCorreo(String correo);
    void eliminarPorId(String id);
    List<Usuario> obtenerTodos(); //para mostrar todos los usuarios
}
