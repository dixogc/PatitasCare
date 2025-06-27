package com.kmd.patitas_care.infraestructure.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class MascotaResponseDTO {
    private String id;
    private String clienteId;
    private String nombre;
    private String especie;
    private String raza;
    private int edad;
}
