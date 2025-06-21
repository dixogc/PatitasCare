package com.kmd.patitas_care.infraestructure.dto.request.veterinario;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "Datos requeridos para registrar un veterinario")
public class RegistroVeterinarioRequestDTO {

    @Schema(description = "Nombre completo del veterinario", example = "Juan Pérez")
    @NotBlank(message = "El nombre es obligatorio")
    @Size(min = 2, max = 255, message = "El nombre debe tener 2 caracteres o más")
    private String nombre;

    @Schema(description = "Correo del veterinario", example = "juanperez@gmial.com")
    @Email(message = "El formato del correo no es válido")
    @NotBlank(message = "El correo es obligatorio")
    private String correo;

    @Schema(description = "Contraseña para la cuenta", example = "juanperez123", minLength = 8)
    @NotBlank(message = "La contraseña es obligatoria")
    @Size(min = 8, message = "La contraseña debe tener 8 o más carácteres")
    private String password;

    @Schema(description = "Tipo de usuario en el sistema", example = "VETERINARIO")
//    @NotEmpty(message = "El tipo de usuario es obligatorio")
    private TipoDeUsuario tipoDeUsuario;

}
