package com.kmd.patitas_care.infraestructure.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class MascotaResponseDTO {

    @Schema(description = "ID de la mascota", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
    private String id;

    @Schema(description = "ID del dueño", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
    private String clienteId;

    @Schema(description = "Nombre de la mascota", example = "Luna")
    private String nombre;

    @Schema(description = "Especie de la mascota", example = "Tortuga")
    private String especie;

    @Schema(description = "Raza de la mascota", example = "Labrador")
    private String raza;

    @Schema(description = "Edad de la mascota", example = "3")
    private int edad;
}
