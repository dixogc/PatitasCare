package com.kmd.patitas_care.domain.model.entity;

import jakarta.persistence.*;

@Table(name = "mascotas")
public class Mascota {
    private String id;
    private Cliente cliente;
    private String nombre;
    private String especie;
    private String raza;
    private int edad;
    private String duenioId;
}
