package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.Cita;
import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Mascota;
import com.kmd.patitas_care.domain.model.entity.enums.EstadoCita;
import com.kmd.patitas_care.domain.repository.ClienteRepository;import com.kmd.patitas_care.domain.service.CitaService;
import com.kmd.patitas_care.infraestructure.dto.request.CitaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.request.CitaUpdateDTO;
import com.kmd.patitas_care.infraestructure.dto.response.CitaResponseDTO;
import com.kmd.patitas_care.infraestructure.mapper.CitaMapper;
import com.kmd.patitas_care.infraestructure.repository.jpa.CitaRepositoryJpa;
import com.kmd.patitas_care.infraestructure.repository.jpa.MascotaRepositoryJpa;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class CitaServiceImpl implements CitaService {
    private final CitaRepositoryJpa citaRepository;
    private final MascotaRepositoryJpa mascotaRepository;
    private final ClienteRepository clienteRepository;
    private final CitaMapper mapper;

    @Override
    public CitaResponseDTO agendarCita(CitaRequestDTO dto, String clienteId) {
        // Validar que la fecha no sea en el pasado
        if (dto.getFechaHora().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("No se puede agendar una cita en el pasado");
        }

        Mascota mascota = mascotaRepository.findById(dto.getMascotaId())
                .orElseThrow(() -> new RuntimeException("Mascota no encontrada"));

        Cliente cliente = clienteRepository.buscarPorId(clienteId)
                .orElseThrow(() -> new RuntimeException("Cliente no encontrado"));

        if (!mascota.getCliente().getId().equals(clienteId)) {
            throw new RuntimeException("La mascota no pertenece a este cliente");
        }

        Cita nuevaCita = mapper.toEntity(dto, mascota, cliente);
        citaRepository.save(nuevaCita);
        return mapper.toResponseDTO(nuevaCita);
    }

    @Override
    public CitaResponseDTO obtenerCitaPorId(String citaId, String clienteId) {
        Cita cita = citaRepository.findById(citaId)
                .orElseThrow(() -> new RuntimeException("Cita no encontrada"));

        if (!cita.getCliente().getId().equals(clienteId)) {
            throw new RuntimeException("No tienes permisos para ver esta cita");
        }

        // No mostrar citas canceladas en consultas normales
        if (cita.getEstado() == EstadoCita.CANCELADA) {
            throw new RuntimeException("Cita no encontrada");
        }

        return mapper.toResponseDTO(cita);
    }

    @Override
    public CitaResponseDTO obtenerCitaPorIdIncluirCanceladas(String citaId, String clienteId) {
        Cita cita = citaRepository.findById(citaId)
                .orElseThrow(() -> new RuntimeException("Cita no encontrada"));

        if (!cita.getCliente().getId().equals(clienteId)) {
            throw new RuntimeException("No tienes permisos para ver esta cita");
        }

        return mapper.toResponseDTO(cita);
    }

    @Override
    public CitaResponseDTO actualizarCita(String citaId, CitaUpdateDTO dto, String clienteId) {
        Cita cita = citaRepository.findById(citaId)
                .orElseThrow(() -> new RuntimeException("Cita no encontrada"));

        if (!cita.getCliente().getId().equals(clienteId)) {
            throw new RuntimeException("No tienes permisos para modificar esta cita");
        }

        // No permitir completar citas canceladas
        if (cita.getEstado() == EstadoCita.CANCELADA) {
            throw new RuntimeException("No se puede completar una cita cancelada");
        }

        // No permitir modificar citas canceladas
        if (cita.getEstado() == EstadoCita.CANCELADA) {
            throw new RuntimeException("No se puede modificar una cita cancelada");
        }

        // Validaciones
        if (dto.getFechaHora() != null && dto.getFechaHora().isBefore(LocalDateTime.now())) {
            throw new RuntimeException("No se puede programar una cita en el pasado");
        }

        // Actualizar campos si se proporcionan
        if (dto.getMascotaId() != null && !dto.getMascotaId().isBlank()) {
            Mascota nuevaMascota = mascotaRepository.findById(dto.getMascotaId())
                    .orElseThrow(() -> new RuntimeException("Mascota no encontrada"));

            if (!nuevaMascota.getCliente().getId().equals(clienteId)) {
                throw new RuntimeException("La mascota no pertenece a este cliente");
            }
            cita.setMascota(nuevaMascota);
        }

        if (dto.getFechaHora() != null) {
            cita.setFechaHora(dto.getFechaHora());
        }

        if (dto.getMotivo() != null && !dto.getMotivo().isBlank()) {
            cita.setMotivo(dto.getMotivo());
        }

        if (dto.getEstado() != null) {
            cita.setEstado(dto.getEstado());
        }

        citaRepository.save(cita);
        return mapper.toResponseDTO(cita);
    }

    @Override
    public CitaResponseDTO marcarComoCompletada(String citaId, String clienteId) {
        Cita cita = citaRepository.findById(citaId)
                .orElseThrow(() -> new RuntimeException("Cita no encontrada"));

        if (!cita.getCliente().getId().equals(clienteId)) {
            throw new RuntimeException("No tienes permisos para modificar esta cita");
        }

        cita.setEstado(EstadoCita.COMPLETADA);
        citaRepository.save(cita);
        return mapper.toResponseDTO(cita);
    }

    @Override
    public void eliminarCita(String citaId, String clienteId) {
        Cita cita = citaRepository.findById(citaId)
                .orElseThrow(() -> new RuntimeException("Cita no encontrada"));

        if (!cita.getCliente().getId().equals(clienteId)) {
            throw new RuntimeException("No tienes permisos para eliminar esta cita");
        }

        // No permitir cancelar una cita ya cancelada
        if (cita.getEstado() == EstadoCita.CANCELADA) {
            throw new RuntimeException("La cita ya está cancelada");
        }

        // Eliminación lógica: cambiar estado a CANCELADA
        cita.setEstado(EstadoCita.CANCELADA);
        citaRepository.save(cita);
    }

    @Override
    public List<CitaResponseDTO> obtenerCitasPorCliente(String clienteId) {
        return citaRepository.findByClienteId(clienteId).stream()
                .filter(cita -> cita.getEstado() != EstadoCita.CANCELADA) // Filtrar citas canceladas
                .map(mapper::toResponseDTO)
                .toList();
    }

    @Override
    public List<CitaResponseDTO> obtenerCitasPorVeterinario(String veterinarioId) {
        return citaRepository.findByVeterinarioId(veterinarioId).stream()
                .map(mapper::toResponseDTO)
                .toList();
    }

    public List<CitaResponseDTO> obtenerCitasSinVeterinario() {
        return citaRepository.findByVeterinarioIsNullAndEstado("PENDIENTE")
                .stream()
                .map(mapper::toResponseDTO)
                .collect(Collectors.toList());
    }

    @Override
    public List<CitaResponseDTO> obtenerTodasLasCitas(String clienteId) {
        return citaRepository.findByClienteId(clienteId).stream()
                .map(mapper::toResponseDTO)
                .toList();
    }

    @Override
    public List<CitaResponseDTO> obtenerCitasPorEstado(String clienteId, EstadoCita estado) {
        return citaRepository.findByClienteId(clienteId).stream()
                .filter(cita -> cita.getEstado() == estado)
                .map(mapper::toResponseDTO)
                .toList();
    }

}
