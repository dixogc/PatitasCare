package com.kmd.patitas_care.infraestructure.dto.response;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
@Schema(description = "Respuesta tras iniciar sesión exitosamente")
public class AuthResponse {
    @Schema(description = "Token de autenticación del usuario")
    private String token;
}
