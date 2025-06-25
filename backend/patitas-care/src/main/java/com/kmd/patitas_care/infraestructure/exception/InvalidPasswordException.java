package com.kmd.patitas_care.infraestructure.exception;

import org.springframework.http.HttpStatus;

public class InvalidPasswordException extends BaseException {
    public InvalidPasswordException(String reason) {
        super(
                "Contraseña inválida: " + reason,
                "INVALID_PASSWORD",
                HttpStatus.BAD_REQUEST
        );
    }
}
