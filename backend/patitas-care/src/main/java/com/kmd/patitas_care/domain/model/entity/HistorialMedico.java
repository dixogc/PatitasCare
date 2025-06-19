package com.kmd.patitas_care.domain.model.entity;

import jakarta.persistence.*;

import java.util.List;

@Table(name = "historial_medico")
public class HistorialMedico {

    private String id;
    private String mascotaId;
    private List<Consulta> consultas;
}
