package com.kmd.patitas_care.infraestructure.exception;

import org.springframework.http.HttpStatus;

public class InvalidAccountTypeException extends BaseException {
    public InvalidAccountTypeException(String accountType) {
        super(
                String.format("Tipo de cuenta '%s' no válido", accountType),
                "INVALID_ACCOUNT_TYPE",
                HttpStatus.BAD_REQUEST
        );
    }
}
