package com.kmd.patitas_care.infraestructure.dto.request.cliente;

import com.kmd.patitas_care.infraestructure.dto.response.MascotaResponseDTO;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class PerfilClienteDTO {
    private String id;
    private String nombre;
    private String correo;
    private List<MascotaResponseDTO> mascotas;
}
