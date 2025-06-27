package com.kmd.patitas_care.infraestructure.mapper;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Mascota;
import com.kmd.patitas_care.infraestructure.dto.request.MascotaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.MascotaResponseDTO;
import org.springframework.stereotype.Component;

@Component
public class MascotaMapper {

    public Mascota toEntityForCreate(MascotaRequestDTO dto, Cliente cliente){
        return Mascota.builder()
                .cliente(cliente)
                .nombre(dto.getNombre())
                .especie(dto.getEspecie())
                .raza(dto.getRaza())
                .edad(dto.getEdad())
                .build();
    }
    public Mascota toEntityForUpdate(MascotaRequestDTO dto, String id, Cliente cliente){
        return Mascota.builder()
                .id(id)
                .cliente(cliente)
                .nombre(dto.getNombre())
                .especie(dto.getEspecie())
                .raza(dto.getRaza())
                .edad(dto.getEdad())
                .build();
    }
    public MascotaResponseDTO toResponseDTO(Mascota mascota){
        return new MascotaResponseDTO(
                mascota.getId(),
                mascota.getCliente().getId(),
                mascota.getNombre(),
                mascota.getEspecie(),
                mascota.getRaza(),
                mascota.getEdad()
        );
    }
}
