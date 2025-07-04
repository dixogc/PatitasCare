package com.kmd.patitas_care.domain.model.entity;

import jakarta.persistence.Entity;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class Veterinaria {
    private String nombre;
    private String direccion;
    private double latitud;
    private double longitud;
    private String telefono;
    private String horario;
    private double distancia; // en kilómetros
    private String tipo;
}
