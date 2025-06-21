package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.infraestructure.dto.request.cliente.ActualizarClienteRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.request.veterinario.ActualizarVeterinarioRequestDTO;

public interface UsuarioDomainService {

    Cliente registrarCliente(String nombre, String correo, String password, TipoDeUsuario tipoDeUsuario);
    Veterinario registrarVeterinario(String nombre, String correo, String password, TipoDeUsuario tipoDeUsuario);
    Cliente buscarClientePorId(String id);
    Veterinario buscarVeterinarioPorId(String id);
    Cliente actualizarCliente(String id, ActualizarClienteRequestDTO dto);
    Veterinario actualizarVeterinario(String id, ActualizarVeterinarioRequestDTO dto);
    void eliminarCliente(String id);
    void eliminarVeterinario(String id);
//    List<Cliente> obtenerTodosLosClientes();
//    List<Veterinario> obtenerTodosLosVeterinarios();
//    Usuario iniciarSesion(String correo, String password);

}
