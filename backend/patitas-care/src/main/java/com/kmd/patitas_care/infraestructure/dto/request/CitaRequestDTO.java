package com.kmd.patitas_care.infraestructure.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import com.fasterxml.jackson.annotation.JsonFormat;
import java.time.LocalDateTime;
import com.fasterxml.jackson.databind.annotation.JsonDeserialize;
import com.kmd.patitas_care.config.CustomLocalDateTimeDeserializer;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CitaRequestDTO {
    @Schema(description = "ID de la mascota para la cita", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e", required = true)
    @NotBlank
    private String mascotaId;

    @Schema(description = "Fecha y hora de la cita en formato ISO", example = "2025-07-05T10:30:00", required = true)
    @NotNull
    @JsonDeserialize(using = CustomLocalDateTimeDeserializer.class)
    private LocalDateTime fechaHora;

    @Schema(description = "Motivo o descripción de la cita", example = "Vacunación anual", required = true)
    @NotBlank
    private String motivo;
}
