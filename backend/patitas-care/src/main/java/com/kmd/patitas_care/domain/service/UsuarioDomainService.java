package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Usuario;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;

import java.util.List;

public interface UsuarioDomainService {

    Cliente registrarCliente(String nombre, String correo, String password, TipoDeUsuario tipoDeUsuario);
    Veterinario registrarVeterinario(String nombre, String correo, String password, TipoDeUsuario tipoDeUsuario);
    Cliente buscarClientePorId(String id);
    Veterinario buscarVeterinarioPorId(String id);
//    List<Cliente> obtenerTodosLosClientes();
//    List<Veterinario> obtenerTodosLosVeterinarios();

//    Usuario iniciarSesion(String correo, String password);
    void eliminarCliente(String id);
    void eliminarVeterinario(String id);
}
