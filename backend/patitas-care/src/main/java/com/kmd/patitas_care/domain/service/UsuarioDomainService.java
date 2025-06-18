package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;

public interface UsuarioDomainService {

    Cliente registrarCliente(String nombre, String correo, String password);
    Veterinario registrarVeterinario(String nombre, String correo, String password);
//    Usuario iniciarSesion(String correo, String password);
//    void eliminarCuenta(String usuarioId);
}
