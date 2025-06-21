package com.kmd.patitas_care.infraestructure.dto.response.cliente;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.NoArgsConstructor;

@AllArgsConstructor
@NoArgsConstructor
@Schema(description = "Respuesta tras registrar al usuario tipo cliente exitosamente")
public class ClienteResponseDTO {

    @Schema(description = "ID único del usuario", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
    private String id;
    @Schema(description = "Nombre completo del usuario", example = "Juan Pérez")
    private String nombre;
    @Schema(description = "Correo electrónico del usuario", example = "juanperez@gmail.com")
    private String correo;
    @Schema(description = "Tipo de cuenta del usuario", example = "CLIENTE")
    private TipoDeUsuario tipo;

    public String getId() {return id;}
    public String getNombre(){return nombre;}
    public String getCorreo(){return correo;}
    public TipoDeUsuario getTipo(){return tipo;}

    public void setId(String id) {this.id = id;}
    public void setNombre(String nombre) {this.nombre = nombre;}
    public void setCorreo(String correo) {this.correo = correo;}
    public void setTipo(TipoDeUsuario tipo) {this.tipo = tipo;}
}
