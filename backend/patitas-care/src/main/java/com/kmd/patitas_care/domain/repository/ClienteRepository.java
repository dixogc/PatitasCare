package com.kmd.patitas_care.domain.repository;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface ClienteRepository {
    Optional<Cliente> buscarPorId(String id);
    Optional<Cliente> buscarPorCorreo(String correo);
    void guardar(Cliente cliente);
    void eliminarPorId(String id);
    List<Cliente> obtenerTodos();
}
