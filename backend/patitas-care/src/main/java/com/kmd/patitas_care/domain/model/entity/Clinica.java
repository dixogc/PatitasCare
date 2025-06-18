package com.kmd.patitas_care.domain.model.entity;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;

import java.util.Map;

public class Clinica extends Usuario {
    private String nombreClinica;
    private String direccion;
    private String telefono;
    private String horarios;
    private Map<String, Double> servicios;

    public Clinica(String id, String nombre, String correo, String passwordHash, TipoDeUsuario tipo,
                   String nombreClinica, String direccion, String telefono, String horarios, Map<String, Double> servicios){
        super(id, nombre, correo, passwordHash, tipo);
        this.nombreClinica = nombreClinica;
        this.direccion = direccion;
        this.telefono = telefono;
        this.horarios = horarios;
        this.servicios = servicios;
    }

    public String getNombre() {return nombreClinica;}
    public String getDireccion() {return direccion;}
    public String getTelefono() {return telefono;}
    public String getHorarios() {return horarios;}
    public Map<String, Double> getServicios() {return servicios;}


}
