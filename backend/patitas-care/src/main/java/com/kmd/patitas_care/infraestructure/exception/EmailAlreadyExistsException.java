package com.kmd.patitas_care.infraestructure.exception;

import org.springframework.http.HttpStatus;

public class EmailAlreadyExistsException extends BaseException {
    public EmailAlreadyExistsException(String email) {
        super(
                String.format("El email '%s' ya está registrado", email),
                "EMAIL_ALREADY_EXISTS",
                HttpStatus.CONFLICT
        );
    }
}
