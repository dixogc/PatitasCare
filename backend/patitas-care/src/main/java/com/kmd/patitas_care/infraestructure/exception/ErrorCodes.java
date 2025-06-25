package com.kmd.patitas_care.infraestructure.exception;

public class ErrorCodes {
    // Usuario
    public static final String USER_NOT_FOUND = "USER_NOT_FOUND";
    public static final String EMAIL_ALREADY_EXISTS = "EMAIL_ALREADY_EXISTS";
    public static final String INVALID_PASSWORD = "INVALID_PASSWORD";
    public static final String INVALID_ACCOUNT_TYPE = "INVALID_ACCOUNT_TYPE";

    // Validación
    public static final String VALIDATION_ERROR = "VALIDATION_ERROR";

    // Sistema
    public static final String INTERNAL_SERVER_ERROR = "INTERNAL_SERVER_ERROR";
    public static final String DATA_INTEGRITY_VIOLATION = "DATA_INTEGRITY_VIOLATION";
}
