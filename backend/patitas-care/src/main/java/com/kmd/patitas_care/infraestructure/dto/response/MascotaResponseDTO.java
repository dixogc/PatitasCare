package com.kmd.patitas_care.infraestructure.dto.response;

import com.kmd.patitas_care.domain.model.entity.enums.Sexo;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.*;

import java.time.LocalDate;

@Builder
@Setter
@Getter
@AllArgsConstructor
@NoArgsConstructor
public class MascotaResponseDTO {

    private String id;

    private String clienteId;

    private String nombre;

    private String especie;

    private String raza;

    private Sexo sexo;

    private Boolean esterilizado;

    private LocalDate fechaNacimiento;

    private int edad;

    private String color;
}
