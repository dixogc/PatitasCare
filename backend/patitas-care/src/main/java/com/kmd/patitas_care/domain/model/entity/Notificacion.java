package com.kmd.patitas_care.domain.model.entity;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Table(name = "notificaciones")
public class Notificacion {
    private String id;
    private Cliente cliente;
    private String usuarioId;
    private String mensaje;
    private LocalDateTime fechaEnvio;
    private boolean leida;

    public Notificacion(String id, String usuarioId, String mensaje, LocalDateTime fechaEnvio, boolean leida){
        this.id = id;
        this.usuarioId = usuarioId;
        this.mensaje = mensaje != null ? mensaje.trim() : null;
        this.fechaEnvio = fechaEnvio;
        this.leida = leida;
    }

    private void validar(){
        if(mensaje == null || mensaje.isBlank()){
            throw new IllegalArgumentException("El mensaje no se puede enviar en blanco");
        }
    }
    private String getId(){
        return id;
    }
    private String getUsuarioId(){
        return usuarioId;
    }
    private String getMensaje(){
        return mensaje;
    }
    private LocalDateTime getFechaEnvio(){
        return fechaEnvio;
    }
    private boolean getLeida(){
        return leida;
    }
}
