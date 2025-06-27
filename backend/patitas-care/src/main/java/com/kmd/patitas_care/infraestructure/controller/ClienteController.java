package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.AuthService;
import com.kmd.patitas_care.application.service.impl.MascotaServiceImpl;
import com.kmd.patitas_care.application.service.impl.UsuarioServiceImpl;
import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.service.MascotaService;
import com.kmd.patitas_care.infraestructure.dto.request.cliente.ActualizarClienteRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.request.cliente.PerfilClienteDTO;
import com.kmd.patitas_care.infraestructure.dto.request.cliente.RegistroClienteRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.MascotaResponseDTO;
import com.kmd.patitas_care.infraestructure.dto.response.cliente.ClienteResponseDTO;
import com.kmd.patitas_care.infraestructure.exception.ErrorResponse;
import com.kmd.patitas_care.infraestructure.mapper.ClienteMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/cliente")
@Tag(name = "Clientes", description = "API para registro de clientes")
public class ClienteController {
    @Autowired
    private final UsuarioServiceImpl usuarioService;
    @Autowired
    private final ClienteMapper clienteMapper;
    @Autowired
    private final MascotaServiceImpl mascotaService;
    @Autowired
    private final AuthService authService;

    public ClienteController(UsuarioServiceImpl usuarioService, ClienteMapper clienteMapper,
                             MascotaServiceImpl mascotaService, AuthService authService){
        this.usuarioService = usuarioService;
        this.clienteMapper = clienteMapper;
        this.mascotaService = mascotaService;
        this.authService = authService;
    }


    @Operation(summary = "Registrar nuevo Cliente",
            description = "Crear una nueva cuenta de cliente en el sistema")

    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "201",
                    description = "Cliente registrado exitosamente",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ClienteResponseDTO.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Datos de entrada inválidos",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ErrorResponse.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Datos de entrada inválidos o correo ya registrado",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ErrorResponse.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "500",
                    description = "Error interno del servidor",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ErrorResponse.class)
                    )
            )
    })

    @PostMapping("/registro")
    public ResponseEntity<ClienteResponseDTO> registrarCliente(
            @Valid @RequestBody @io.swagger.v3.oas.annotations.parameters.RequestBody(
                    description = "Datos del usuario a registrar",
                    required = true,
                    content = @Content(
                            schema = @Schema(implementation = RegistroClienteRequestDTO.class)
                    )
            )RegistroClienteRequestDTO dto
    ){
        Cliente veterinario = usuarioService.registrarCliente(
                dto.getNombre(), dto.getCorreo(), dto.getPassword(), dto.getTipoDeUsuario());

        ClienteResponseDTO response = clienteMapper.toResponseDTO(veterinario);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    @Operation(
            summary = "Buscar cliente por ID",
            description = "Obtiene los datos de un cliente específico por su ID"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Cliente encontrado",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = ClienteResponseDTO.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Cliente no encontrado"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "ID inválido"
            )
    })

    @GetMapping("/{id}")
    public  ResponseEntity<ClienteResponseDTO> buscarCliente(
            @Parameter(description = "ID único del veterinario", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
            @PathVariable String id
    ){
        Cliente cliente = usuarioService.buscarClientePorId(id);
        ClienteResponseDTO response = clienteMapper.toResponseDTO(cliente);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Actualizar datos del cliente")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Cliente actualizado"),
            @ApiResponse(responseCode = "404", description = "Cliente no encontrado")
    })
    public ResponseEntity<ClienteResponseDTO> actualizarCliente(
            @PathVariable String id,
            @Valid @RequestBody ActualizarClienteRequestDTO dto
    ) {
        Cliente clienteActualizado = usuarioService.actualizarCliente(id, dto);
        ClienteResponseDTO response = clienteMapper.toResponseDTO(clienteActualizado);
        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "Eliminar cliente",
            description = "Elimina un cliente del sistema por su ID"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "204",
                    description = "Cliente eliminado exitosamente"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Cliente no encontrado"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "ID inválido"
            )
    })

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarCliente(
            @Parameter(description = "ID único del veterinario a eliminar", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
            @PathVariable String id
    ){
        usuarioService.eliminarCliente(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/perfil")
    public ResponseEntity<PerfilClienteDTO> obtenerPerfil(HttpServletRequest request) {
        String clienteId = authService.obtenerClienteDesdeToken(request);

        Cliente cliente = usuarioService.buscarClientePorId(clienteId);
        List<MascotaResponseDTO> mascotas = mascotaService.obtenerMascotasPorCliente(clienteId);

        PerfilClienteDTO perfil = new PerfilClienteDTO(
                cliente.getId(),
                cliente.getNombre(),
                cliente.getCorreo(),
                mascotas
        );

        return ResponseEntity.ok(perfil);
    }

}
