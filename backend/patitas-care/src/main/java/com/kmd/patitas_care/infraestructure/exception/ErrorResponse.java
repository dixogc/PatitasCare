package com.kmd.patitas_care.infraestructure.exception;

import com.fasterxml.jackson.annotation.JsonInclude;
import io.swagger.v3.oas.annotations.media.Schema;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
@JsonInclude(JsonInclude.Include.NON_NULL)
public class ErrorResponse {

    @Schema(description = "Mensaje de error", example = "El email ya está registrado")
    private String message;

    @Schema(description = "Código de error", example = "400")
    private int statusCode;

    @Schema(description = "Código de error específico", example = "EMAIL_ALREADY_EXISTS")
    private String errorCode; // Nuevo campo importante

    @Schema(description = "Timestamp del error", example = "2024-12-20T10:30:00Z")
    private LocalDateTime timestamp;

    @Schema(description = "Path de la petición", example = "/api/usuarios")
    private String path; // Útil para debugging

    @Schema(description = "Detalles de errores de validación")
    private List<FieldError> fieldErrors; // Para errores de validación

    @Data
    @Builder
    @AllArgsConstructor
    @NoArgsConstructor
    public static class FieldError {
        private String field;
        private String message;
        private Object rejectedValue;
    }

}
