package com.kmd.patitas_care.infraestructure.dto.response.veterinario;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;

public class VeterinarioResponseDTO {
    private String id;
    private String nombre;
    private String correo;
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
