package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.domain.model.entity.factory.UsuarioFactory;
import com.kmd.patitas_care.domain.repository.ClienteRepository;
import com.kmd.patitas_care.domain.repository.VeterinarioRepository;
import com.kmd.patitas_care.domain.service.UsuarioDomainService;
import com.kmd.patitas_care.domain.service.validator.UsuarioValidator;
import com.kmd.patitas_care.infraestructure.dto.request.cliente.ActualizarClienteRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.request.veterinario.ActualizarVeterinarioRequestDTO;
import com.kmd.patitas_care.infraestructure.exception.BadRequestException;
import com.kmd.patitas_care.infraestructure.exception.EmailAlreadyExistsException;
import com.kmd.patitas_care.infraestructure.exception.ResourceNotFoundException;
import com.kmd.patitas_care.infraestructure.exception.UserNotFoundException;
import jakarta.transaction.Transactional;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@Transactional
public class UsuarioServiceImpl implements UsuarioDomainService {
    private final ClienteRepository clienteRepository;
    private final VeterinarioRepository veterinarioRepository;
    private final PasswordEncoder passwordEncoder;

    public UsuarioServiceImpl(ClienteRepository clienteRepository, VeterinarioRepository veterinarioRepository,
                              PasswordEncoder passwordEncoder) {
        this.clienteRepository = clienteRepository;
        this.veterinarioRepository = veterinarioRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public Cliente registrarCliente(String nombre, String correo, String password, TipoDeUsuario tipoDeUsuario) {
        UsuarioValidator.validarDatosDeRegistro(nombre, correo, password);
        UsuarioValidator.validarTipoDeUsuarioCliente(tipoDeUsuario);
        Optional<Cliente> clienteExiste = clienteRepository.buscarPorCorreo(correo);
        if (clienteExiste.isPresent()) {
            throw new EmailAlreadyExistsException(correo);
        }
        Cliente nuevoCliente = UsuarioFactory.crearCliente(nombre, correo, passwordEncoder.encode(password), tipoDeUsuario);
        clienteRepository.guardar(nuevoCliente);
        return nuevoCliente;

    }

    @Override
    public Veterinario registrarVeterinario(String nombre, String correo, String password, TipoDeUsuario tipoDeUsuario) {
        UsuarioValidator.validarDatosDeRegistro(nombre, correo, password);
        UsuarioValidator.validarTipoDeUsuarioVeterinario(tipoDeUsuario);
        Optional<Veterinario> veterinarioExiste = veterinarioRepository.buscarPorCorreo(correo);
        if (veterinarioExiste.isPresent()) {
            throw new EmailAlreadyExistsException(correo);
        }
        Veterinario nuevoVeterinario = UsuarioFactory.crearVeterinario(nombre, correo, passwordEncoder.encode(password), tipoDeUsuario);
        veterinarioRepository.guardar(nuevoVeterinario);
        return nuevoVeterinario;
    }

    @Override
    public Cliente buscarClientePorId(String id){
        return clienteRepository.buscarPorId(id)
                .orElseThrow(() -> new UserNotFoundException(id));
    }

    @Override
    public Veterinario buscarVeterinarioPorId(String id){
        return veterinarioRepository.buscarPorId(id)
                .orElseThrow(() -> new UserNotFoundException(id));
    }

    @Override
    public Cliente actualizarCliente(String id, ActualizarClienteRequestDTO dto) {
        Cliente clienteExistente = clienteRepository.buscarPorId(id)
                .orElseThrow(() -> new UserNotFoundException(id));

        clienteRepository.buscarPorCorreo(dto.getCorreo())
                .filter(c -> !c.getId().equals(id))
                .ifPresent(c -> {
                    throw new EmailAlreadyExistsException(dto.getCorreo());
                });

        String passwordHash = dto.getPassword() != null ?
                passwordEncoder.encode(dto.getPassword()) :
                clienteExistente.getPasswordHash();

        Cliente clienteActualizado = new Cliente.ClienteBuilder()
                .setId(id)
                .setNombre(dto.getNombre())
                .setCorreo(dto.getCorreo())
                .setPasswordHash(passwordHash)
                .setTipo(TipoDeUsuario.CLIENTE)
                .build();

        clienteRepository.guardar(clienteActualizado);
        return clienteActualizado;
    }

    @Override
    public Veterinario actualizarVeterinario(String id, ActualizarVeterinarioRequestDTO dto) {
        Veterinario veterinarioExistente = veterinarioRepository.buscarPorId(id)
                .orElseThrow(() -> new UserNotFoundException(id));

        veterinarioRepository.buscarPorCorreo(dto.getCorreo())
                .filter(c -> !c.getId().equals(id))
                .ifPresent(c -> {
                    throw new EmailAlreadyExistsException(dto.getCorreo());
                });

        String passwordHash = dto.getPassword() != null ?
                passwordEncoder.encode(dto.getPassword()) :
                veterinarioExistente.getPasswordHash();

        Veterinario veterinarioActualizado = new Veterinario.VeterinarioBuilder()
                .setNombre(dto.getNombre())
                .setCorreo(dto.getCorreo())
                .setPasswordHash(passwordHash)
                .setTipo(TipoDeUsuario.CLIENTE)
                .build();

        veterinarioRepository.guardar(veterinarioActualizado);
        return veterinarioActualizado;
    }

    @Override
    public void eliminarCliente(String id) {
        if(!clienteRepository.buscarPorId(id).isPresent()){
            throw new UserNotFoundException(id);
        }
        clienteRepository.eliminarPorId(id);
    }

    @Override
    public void eliminarVeterinario(String id) {
        if (!veterinarioRepository.buscarPorId(id).isPresent()){
            throw new UserNotFoundException(id);
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
}
