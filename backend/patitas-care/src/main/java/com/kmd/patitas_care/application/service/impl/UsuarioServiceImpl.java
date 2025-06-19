package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.domain.model.entity.factory.UsuarioFactory;
import com.kmd.patitas_care.domain.repository.ClienteRepository;
import com.kmd.patitas_care.domain.repository.VeterinarioRepository;
import com.kmd.patitas_care.domain.service.UsuarioDomainService;
import com.kmd.patitas_care.domain.service.validator.UsuarioValidator;
import com.kmd.patitas_care.infraestructure.exception.ResourceNotFoundException;
import jakarta.transaction.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class UsuarioServiceImpl implements UsuarioDomainService {
    private final ClienteRepository clienteRepository;
    private final VeterinarioRepository veterinarioRepository;
    private final PasswordEncoder passwordEncoder;

    public UsuarioServiceImpl(ClienteRepository clienteRepository ,VeterinarioRepository veterinarioRepository,
                              PasswordEncoder passwordEncoder){
        this.clienteRepository = clienteRepository;
        this.veterinarioRepository = veterinarioRepository;
        this.passwordEncoder = passwordEncoder;
    }
    @Override
    public Cliente registrarCliente(String nombre, String correo, String password, TipoDeUsuario tipoDeUsuario){
        UsuarioValidator.validarDatosDeRegistro(nombre, correo, password, TipoDeUsuario.CLIENTE);
        Optional<Cliente> clienteExiste = clienteRepository.buscarPorCorreo(correo);
        if(clienteExiste.isPresent()){
            throw new IllegalStateException("El usuario ya existe");
        }
        Cliente nuevoCliente = UsuarioFactory.crearCliente(nombre, correo, passwordEncoder.encode(password), tipoDeUsuario);
        clienteRepository.guardar(nuevoCliente);
        return nuevoCliente;

    }
    @Override
    public Veterinario registrarVeterinario(String nombre, String correo, String password, TipoDeUsuario tipoDeUsuario){
        UsuarioValidator.validarDatosDeRegistro(nombre, correo, password, TipoDeUsuario.VETERINARIO);
        Optional<Veterinario> veterinarioExiste = veterinarioRepository.buscarPorCorreo(correo);
        if(veterinarioExiste.isPresent()){
            throw new IllegalStateException("El usuario ya existe");
        }
        Veterinario nuevoVeterinario = UsuarioFactory.crearVeterinario(nombre, correo, passwordEncoder.encode(password), tipoDeUsuario);
        veterinarioRepository.guardar(nuevoVeterinario);
        return nuevoVeterinario;
    }
    @Override
    public Cliente buscarClientePorId(String id){
        return clienteRepository.buscarPorId(id)
                .orElseThrow(() -> new ResourceNotFoundException("Cliente no encontrado"));
    }

    @Override
    public Veterinario buscarVeterinarioPorId(String id){
        return veterinarioRepository.buscarPorId(id)
                .orElseThrow(() -> new ResourceNotFoundException("Veterinario no encontrado"));
    }

    @Override
    public void eliminarCliente(String id) {
        if(!clienteRepository.buscarPorId(id).isPresent()){
            throw new ResourceNotFoundException("Cliente no encontrado");
        }
        clienteRepository.eliminarPorId(id);
    }

    @Override
    public void eliminarVeterinario(String id) {
        if (!veterinarioRepository.buscarPorId(id).isPresent()){
            throw new ResourceNotFoundException("Veterinario no encontrado");
        }
        veterinarioRepository.eliminarPorId(id);
    }
    //    @Override
//    public List<Cliente> obtenerTodosLosClientes() {
//        return clienteRepository.obtenerTodos();
//    }
//
//    @Override
//    public List<Veterinario> obtenerTodosLosVeterinarios() {
//        return veterinarioRepository.obtenerTodos();
//    }
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
