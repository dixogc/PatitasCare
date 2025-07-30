package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.domain.model.entity.enums.EstadoCita;
import com.kmd.patitas_care.infraestructure.dto.request.CitaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.request.CitaUpdateDTO;
import com.kmd.patitas_care.infraestructure.dto.response.CitaResponseDTO;
import java.util.List;

public interface CitaService {
    CitaResponseDTO agendarCita(CitaRequestDTO dto, String clienteId);
    List<CitaResponseDTO> obtenerCitasPorCliente(String clienteId);
    List<CitaResponseDTO> obtenerCitasPorVeterinario(String veterinarioId);

    // Nuevos métodos CRUD
    CitaResponseDTO obtenerCitaPorId(String citaId, String clienteId);
    CitaResponseDTO obtenerCitaPorIdIncluirCanceladas(String citaId, String clienteId);
    CitaResponseDTO actualizarCita(String citaId, CitaUpdateDTO dto, String clienteId);
    CitaResponseDTO marcarComoCompletada(String citaId, String clienteId);
    void eliminarCita(String citaId, String clienteId);

    // Métodos adicionales para manejo de citas canceladas
    List<CitaResponseDTO> obtenerTodasLasCitas(String clienteId);
    List<CitaResponseDTO> obtenerCitasPorEstado(String clienteId, EstadoCita estado);
}
