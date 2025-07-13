package com.kmd.patitas_care.domain.model.entity.enums;

import lombok.Getter;

@Getter
public enum TipoEventoMedico {
    VACUNACION("Vacunación"),
    CONSULTA("Consulta"),
    CIRUGIA("Cirugía"),
    ALERGIA("Alergia"),
    DESPARASITACION("Desparasitación"),
    CHEQUEO("Chequeo General"),
    EMERGENCIA("Emergencia"),
    TRATAMIENTO("Tratamiento"),
    EXAMEN("Examen/Análisis"),
    OTRO("Otro");

    private final String descripcion;

    TipoEventoMedico(String descripcion) {
        this.descripcion = descripcion;
    }

}
