package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.AuthService;
import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.service.MascotaService;
import com.kmd.patitas_care.infraestructure.dto.request.MascotaRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.MascotaResponseDTO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/mascotas")
public class MascotaController {

    @Autowired
    private final MascotaService mascotaService;
    @Autowired
    private final AuthService authService;

    public MascotaController(MascotaService mascotaService, AuthService authService) {
        this.mascotaService = mascotaService;
        this.authService = authService;
    }

    @GetMapping("/mis-mascotas")
    public ResponseEntity<List<MascotaResponseDTO>> misMascotas(HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        List<MascotaResponseDTO> mascotas = mascotaService.obtenerMascotasPorCliente(clienteId);
        return ResponseEntity.ok(mascotas);
    }

    @GetMapping("/mis-mascotas/{mascotaId}")
    public ResponseEntity<MascotaResponseDTO> miMascota(
            @PathVariable String mascotaId,
            HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        MascotaResponseDTO mascota = mascotaService.obtenerMascotaDelCliente(mascotaId, clienteId);
        return ResponseEntity.ok(mascota);
    }

    @PostMapping("/mis-mascotas")
    public ResponseEntity<MascotaResponseDTO> crearMiMascota(
            @RequestBody @Valid MascotaRequestDTO dto, HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        dto.setClienteId(clienteId);
        MascotaResponseDTO mascota = mascotaService.crearMascota(dto);
        return ResponseEntity.status(HttpStatus.CREATED).body(mascota);
    }

    @PutMapping("/mis-mascotas/{mascotaId}")
    public ResponseEntity<MascotaResponseDTO> actualizarMiMascota(
            @PathVariable String mascotaId,
            @RequestBody @Valid MascotaRequestDTO dto,
            HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        dto.setClienteId(clienteId);
        MascotaResponseDTO mascota = mascotaService.actualizarMascotaDelCliente(mascotaId, dto, clienteId);
        return ResponseEntity.ok(mascota);
    }

    @DeleteMapping("/mis-mascotas/{mascotaId}")
    public ResponseEntity<Void> eliminarMiMascota(
            @PathVariable String mascotaId,
            HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);
        mascotaService.eliminarMascotaDelCliente(mascotaId, clienteId);
        return ResponseEntity.noContent().build();
    }

}
