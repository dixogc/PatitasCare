package com.kmd.patitas_care.domain.model.entity;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import jakarta.persistence.*;

import java.util.Map;
@Table(name = "clinicas")
public class Clinica{
    private String id;
    private Veterinario veterinario;
    private String nombreClinica;
    private String direccion;
    private String telefono;
    private String horarios;

    public Clinica(String id, String nombreClinica, String direccion, String telefono, String horarios){
        this.id = id;
        this.nombreClinica = nombreClinica;
        this.direccion = direccion;
        this.telefono = telefono;
        this.horarios = horarios;
    }
    public String getId(){return id;}
    public String getNombre() {return nombreClinica;}
    public String getDireccion() {return direccion;}
    public String getTelefono() {return telefono;}
    public String getHorarios() {return horarios;}

}
