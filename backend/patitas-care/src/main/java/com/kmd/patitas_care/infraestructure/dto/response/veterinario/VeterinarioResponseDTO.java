package com.kmd.patitas_care.infraestructure.dto.response.veterinario;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Schema(description = "Respuesta tras registrar al usuario tipo veterinario exitosamente")
public class VeterinarioResponseDTO {

    @Schema(description = "ID único del veterinario", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
    private String id;

    @Schema(description = "Nombre completo del veterinario", example = "Juan Pérez")
    private String nombre;

    @Schema(description = "Correo electrónico del veterinario", example = "juanperez@gmail.com")
    private String correo;

    @Schema(description = "Tipo de cuenta del usuario", example = "VETERINARIO")
    private TipoDeUsuario tipo;

}
