package com.kmd.patitas_care.infraestructure.dto.request;

import com.kmd.patitas_care.domain.model.entity.enums.Sexo;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.*;

import java.time.LocalDate;

@Builder
@Setter
@Getter
@AllArgsConstructor
@NoArgsConstructor
public class MascotaRequestDTO {

    @Schema(hidden = true)
    private String clienteId;

    @Schema(description = "Nombre de la mascota)", example = "Firulais", required = true)
    @NotBlank
    private String nombre;

    @NotBlank(message = "La especie es obligatoria")
    private String especie;

    private String raza;

    private Sexo sexo;

    private Boolean esterilizado;

    private LocalDate fechaNacimiento;

    private int edad;

    private String color;
}
