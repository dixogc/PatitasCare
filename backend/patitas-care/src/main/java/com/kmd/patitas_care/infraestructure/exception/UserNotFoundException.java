package com.kmd.patitas_care.infraestructure.exception;

import org.springframework.http.HttpStatus;

// Excepciones específicas para usuarios
public class UserNotFoundException extends BaseException {
    public UserNotFoundException(String identifier) {
        super(
                String.format("Usuario con identificador '%s' no encontrado", identifier),
                "USER_NOT_FOUND",
                HttpStatus.NOT_FOUND
        );
    }
}
