package com.kmd.patitas_care.domain.model.entity.enums;

import io.swagger.v3.oas.annotations.media.Schema;

@Schema(description = "Tipos de usuario disponibles en el sistema")
public enum TipoDeUsuario {

    @Schema(description = "Usuario veterinario con acceso completo a casos clínicos")
    VETERINARIO,

    @Schema(description = "Usuario común con mascota")
    CLIENTE
}
