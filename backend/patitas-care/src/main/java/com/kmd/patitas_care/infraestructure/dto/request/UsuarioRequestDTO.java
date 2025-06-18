package com.kmd.patitas_care.infraestructure.dto.request;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class UsuarioRequestDTO {
    @NotBlank(message = "El nombre de usuario es requerido")
    @Size(min = 2, max = 50, message = "El nombre debe tener 2 o más caracteres")
    private String nombre;

    @Email(message = "El correo electrónico es requerido")
    @NotBlank(message = "Debe ingresar un correo")
    private String correo;

    @Size(min = 8 ,message = "La contraseña debe tener 8 o más caracteres")
    @NotBlank(message = "La contraseña es requerida")
    private String password;

    public UsuarioRequestDTO(){}

    public UsuarioRequestDTO(String nombre, String correo, String password){
        this.nombre = nombre;
        this.correo = correo;
        this.password = password;
    }

    public String getNombre(){
        return nombre;
    }
    public String getCorreo(){
        return correo;
    }
    public String getPassword(){ return password;}
}
