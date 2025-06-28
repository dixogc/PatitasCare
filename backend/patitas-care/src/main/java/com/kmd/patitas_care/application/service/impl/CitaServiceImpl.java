package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.Cita;
import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Mascota;
import com.kmd.patitas_care.domain.model.entity.enums.EstadoCita;
import com.kmd.patitas_care.domain.repository.ClienteRepository;
import com.kmd.patitas_care.domain.repository.VeterinarioRepository;
import com.kmd.patitas_care.domain.service.CitaService;
import com.kmd.patitas_care.infraestructure.dto.request.CitaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.CitaResponseDTO;
import com.kmd.patitas_care.infraestructure.mapper.CitaMapper;
import com.kmd.patitas_care.infraestructure.repository.jpa.CitaRepositoryJpa;
import com.kmd.patitas_care.infraestructure.repository.jpa.MascotaRepositoryJpa;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Transactional
public class CitaServiceImpl implements CitaService {
    private final CitaRepositoryJpa citaRepository;
    private final MascotaRepositoryJpa mascotaRepository;
    private final ClienteRepository clienteRepository;
    private final VeterinarioRepository veterinarioRepository;
    private final CitaMapper mapper;

    @Override
    public CitaResponseDTO agendarCita(CitaRequestDTO dto, String clienteId) {
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
    public List<CitaResponseDTO> obtenerCitasPorCliente(String clienteId) {
        return citaRepository.findByClienteId(clienteId).stream()
                .map(mapper::toResponseDTO)
                .toList();
    }

    @Override
    public List<CitaResponseDTO> obtenerCitasPorVeterinario(String veterinarioId) {
        return citaRepository.findByVeterinarioId(veterinarioId).stream()
                .map(mapper::toResponseDTO)
                .toList();
    }

    private CitaResponseDTO toResponseDTO(Cita cita) {
        return new CitaResponseDTO(
                cita.getId(),
                cita.getMascota().getNombre(),
                cita.getMotivo(),
                cita.getFechaHora(),
                cita.getEstado(),
                cita.getVeterinario() != null ? cita.getVeterinario().getNombre() : "Sin asignar"
        );
    }
    public List<CitaResponseDTO> obtenerCitasSinVeterinario() {
        return citaRepository.findByVeterinarioIsNullAndEstado("PENDIENTE")
                .stream()
                .map(mapper::toResponseDTO)
                .collect(Collectors.toList());
    }

}
