package com.kmd.patitas_care.infraestructure.controller;

import com.kmd.patitas_care.application.service.impl.UsuarioServiceImpl;
import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.infraestructure.dto.request.cliente.ActualizarClienteRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.request.veterinario.ActualizarVeterinarioRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.request.veterinario.RegistroVeterinarioRequestDTO;
import com.kmd.patitas_care.infraestructure.dto.response.cliente.ClienteResponseDTO;
import com.kmd.patitas_care.infraestructure.dto.response.veterinario.VeterinarioResponseDTO;
import com.kmd.patitas_care.infraestructure.exception.ErrorResponse;
import com.kmd.patitas_care.infraestructure.mapper.VeterinarioMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/veterinario")
@Tag(name = "Veterinarios", description = "API para registro de veterinarios")
public class VeterinarioController {
    @Autowired
    private final UsuarioServiceImpl usuarioService;
    @Autowired
    private final VeterinarioMapper veterinarioMapper;

    public VeterinarioController(UsuarioServiceImpl usuarioService, VeterinarioMapper veterinarioMapper){
        this.usuarioService = usuarioService;
        this.veterinarioMapper = veterinarioMapper;
    }


    @Operation(
            summary = "Registrar nuevo veterinario",
            description = "Crea una nueva cuenta de veterinario en el sistema"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "201",
                    description = "Veterinario registrado exitosamente",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = VeterinarioResponseDTO.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "Datos de entrada inválidos o correo ya registrado",
                    content = @Content(
                            mediaType = "application/json",
                            examples = @ExampleObject(
                                    value = "{\"error\": \"El correo ya está registrado\", \"timestamp\": \"2024-12-20T10:30:00Z\"}"
                            )
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
    public ResponseEntity<VeterinarioResponseDTO> registrarVeterinario(
            @Valid @RequestBody @io.swagger.v3.oas.annotations.parameters.RequestBody(
            description = "Datos del usuario a registrar",
            required = true,
            content = @Content(
                    schema = @Schema(implementation = RegistroVeterinarioRequestDTO.class)
            )
    )RegistroVeterinarioRequestDTO dto){
        Veterinario veterinario = usuarioService.registrarVeterinario(
                dto.getNombre(), dto.getCorreo(), dto.getPassword(), dto.getTipoDeUsuario());

        VeterinarioResponseDTO response = veterinarioMapper.toResponseDTO(veterinario);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }


    @Operation(
            summary = "Buscar veterinario por ID",
            description = "Obtiene los datos de un veterinario específico por su ID"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "200",
                    description = "Veterinario encontrado",
                    content = @Content(
                            mediaType = "application/json",
                            schema = @Schema(implementation = VeterinarioResponseDTO.class)
                    )
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Veterinario no encontrado"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "ID inválido"
            )
    })

    @GetMapping("/{id}")
    public ResponseEntity<VeterinarioResponseDTO> buscarVeterinario(
            @Parameter(description = "ID único del veterinario", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
            @PathVariable String id
    ){
        Veterinario veterinario = usuarioService.buscarVeterinarioPorId(id);
        VeterinarioResponseDTO response = veterinarioMapper.toResponseDTO(veterinario);
        return ResponseEntity.ok(response);
    }

    @PutMapping("/{id}")
    @Operation(summary = "Actualizar datos del veterinario")
    @ApiResponses(value = {
            @ApiResponse(responseCode = "200", description = "Veterinario actualizado"),
            @ApiResponse(responseCode = "404", description = "Veterinario no encontrado")
    })
    public ResponseEntity<VeterinarioResponseDTO> actualizarVeterinario(
            @PathVariable String id,
            @Valid @RequestBody ActualizarVeterinarioRequestDTO dto
    ) {
        Veterinario veterinarioActualizado = usuarioService.actualizarVeterinario(id, dto);
        VeterinarioResponseDTO response = veterinarioMapper.toResponseDTO(veterinarioActualizado);
        return ResponseEntity.ok(response);
    }

    @Operation(
            summary = "Eliminar veterinario",
            description = "Elimina un veterinario del sistema por su ID"
    )
    @ApiResponses(value = {
            @ApiResponse(
                    responseCode = "204",
                    description = "Veterinario eliminado exitosamente"
            ),
            @ApiResponse(
                    responseCode = "404",
                    description = "Veterinario no encontrado"
            ),
            @ApiResponse(
                    responseCode = "400",
                    description = "ID inválido"
            )
    })
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> eliminarVeterinario(
            @Parameter(description = "ID único del veterinario a eliminar", example = "19c5a3f1-233e-428d-bb71-f3ce95b7d50e")
            @PathVariable String id
    ){
        usuarioService.eliminarVeterinario(id);
        return ResponseEntity.noContent().build();
    }
}
