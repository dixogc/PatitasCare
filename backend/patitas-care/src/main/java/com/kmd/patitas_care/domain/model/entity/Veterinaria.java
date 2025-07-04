package com.kmd.patitas_care.domain.model.entity;

import lombok.*;

@AllArgsConstructor
@NoArgsConstructor
@Builder
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
