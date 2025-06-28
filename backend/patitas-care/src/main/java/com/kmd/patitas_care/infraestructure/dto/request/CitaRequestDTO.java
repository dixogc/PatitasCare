package com.kmd.patitas_care.infraestructure.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CitaRequestDTO {
    private String mascotaId;
    private LocalDateTime fechaHora;
    private String motivo;
}
