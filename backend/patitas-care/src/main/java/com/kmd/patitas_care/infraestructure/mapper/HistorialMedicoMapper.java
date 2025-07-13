package com.kmd.patitas_care.infraestructure.mapper;

import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import com.kmd.patitas_care.infraestructure.dto.request.HistorialMedicoRequest;
import com.kmd.patitas_care.infraestructure.dto.response.HistorialMedicoResponse;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class HistorialMedicoMapper {

    public HistorialMedico toEntity(HistorialMedicoRequest request) {
        return HistorialMedico.builder()
                .mascotaId(request.getMascotaId())
                .fecha(request.getFecha())
                .titulo(request.getTitulo())
                .descripcion(request.getDescripcion())
                .tipo(request.getTipo())
                .peso(request.getPeso())
                .build();
    }

    public HistorialMedicoResponse toResponse(HistorialMedico entity) {
        return HistorialMedicoResponse.builder()
                .id(entity.getId())
                .mascotaId(entity.getMascotaId())
                .fecha(entity.getFecha())
                .titulo(entity.getTitulo())
                .descripcion(entity.getDescripcion())
                .tipo(entity.getTipo())
                .tipoDescripcion(entity.getTipo().getDescripcion())
                .peso(entity.getPeso())
                .createdAt(entity.getCreatedAt())
                .updatedAt(entity.getUpdatedAt())
                .build();
    }

    public List<HistorialMedicoResponse> toResponseList(List<HistorialMedico> entities) {
        return entities.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }

    public void updateEntityFromRequest(HistorialMedico entity, HistorialMedicoRequest request) {
        entity.setMascotaId(request.getMascotaId());
        entity.setFecha(request.getFecha());
        entity.setTitulo(request.getTitulo());
        entity.setDescripcion(request.getDescripcion());
        entity.setTipo(request.getTipo());
        entity.setPeso(request.getPeso());
    }
}
