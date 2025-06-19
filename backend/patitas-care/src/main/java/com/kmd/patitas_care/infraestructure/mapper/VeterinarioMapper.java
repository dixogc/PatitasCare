package com.kmd.patitas_care.infraestructure.mapper;

import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.infraestructure.dto.request.veterinario.ActualizarVeterinarioRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.veterinario.VeterinarioResponseDTO;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class VeterinarioMapper {
    private final PasswordEncoder passwordEncoder;

    public VeterinarioMapper(PasswordEncoder passwordEncoder){
        this.passwordEncoder = passwordEncoder;
    }

    public Veterinario toEntityForUpdate(ActualizarVeterinarioRequestDTO dto, String id, String currentPassword){
        return new Veterinario.VeterinarioBuilder()
                .setId(id)
                .setNombre(dto.getNombre())
                .setCorreo(dto.getCorreo())
                .setPasswordHash(dto.getPassword() != null ? passwordEncoder.encode(dto.getPassword()) : currentPassword)
                .setTipo(TipoDeUsuario.VETERINARIO)
                .build();
    }
    public VeterinarioResponseDTO toResponseDTO(Veterinario veterinario){
        VeterinarioResponseDTO dto = new VeterinarioResponseDTO();
        dto.setId(veterinario.getId());
        dto.setNombre(veterinario.getNombre());
        dto.setCorreo(veterinario.getCorreo());
        dto.setTipo(veterinario.getTipo());
        return dto;
    }

}
