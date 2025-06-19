package com.kmd.patitas_care.infraestructure.dto.request.cliente;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

public class RegistroClienteRequestDTO {
    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;

    @Email(message = "El formato del correo no es válido")
    @NotBlank(message = "El correo es obligatorio")
    private String correo;

    @NotBlank(message = "La contraseña es obligatoria")
    @Size(min = 8, message = "La contraseña debe tener 8 o más carácteres")
    private String password;

//    @NotBlank(message = "El tipo de usuario es obligatorio")
    private TipoDeUsuario tipoDeUsuario;

    public String getNombre() {return nombre;}

    public String getCorreo() {return correo;}

    public String getPassword() {return password;}

    public TipoDeUsuario getTipoDeUsuario() {return tipoDeUsuario;}
}
