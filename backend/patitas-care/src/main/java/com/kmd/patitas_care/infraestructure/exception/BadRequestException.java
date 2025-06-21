package com.kmd.patitas_care.infraestructure.exception;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
public class BadRequestException extends RuntimeException {
    public BadRequestException(String message) {
        super(message);
    }
}
