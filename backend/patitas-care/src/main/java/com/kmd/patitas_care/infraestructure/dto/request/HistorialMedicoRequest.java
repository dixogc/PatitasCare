package com.kmd.patitas_care.infraestructure.dto.request;

import jakarta.validation.constraints.*;
import lombok.*;

import java.time.LocalDate;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HistorialMedicoRequest {

    @NotNull(message = "La fecha del evento es obligatoria")
    @PastOrPresent(message = "La fecha del evento no puede ser futura")
    private LocalDate fechaEvento;

    @NotBlank(message = "El tipo de evento es obligatorio")
    @Size(max = 100, message = "El tipo de evento no puede exceder 100 caracteres")
    private String tipoEvento;

    @Size(max = 1000, message = "La descripción no puede exceder 1000 caracteres")
    private String descripcion;

    @DecimalMin(value = "0.1", message = "El peso debe ser mayor a 0.1 kg")
    @DecimalMax(value = "200.0", message = "El peso no puede exceder 200 kg")
    @Digits(integer = 3, fraction = 2, message = "El peso debe tener máximo 3 enteros y 2 decimales")
    private Double peso;

    @Size(max = 1000, message = "El diagnóstico no puede exceder 1000 caracteres")
    private String diagnostico;

    @Size(max = 1000, message = "El tratamiento no puede exceder 1000 caracteres")
    private String tratamiento;

    @Future(message = "La fecha de próxima revisión debe ser futura")
    private LocalDate fechaProximaRevision;

    @Size(max = 100, message = "El nombre del veterinario no puede exceder 100 caracteres")
    private String veterinario;
}
