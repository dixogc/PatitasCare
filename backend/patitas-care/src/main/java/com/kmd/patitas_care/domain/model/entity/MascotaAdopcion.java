package com.kmd.patitas_care.domain.model.entity;

import jakarta.persistence.*;

@Table(name = "mascotas_adopcion")
public class MascotaAdopcion {

    private String id;
    private String nombre;
    private String especie;
    private String raza;
    private int edad;
    private String descripcion;
    private boolean adoptado;
}
