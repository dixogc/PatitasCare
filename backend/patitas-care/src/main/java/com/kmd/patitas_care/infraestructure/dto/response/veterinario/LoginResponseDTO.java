package com.kmd.patitas_care.infraestructure.dto.response.veterinario;

import com.kmd.patitas_care.infraestructure.dto.response.cliente.ClienteResponseDTO;

import java.time.LocalDateTime;

public class LoginResponseDTO {
    private String token;
    private ClienteResponseDTO usuario;
    private LocalDateTime expiracion;

    public String getToken() {return token;}
    public ClienteResponseDTO getUsuario(){return usuario;}
    public LocalDateTime getExpiracion(){return expiracion;}

    public void setToken(String token) {this.token = token;}
    public void setUsuario(ClienteResponseDTO usuario) {this.usuario = usuario;}
    public void setExpiracion(LocalDateTime expiracion) {this.expiracion = expiracion;}
}
