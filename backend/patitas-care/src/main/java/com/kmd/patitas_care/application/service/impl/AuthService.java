package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.repository.Autenticable;
import com.kmd.patitas_care.domain.repository.ClienteRepository;
import com.kmd.patitas_care.domain.repository.VeterinarioRepository;
import com.kmd.patitas_care.infraestructure.exception.UserNotFoundException;
import com.kmd.patitas_care.infraestructure.security.JwtUtil;
import com.kmd.patitas_care.infraestructure.dto.request.AuthRequest;
import com.kmd.patitas_care.infraestructure.dto.response.AuthResponse;
import com.kmd.patitas_care.infraestructure.exception.InvalidPasswordException;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
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
    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    public AuthService(ClienteRepository clienteRepo, VeterinarioRepository vetRepo, JwtUtil jwtUtil, PasswordEncoder passwordEncoder) {
        this.clienteRepository = clienteRepo;
        this.veterinarioRepository = vetRepo;
        this.jwtUtil = jwtUtil;
        this.passwordEncoder = passwordEncoder;
    }

    public String obtenerClienteDesdeToken(HttpServletRequest request){
        try {
            log.info("=== INICIANDO obtenerClienteDesdeToken ===");

            String token = extraerToken(request);
            log.info("Token extraído exitosamente: {}", token.substring(0, Math.min(token.length(), 20)) + "...");

            String email = jwtUtil.extractUsername(token);
            log.info("Email extraído del token: {}", email);

            Cliente cliente = clienteRepository.buscarPorCorreo(email)
                    .orElseThrow(() -> {
                        log.error("Cliente no encontrado con email: {}", email);
                        return new UserNotFoundException("Cliente no encontrado");
                    });

            log.info("Cliente encontrado - ID: {}, Email: {}", cliente.getId(), cliente.getCorreo());
            log.info("=== FIN obtenerClienteDesdeToken - Retornando ID: {} ===", cliente.getId());

            return cliente.getId();
        } catch (Exception e) {
            log.error("Error en obtenerClienteDesdeToken: {}", e.getMessage(), e);
            throw e;
        }
    }

    private String extraerToken(HttpServletRequest request){
        log.info("Extrayendo token del request...");
        String authHeader = request.getHeader("Authorization");
        log.info("Authorization header: {}", authHeader != null ? authHeader.substring(0, Math.min(authHeader.length(), 20)) + "..." : "null");

        if(authHeader != null && authHeader.startsWith("Bearer ")){
            String token = authHeader.substring(7);
            log.info("Token extraído correctamente");
            return token;
        }
        log.error("Token no encontrado o mal formateado");
        throw new RuntimeException("Token no encontrado");
    }
}

