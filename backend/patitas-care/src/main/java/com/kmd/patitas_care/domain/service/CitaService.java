package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.infraestructure.dto.request.CitaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.CitaResponseDTO;
import java.util.List;

public interface CitaService {
    CitaResponseDTO agendarCita(CitaRequestDTO dto, String clienteId);
    List<CitaResponseDTO> obtenerCitasPorCliente(String clienteId);
    List<CitaResponseDTO> obtenerCitasPorVeterinario(String veterinarioId);
}
