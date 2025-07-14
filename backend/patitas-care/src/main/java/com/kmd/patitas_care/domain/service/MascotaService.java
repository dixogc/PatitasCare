package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.infraestructure.dto.request.MascotaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.MascotaResponseDTO;

import java.util.List;

public interface MascotaService {
    MascotaResponseDTO crearMascota(MascotaRequestDTO dto);
    MascotaResponseDTO obtenerPorId(String id);
    List<MascotaResponseDTO> listarTodas();
    MascotaResponseDTO actualizarMascota(String id, MascotaRequestDTO dto);
    void eliminarPorId(String id);
    List<MascotaResponseDTO> obtenerMascotasPorCliente(String clienteId);
    MascotaResponseDTO obtenerMascotaDelCliente(String mascotaId, String clienteId);
    MascotaResponseDTO actualizarMascotaDelCliente(String mascotaId, MascotaRequestDTO dto, String clienteId);
    void eliminarMascotaDelCliente(String mascotaId, String clienteId);
    boolean mascotaPertenenceAlUsuario(String mascotaId, String clienteId);
}
