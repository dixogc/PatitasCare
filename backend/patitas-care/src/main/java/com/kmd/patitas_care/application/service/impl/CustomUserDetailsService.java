package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.repository.ClienteRepository;
import com.kmd.patitas_care.domain.repository.VeterinarioRepository;
import com.kmd.patitas_care.infraestructure.security.UserDetailsAdapter;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CustomUserDetailsService implements UserDetailsService {
    private final ClienteRepository clienteRepository;
    private final VeterinarioRepository veterinarioRepository;

    public CustomUserDetailsService(ClienteRepository clienteRepository, VeterinarioRepository veterinarioRepository) {
        this.clienteRepository = clienteRepository;
        this.veterinarioRepository = veterinarioRepository;
    }

    @Override
    public UserDetails loadUserByUsername(String correo) throws UsernameNotFoundException {
        return clienteRepository.buscarPorCorreo(correo)
                .map(cliente -> new UserDetailsAdapter(
                        cliente.getId(),
                        cliente.getCorreo(),
                        cliente.getPasswordHash(),
                        List.of(new SimpleGrantedAuthority("ROLE_" + cliente.getTipo().name()))
                ))
                .or(() -> veterinarioRepository.buscarPorCorreo(correo)
                        .map(veterinario -> new UserDetailsAdapter(
                                veterinario.getId(),
                                veterinario.getCorreo(),
                                veterinario.getPasswordHash(),
                                List.of(new SimpleGrantedAuthority("ROLE_" + veterinario.getTipo().name()))
                        )))
                .orElseThrow(() -> new UsernameNotFoundException("Usuario no encontrado: " + correo));
    }

}
