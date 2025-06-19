package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.UsuarioServiceImpl;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.infraestructure.dto.request.veterinario.RegistroVeterinarioRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.veterinario.VeterinarioResponseDTO;
import com.kmd.patitas_care.infraestructure.mapper.VeterinarioMapper;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/veterinario")
public class VeterinarioController {
    private final UsuarioServiceImpl usuarioService;
    private final VeterinarioMapper veterinarioMapper;

    public VeterinarioController(UsuarioServiceImpl usuarioService, VeterinarioMapper veterinarioMapper){
        this.usuarioService = usuarioService;
        this.veterinarioMapper = veterinarioMapper;
    }

    @PostMapping("/registro")
    public ResponseEntity<VeterinarioResponseDTO> registrarVeterinario(@Valid @RequestBody RegistroVeterinarioRequestDTO dto){
        try {
            Veterinario veterinario = usuarioService.registrarVeterinario((dto.getNombre()), dto.getCorreo(), dto.getPassword(), dto.getTipoDeUsuario());
            VeterinarioResponseDTO response = veterinarioMapper.toResponseDTO(veterinario);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        }catch (IllegalStateException | IllegalArgumentException e){
            return ResponseEntity.badRequest().build();        }
    }
    @GetMapping("/{id}")
    public ResponseEntity<VeterinarioResponseDTO> buscarVeterinario(@PathVariable String id){
        Veterinario veterinario = usuarioService.buscarVeterinarioPorId(id);
        VeterinarioResponseDTO response = veterinarioMapper.toResponseDTO(veterinario);
        return ResponseEntity.ok(response);
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarVeterinario(@PathVariable String id){
        usuarioService.eliminarVeterinario(id);
        return ResponseEntity.noContent().build();
    }
}
