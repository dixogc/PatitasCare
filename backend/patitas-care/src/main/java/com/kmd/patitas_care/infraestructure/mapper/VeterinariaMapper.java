package com.kmd.patitas_care.infraestructure.mapper;

import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.infraestructure.dto.response.VeterinariaResponse;
import org.springframework.stereotype.Component;

@Component
public class VeterinariaMapper {
    public VeterinariaResponse toResponse(Veterinaria veterinaria) {
        return new VeterinariaResponse(
                veterinaria.getNombre(),
                veterinaria.getDireccion(),
                veterinaria.getLatitud(),
                veterinaria.getLongitud(),
                veterinaria.getTelefono(),
                veterinaria.getHorario(),
                veterinaria.getDistancia(),
                veterinaria.getTipo()
        );
    }
}
