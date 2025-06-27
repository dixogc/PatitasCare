package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.repository.Autenticable;
import com.kmd.patitas_care.domain.repository.ClienteRepository;
import com.kmd.patitas_care.domain.repository.VeterinarioRepository;
import com.kmd.patitas_care.infraestructure.security.JwtUtil;
import com.kmd.patitas_care.infraestructure.dto.request.AuthRequest;
import com.kmd.patitas_care.infraestructure.dto.response.AuthResponse;
import com.kmd.patitas_care.infraestructure.exception.InvalidPasswordException;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.Optional;

@Service
public class AuthService {
    private final ClienteRepository clienteRepository;
    private final VeterinarioRepository veterinarioRepository;
    private final JwtUtil jwtUtil;
    private final PasswordEncoder passwordEncoder;

    public AuthService(ClienteRepository clienteRepo, VeterinarioRepository vetRepo, JwtUtil jwtUtil, PasswordEncoder passwordEncoder) {
        this.clienteRepository = clienteRepo;
        this.veterinarioRepository = vetRepo;
        this.jwtUtil = jwtUtil;
        this.passwordEncoder = passwordEncoder;
    }

    public AuthResponse authenticate(AuthRequest request) {
        Autenticable usuario = buscarUsuarioPorCorreo(request.getCorreo());

        if (usuario == null) {
            throw new UsernameNotFoundException("Correo no registrado");
        }

        if (!passwordEncoder.matches(request.getPassword(), usuario.getPasswordHash())) {
            throw new InvalidPasswordException("Contraseña incorrecta");
        }

        Map<String, Object> claims = Map.of("rol", usuario.getTipo().name());
        String token = jwtUtil.generateToken(usuario.getCorreo(), claims);
        return new AuthResponse(token);
    }

    private Autenticable buscarUsuarioPorCorreo(String correo) {
        Optional<Cliente> cliente = clienteRepository.buscarPorCorreo(correo);
        if (cliente.isPresent()) return cliente.get();

        Optional<Veterinario> veterinario = veterinarioRepository.buscarPorCorreo(correo);
        return veterinario.orElse(null);
    }

    public String obtenerClienteDesdeToken(HttpServletRequest request){
            String token = extraerToken(request);
            String email = jwtUtil.extractUsername(token);
            Cliente cliente = clienteRepository.buscarPorCorreo(email)
                    .orElseThrow(() -> new RuntimeException("Cliente no encontrado"));
            return cliente.getId();
    }

    private String extraerToken(HttpServletRequest request){
        String authHeader = request.getHeader("Authorization");
        if(authHeader != null && authHeader.startsWith("Bearer ")){
            return authHeader.substring(7);
        }
        throw new RuntimeException("Token no encontrado");
    }

}

