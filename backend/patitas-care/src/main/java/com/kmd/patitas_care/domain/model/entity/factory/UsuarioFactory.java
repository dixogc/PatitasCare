package com.kmd.patitas_care.domain.model.entity.factory;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Usuario;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.service.validator.UsuarioValidator;

import java.util.ArrayList;
import java.util.Optional;
import java.util.UUID;

public class UsuarioFactory {

    public static Cliente crearCliente(String nombre, String correo, String passwordHash){
        return new Cliente.ClienteBuilder()
                .setId(UUID.randomUUID().toString())
                .setNombre(nombre)
                .setCorreo(correo)
                .setPasswordHash(passwordHash)
                .setTipo(TipoDeUsuario.CLIENTE)
                .setMascotas(new ArrayList<>())
                .setCitas(new ArrayList<>())
                .setMensajes(new ArrayList<>())
                .setNotificaciones(new ArrayList<>())
                .build();
    }
    public static Veterinario crearVeterinario(String nombre, String correo, String passwordHash){
        return new Veterinario.VeterinarioBuilder()
                .setId(UUID.randomUUID().toString())
                .setNombre(nombre)
                .setCorreo(correo)
                .setPasswordHash(passwordHash)
                .setTipo(TipoDeUsuario.CLIENTE)
                .setClinicas(new ArrayList<>())
                .setCitas(new ArrayList<>())
                .setConsultas(new ArrayList<>())
                .setMensajes(new ArrayList<>())
                .build();
    }
}
