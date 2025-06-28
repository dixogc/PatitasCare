package com.kmd.patitas_care.domain.model.entity;

import jakarta.persistence.*;

import java.time.LocalDate;
import java.util.List;


@Table(name = "consultas")
public class Consulta {

    private String id;
    private Veterinario veterinario;
    private LocalDate fecha;
    private String diagnostico;
    private String tratamiento;
    private List<String> medicamentos;
}
