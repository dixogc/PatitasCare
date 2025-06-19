package com.kmd.patitas_care.infraestructure.dto.request.cliente;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;


public class ActualizarClienteRequestDTO {
    @NotBlank(message = "El nombre es obligatorio")
    private String nombre;

    @Email(message = "El formato del correo no es válido")
    @NotBlank(message = "El correo es obligatorio")
    private String correo;

    @NotBlank(message = "La contraseña es obligatoria")
    @Size(min = 8, message = "La contraseña debe tener 8 o más carácteres")
    private String password;

    public String getNombre() {return nombre;}
    public String getCorreo() {return correo;}
    public String getPassword() {return password;}
}
