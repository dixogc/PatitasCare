package com.kmd.patitas_care.domain.model.entity;

import java.time.LocalDate;
import java.util.List;

public class Consulta {
    private String id;
    private LocalDate fecha;
    private String veterinarioId;
    private String diagnostico;
    private String tratamiento;
    private List<String> medicamentos;
}
