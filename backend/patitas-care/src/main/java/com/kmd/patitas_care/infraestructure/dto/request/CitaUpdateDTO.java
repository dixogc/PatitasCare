package com.kmd.patitas_care.infraestructure.dto.request;

import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.kmd.patitas_care.domain.model.entity.enums.EstadoCita;
import com.kmd.patitas_care.infraestructure.config.CustomLocalDateTimeDeserializer;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CitaUpdateDTO {
    @Schema(description = "ID de la mascota para la cita", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
    private String mascotaId;

    @Schema(description = "Fecha y hora de la cita en formato ISO", example = "2025-07-05T10:30:00")
    @JsonDeserialize(using = CustomLocalDateTimeDeserializer.class)
    private LocalDateTime fechaHora;

    @Schema(description = "Motivo o descripción de la cita", example = "Vacunación anual")
    private String motivo;

    @Schema(description = "Estado de la cita", example = "COMPLETADA")
    private EstadoCita estado;
}
