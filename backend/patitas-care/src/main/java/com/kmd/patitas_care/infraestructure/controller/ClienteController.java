package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.UsuarioServiceImpl;
import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.infraestructure.dto.request.cliente.RegistroClienteRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.cliente.ClienteResponseDTO;
import com.kmd.patitas_care.infraestructure.mapper.ClienteMapper;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/cliente")
public class ClienteController {
    private final UsuarioServiceImpl usuarioService;
    private final ClienteMapper clienteMapper;

    public ClienteController(UsuarioServiceImpl usuarioService, ClienteMapper clienteMapper){
        this.usuarioService = usuarioService;
        this.clienteMapper = clienteMapper;
    }

    @PostMapping("/registro")
    public ResponseEntity<ClienteResponseDTO> registrarCliente(@Valid @RequestBody RegistroClienteRequestDTO dto){
        try {
            Cliente cliente = usuarioService.registrarCliente(dto.getNombre(), dto.getCorreo(), dto.getPassword(), dto.getTipoDeUsuario());
            ClienteResponseDTO response = clienteMapper.toResponseDTO(cliente);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        }catch (IllegalStateException | IllegalArgumentException e){
            return ResponseEntity.badRequest().build();
        }
    }
    @GetMapping("/{id}")
    public  ResponseEntity<ClienteResponseDTO> buscarCliente(@PathVariable String id){
        Cliente cliente = usuarioService.buscarClientePorId(id);
        ClienteResponseDTO response = clienteMapper.toResponseDTO(cliente);
        return ResponseEntity.ok(response);
    }
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarCliente(@PathVariable String id){
        usuarioService.eliminarCliente(id);
        return ResponseEntity.noContent().build();
    }
}
