package com.kmd.patitas_care.infraestructure.dto.response.cliente;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@NoArgsConstructor
@AllArgsConstructor
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
