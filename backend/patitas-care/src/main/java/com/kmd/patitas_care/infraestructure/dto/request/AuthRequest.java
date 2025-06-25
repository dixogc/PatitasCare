package com.kmd.patitas_care.infraestructure.dto.request;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
@Schema(description = "Datos requeridos para el inicio de sesión")
public class AuthRequest {
    @Schema(description = "Correo del usuario", example = "juanperez@gmial.com")
    @Email(message = "El formato del correo no es válido")
    @NotBlank(message = "El correo es obligatorio")
    private String correo;

    @Schema(description = "Contraseña de la cuenta", example = "juanperez123", minLength = 8)
    @NotBlank(message = "La  contraseña es obligatoria")
    private String password;
}
