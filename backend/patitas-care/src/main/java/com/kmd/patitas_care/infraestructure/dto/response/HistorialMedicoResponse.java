package com.kmd.patitas_care.infraestructure.dto.response;

import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HistorialMedicoResponse {
    private String id;
    private String mascotaId;
    private LocalDate fecha;
    private String titulo;
    private String descripcion;
    private TipoEventoMedico tipo;
    private String tipoDescripcion;
    private Double peso;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
