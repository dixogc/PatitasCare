package com.kmd.patitas_care.infraestructure.mapper;

import com.kmd.patitas_care.domain.model.entity.Cita;
import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Mascota;
import com.kmd.patitas_care.domain.model.entity.enums.EstadoCita;
import com.kmd.patitas_care.infraestructure.dto.request.CitaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.CitaResponseDTO;
import org.springframework.stereotype.Component;

@Component
public class CitaMapper {
    public CitaResponseDTO toResponseDTO(Cita cita) {
        return new CitaResponseDTO(
                cita.getId(),
                cita.getMascota().getNombre(),
                cita.getMotivo(),
                cita.getFechaHora(),
                cita.getEstado(),
                cita.getVeterinario() != null ? cita.getVeterinario().getNombre() : "Sin asignar"
        );
    }
    public Cita toEntity(CitaRequestDTO dto, Mascota mascota, Cliente cliente) {
        return Cita.builder()
                .motivo(dto.getMotivo())
                .fechaHora(dto.getFechaHora())
                .mascota(mascota)
                .cliente(cliente)
                .estado(EstadoCita.PENDIENTE) // puedes dejar esto fijo al agendar
                .build();
    }
}
