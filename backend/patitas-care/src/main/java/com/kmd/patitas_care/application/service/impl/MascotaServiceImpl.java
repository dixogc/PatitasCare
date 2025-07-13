package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Mascota;
import com.kmd.patitas_care.domain.repository.ClienteRepository;
import com.kmd.patitas_care.domain.service.MascotaService;
import com.kmd.patitas_care.infraestructure.dto.request.MascotaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.MascotaResponseDTO;
import com.kmd.patitas_care.infraestructure.mapper.MascotaMapper;
import com.kmd.patitas_care.infraestructure.repository.jpa.MascotaRepositoryJpa;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class MascotaServiceImpl implements MascotaService {

    private final MascotaRepositoryJpa mascotaRepositoryJpa;
    private final ClienteRepository clienteRepository;
    private final MascotaMapper mapper;

    public MascotaServiceImpl(MascotaRepositoryJpa mascotaRepositoryJpa, ClienteRepository clienteRepository,
                              MascotaMapper mapper){
        this.mascotaRepositoryJpa = mascotaRepositoryJpa;
        this.clienteRepository = clienteRepository;
        this.mapper = mapper;
    }

    @Override
    public MascotaResponseDTO crearMascota(MascotaRequestDTO dto) {
        Cliente cliente = clienteRepository.buscarPorId(dto.getClienteId())
                .orElseThrow(() -> new RuntimeException("Cliente no encontrado"));
        Mascota mascota = mapper.toEntityForCreate(dto, cliente);
        return mapper.toResponseDTO(mascotaRepositoryJpa.save(mascota));
    }

    @Override
    public MascotaResponseDTO obtenerPorId(String id){
        Mascota mascota = mascotaRepositoryJpa.findById(id)
                .orElseThrow(() -> new  RuntimeException("Mascota no encontrada"));
        return mapper.toResponseDTO(mascota);
    }
    @Override
    public List<MascotaResponseDTO> listarTodas(){
        return mascotaRepositoryJpa.findAll().stream()
                .map(mapper::toResponseDTO)
                .collect(Collectors.toList());
    }

    @Override
    public MascotaResponseDTO actualizarMascota(String id, MascotaRequestDTO dto) {
        Cliente cliente = clienteRepository.buscarPorId(dto.getClienteId())
                .orElseThrow(() -> new RuntimeException("Cliente no encontrado"));
        Mascota mascota = mapper.toEntityForUpdate(dto, id, cliente);
        return mapper.toResponseDTO(mascotaRepositoryJpa.save(mascota));
    }
    @Override
    public void eliminarPorId(String id){
        mascotaRepositoryJpa.deleteById(id);
    }

    @Override
    public List<MascotaResponseDTO> obtenerMascotasPorCliente(String clienteId) {
        clienteRepository.buscarPorId(clienteId)
                .orElseThrow(() -> new RuntimeException("Cliente no encontrado"));

        return mascotaRepositoryJpa.findByClienteId(clienteId).stream()
                .map(mapper::toResponseDTO)
                .collect(Collectors.toList());
    }

    @Override
    public MascotaResponseDTO obtenerMascotaDelCliente(String mascotaId, String clienteId) {
        Mascota mascota = mascotaRepositoryJpa.findById(mascotaId)
                .orElseThrow(() -> new RuntimeException("Mascota no encontrada"));

        if (!mascota.getCliente().getId().equals(clienteId)) {
            throw new RuntimeException("No tienes permiso para ver esta mascota");
        }

        return mapper.toResponseDTO(mascota);
    }

    @Override
    public MascotaResponseDTO actualizarMascotaDelCliente(String mascotaId, MascotaRequestDTO dto, String clienteId) {
        Mascota mascota = mascotaRepositoryJpa.findById(mascotaId)
                .orElseThrow(() -> new RuntimeException("Mascota no encontrada"));

        // Verificar que la mascota pertenece al cliente
        if (!mascota.getCliente().getId().equals(clienteId)) {
            throw new RuntimeException("No tienes permiso para modificar esta mascota");
        }

        Cliente cliente = clienteRepository.buscarPorId(clienteId)
                .orElseThrow(() -> new RuntimeException("Cliente no encontrado"));

        Mascota mascotaActualizada = mapper.toEntityForUpdate(dto, mascotaId, cliente);
        return mapper.toResponseDTO(mascotaRepositoryJpa.save(mascotaActualizada));
    }

    @Override
    public void eliminarMascotaDelCliente(String mascotaId, String clienteId) {
        Mascota mascota = mascotaRepositoryJpa.findById(mascotaId)
                .orElseThrow(() -> new RuntimeException("Mascota no encontrada"));

        // Verificar que la mascota pertenece al cliente
        if (!mascota.getCliente().getId().equals(clienteId)) {
            throw new RuntimeException("No tienes permiso para eliminar esta mascota");
        }

        mascotaRepositoryJpa.deleteById(mascotaId);
    }

    @Override
    public boolean mascotaPertenenceAlUsuario(String mascotaId, String userEmail) {
        try {
            // Buscar la mascota por ID
            Mascota mascota = mascotaRepositoryJpa.findById(mascotaId)
                    .orElse(null);

            // Si no existe la mascota, retornar false
            if (mascota == null) {
                return false;
            }

            // Verificar que el email del cliente de la mascota coincide con el userEmail
            return mascota.getCliente().getCorreo().equals(userEmail);

        } catch (Exception e) {
            // En caso de cualquier error, retornar false por seguridad
            return false;
        }
    }
}
