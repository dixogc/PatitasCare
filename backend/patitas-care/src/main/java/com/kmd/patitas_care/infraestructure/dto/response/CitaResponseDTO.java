package com.kmd.patitas_care.infraestructure.dto.response;

import com.kmd.patitas_care.domain.model.entity.enums.EstadoCita;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CitaResponseDTO {
    @Schema(description = "ID de la cita", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
    private String id;

    @Schema(description = "Nombre de la mascota a citar", example = "Kiara")
    private String mascotaNombre;

    @Schema(description = "Motivo de la cita", example = "Vacunación anual")
    private String motivo;

    @Schema(description = "Fecha y hora de la cita", example = "2025-07-05T10:30:00")
    private LocalDateTime fechaHora;

    @Schema(description = "Estado de la cita", example = "AGENDADA")
    private EstadoCita estado;

    @Schema(description = "Nombre del veterinario que atenderá la cita", example = "Juan Pérez")
    private String veterinarioNombre;
}
