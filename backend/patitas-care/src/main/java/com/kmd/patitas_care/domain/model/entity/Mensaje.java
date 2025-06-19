package com.kmd.patitas_care.domain.model.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Table(name = "mensajes")
public class Mensaje {

    private String id;
    private Cliente cliente;
    private Veterinario veterinario;
    private String remitenteId;
    private String destinatarioId;
    private String contenido;
    private LocalDateTime fecha;

    public Mensaje(String id, String remitenteId, String destinatarioId, String contenido, LocalDateTime fecha){
        this.id = id;
        this.remitenteId = remitenteId;
        this.destinatarioId = destinatarioId;
        this.contenido = contenido;
        this.fecha = fecha;
    }
}
