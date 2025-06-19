package com.kmd.patitas_care.domain.model.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

public class Cita {

    private String id;
    private String mascotaId;
    private LocalDateTime fechaHora;
    private String motivo;
    private String estado;
}
