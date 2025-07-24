package com.kmd.patitas_care.infraestructure.mapper;

import com.kmd.patitas_care.domain.model.entity.HistorialMedico;
import com.kmd.patitas_care.domain.model.entity.Mascota;
import com.kmd.patitas_care.infraestructure.dto.request.HistorialMedicoRequest;
import com.kmd.patitas_care.infraestructure.dto.response.HistorialMedicoResponse;
import org.springframework.stereotype.Component;

@Component
public class HistorialMedicoMapper {

    public static HistorialMedico toEntity(HistorialMedicoRequest dto, String mascotaId) {
        return HistorialMedico.builder()
                .mascota(Mascota.builder().id(mascotaId).build())
                .fechaEvento(dto.getFechaEvento())
                .tipoEvento(dto.getTipoEvento())
                .descripcion(dto.getDescripcion())
                .peso(dto.getPeso())
                .diagnostico(dto.getDiagnostico())
                .tratamiento(dto.getTratamiento())
                .fechaProximaRevision(dto.getFechaProximaRevision())
                .veterinario(dto.getVeterinario())
                .build();
    }

    public static HistorialMedicoResponse toResponseDTO(HistorialMedico historial) {
        return HistorialMedicoResponse.builder()
                .id(historial.getId())
                .mascotaId(historial.getMascota().getId())
                .fechaEvento(historial.getFechaEvento())
                .tipoEvento(historial.getTipoEvento())
                .descripcion(historial.getDescripcion())
                .peso(historial.getPeso())
                .diagnostico(historial.getDiagnostico())
                .tratamiento(historial.getTratamiento())
                .fechaProximaRevision(historial.getFechaProximaRevision())
                .veterinario(historial.getVeterinario())
                .build();
    }

    public static void updateEntity(HistorialMedico entity, HistorialMedicoRequest dto) {
        entity.setFechaEvento(dto.getFechaEvento());
        entity.setTipoEvento(dto.getTipoEvento());
        entity.setDescripcion(dto.getDescripcion());
        entity.setPeso(dto.getPeso());
        entity.setDiagnostico(dto.getDiagnostico());
        entity.setTratamiento(dto.getTratamiento());
        entity.setFechaProximaRevision(dto.getFechaProximaRevision());
        entity.setVeterinario(dto.getVeterinario());
    }
}
