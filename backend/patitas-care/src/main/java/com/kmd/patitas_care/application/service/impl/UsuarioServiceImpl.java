package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.domain.model.entity.Usuario;
import com.kmd.patitas_care.domain.model.entity.factory.UsuarioFactory;
import com.kmd.patitas_care.domain.repository.UsuarioRepository;
import com.kmd.patitas_care.domain.service.UsuarioDomainService;
import com.kmd.patitas_care.domain.service.validator.UsuarioValidator;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Optional;

@Service
public class UsuarioServiceImpl implements UsuarioDomainService {
    private final UsuarioRepository usuarioRepository;

    public UsuarioServiceImpl(UsuarioRepository usuarioRepository){
        this.usuarioRepository = usuarioRepository;
    }

    @Override
    public Cliente registrarCliente(String nombre, String correo, String password){
        UsuarioValidator.validarDatosDeRegistro(nombre, correo, password, TipoDeUsuario.CLIENTE);
        Optional<Usuario> usuarioExiste = usuarioRepository.buscarPorCorreo(correo);
        if(usuarioExiste.isPresent()){
            throw new IllegalStateException("El usuario ya existe");
        }
        Cliente nuevoCliente = UsuarioFactory.crearCliente(nombre, correo, password);
        return usuarioRepository.guardar(nuevoCliente);

    }
    @Override
    public Veterinario registrarVeterinario(String nombre, String correo, String password){
        UsuarioValidator.validarDatosDeRegistro(nombre, correo, password, TipoDeUsuario.VETERINARIO);
        Optional<Usuario> usuarioExiste = usuarioRepository.buscarPorCorreo(correo);
        if(usuarioExiste.isPresent()){
            throw new IllegalStateException("El usuario ya existe");
        }
        Veterinario nuevoVeterinario = new Veterinario.VeterinarioBuilder()
                .setNombre(nombre)
                .setCorreo(correo)
                .setPasswordHash(password)
                .setTipo(TipoDeUsuario.CLIENTE)
                .setClinicas(new ArrayList<>())
                .setCitas(new ArrayList<>())
                .setConsultas(new ArrayList<>())
                .setMensajes(new ArrayList<>())
                .build();
        usuarioRepository.guardar(nuevoVeterinario);
        return nuevoVeterinario;
    }


//    @Override
//    public Usuario iniciarSesion(String correo, String password) {
//        return usuarioRepository.guardar(usuario);
//    }
//
//    @Override
//    public void eliminarCuenta(String usuarioId) {
//        usuarioRepository.eliminarPorId(usuarioId);
//    }

}
