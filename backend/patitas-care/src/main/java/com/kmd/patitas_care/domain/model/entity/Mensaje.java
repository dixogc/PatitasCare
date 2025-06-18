package com.kmd.patitas_care.domain.model.entity;

import java.time.LocalDateTime;

public class Mensaje {
    private String id;
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
