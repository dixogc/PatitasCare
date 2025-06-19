package com.kmd.patitas_care.infraestructure.mapper;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.infraestructure.dto.request.cliente.ActualizarClienteRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.cliente.ClienteResponseDTO;
import org.springframework.security.core.parameters.P;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class ClienteMapper {
    private final PasswordEncoder passwordEncoder;

    public ClienteMapper(PasswordEncoder passwordEncoder){
        this.passwordEncoder = passwordEncoder;
    }

    public Cliente toEntityForUpdate(ActualizarClienteRequestDTO dto, String id, String currentPassword){
        return new Cliente.ClienteBuilder()
                .setId(id)
                .setNombre(dto.getNombre())
                .setCorreo(dto.getCorreo())
                .setPasswordHash(dto.getPassword() != null ? passwordEncoder.encode(dto.getPassword()) : currentPassword)
                .setTipo(TipoDeUsuario.CLIENTE)
                .build();
    }
    public ClienteResponseDTO toResponseDTO(Cliente cliente){
        ClienteResponseDTO dto = new ClienteResponseDTO();
        dto.setId(cliente.getId());
        dto.setNombre(cliente.getNombre());
        dto.setCorreo(cliente.getCorreo());
        dto.setTipo(cliente.getTipo());
        return dto;
    }
}
