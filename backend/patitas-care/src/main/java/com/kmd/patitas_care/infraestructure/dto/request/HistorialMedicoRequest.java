package com.kmd.patitas_care.infraestructure.dto.request;

import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import jakarta.validation.constraints.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HistorialMedicoRequest {

    @NotBlank(message = "El ID de la mascota es requerido")
    private String mascotaId;

    @NotNull(message = "La fecha es requerida")
    @PastOrPresent(message = "La fecha no puede ser futura")
    private LocalDate fecha;

    @NotBlank(message = "El título es requerido")
    @Size(max = 200, message = "El título no puede exceder los 200 caracteres")
    private String titulo;

    @Size(max = 2000, message = "La descripción no puede exceder los 2000 caracteres")
    private String descripcion;

    @NotNull(message = "El tipo de evento es requerido")
    private TipoEventoMedico tipo;

    @DecimalMin(value = "0.1", message = "El peso debe ser mayor a 0.1 kg")
    @DecimalMax(value = "999.99", message = "El peso no puede exceder los 999.99 kg")
    private Double peso;
}
