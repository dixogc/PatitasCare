package com.kmd.patitas_care.infraestructure.dto.response;

import com.kmd.patitas_care.domain.model.entity.enums.TipoEventoMedico;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class HistorialMedicoResponse {
    private String id;
    private String mascotaId;
    private LocalDate fechaEvento;
    private String tipoEvento;
    private String descripcion;
    private Double peso;
    private String diagnostico;
    private String tratamiento;
    private LocalDate fechaProximaRevision;
    private String veterinario;
}
