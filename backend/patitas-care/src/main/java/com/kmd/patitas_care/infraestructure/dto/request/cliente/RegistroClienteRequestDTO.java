package com.kmd.patitas_care.infraestructure.dto.request.cliente;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
@Schema(description = "Datos requeridos para registrar un cliente")
public class RegistroClienteRequestDTO {

    @Schema(description = "Nombre completo del cliente", example = "Juan Pérez")
    @NotBlank(message = "El nombre es obligatorio")
    @Size(min = 2, max = 255, message = "El nombre debe tener 2 caracteres o más")
    private String nombre;

    @Schema(description = "Correo electrónico de la cuenta", example = "juanperez123@gmail.com")
    @Email(message = "El formato del correo no es válido")
    @NotBlank(message = "El correo es obligatorio")
    private String correo;

    @Schema(description = "Contraseña del usuario", example = "juanperez123", minLength = 8)
    @NotBlank(message = "La contraseña es obligatoria")
    @Size(min = 8, message = "La contraseña debe tener 8 o más carácteres")
    private String password;

    @Schema(description = "Tipo de usuario en el sistema", example = "ClIENTE")
//    @NotEmpty(message = "El tipo de usuario es obligatorio")
    private TipoDeUsuario tipoDeUsuario;

}
