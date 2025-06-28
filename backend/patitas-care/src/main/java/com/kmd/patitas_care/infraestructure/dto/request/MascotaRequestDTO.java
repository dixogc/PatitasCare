package com.kmd.patitas_care.infraestructure.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class MascotaRequestDTO {

    @Schema(hidden = true)
    private String clienteId;

    @Schema(description = "Nombre de la mascota)", example = "Firulais", required = true)
    @NotBlank
    private String nombre;

    @Schema(description = "Especie de la mascota", example = "Perro, tortuga, conejo", required = true)
    private String especie;

    @Schema(description = "Raza de la mascota", example = "Labrador, Tuxedo", required = true)
    private String raza;

    @Schema(description = "Edad de la mascota en años", example = "3", required = true)
    @Min(0)
    private int edad;
}
