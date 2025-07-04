package com.kmd.patitas_care.infraestructure.dto.response;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class VeterinariaResponse {
    private String nombre;
    private String direccion;
    private double latitud;
    private double longitud;
    private String telefono;
    private String horario;
    private double distancia;
    private String tipo;
}
