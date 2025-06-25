package com.kmd.patitas_care.domain.repository;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;

public interface Autenticable {
    String getCorreo();
    String getPasswordHash();
    TipoDeUsuario getTipo();
}
