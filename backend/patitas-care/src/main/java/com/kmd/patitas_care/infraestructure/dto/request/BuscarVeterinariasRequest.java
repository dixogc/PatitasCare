package com.kmd.patitas_care.infraestructure.dto.request;

import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@AllArgsConstructor
@NoArgsConstructor
@Getter
@Setter
public class BuscarVeterinariasRequest {
    private double latitud;
    private double longitud;
    private Integer radio;
    private String contexto;
}
