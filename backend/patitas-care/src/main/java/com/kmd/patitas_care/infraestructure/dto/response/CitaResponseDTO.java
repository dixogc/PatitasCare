package com.kmd.patitas_care.infraestructure.dto.response;

import com.kmd.patitas_care.domain.model.entity.enums.EstadoCita;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CitaResponseDTO {
    private String id;
    private String mascotaNombre;
    private String motivo;
    private LocalDateTime fechaHora;
    private EstadoCita estado;
    private String veterinarioNombre;
}
