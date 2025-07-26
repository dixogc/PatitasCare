package com.kmd.patitas_care.infraestructure.mapper;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Mascota;
import com.kmd.patitas_care.infraestructure.dto.request.MascotaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.MascotaResponseDTO;
import org.springframework.stereotype.Component;

@Component
public class MascotaMapper {

    public Mascota toEntityForCreate(MascotaRequestDTO dto, Cliente cliente) {
        return Mascota.builder()
                .cliente(cliente)
                .nombre(dto.getNombre())
                .especie(dto.getEspecie())
                .raza(dto.getRaza())
                .sexo(dto.getSexo())
                .esterilizado(dto.getEsterilizado())
                .fechaNacimiento(dto.getFechaNacimiento())
                .edad(dto.getEdad())
                .color(dto.getColor())
                .build();
    }

    public Mascota toEntityForUpdate(MascotaRequestDTO dto, String id, Cliente cliente) {
        return Mascota.builder()
                .id(id)
                .cliente(cliente)
                .nombre(dto.getNombre())
                .especie(dto.getEspecie())
                .raza(dto.getRaza())
                .sexo(dto.getSexo())
                .esterilizado(dto.getEsterilizado())
                .fechaNacimiento(dto.getFechaNacimiento())
                .edad(dto.getEdad())
                .color(dto.getColor())
                .build();
    }

    public MascotaResponseDTO toResponseDTO(Mascota mascota) {
        return MascotaResponseDTO.builder()
                .id(mascota.getId())
                .clienteId(mascota.getCliente().getId())
                .nombre(mascota.getNombre())
                .especie(mascota.getEspecie())
                .raza(mascota.getRaza())
                .sexo(mascota.getSexo())
                .esterilizado(mascota.getEsterilizado())
                .fechaNacimiento(mascota.getFechaNacimiento())
                .edad(mascota.getEdad())
                .color(mascota.getColor())
                .build();
    }
}
