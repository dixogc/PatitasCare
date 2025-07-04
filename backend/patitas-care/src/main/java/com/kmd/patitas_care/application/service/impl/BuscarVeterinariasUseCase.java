package com.kmd.patitas_care.application.service.impl;

import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.domain.service.VeterinariaService;
import org.springframework.stereotype.Component;
import java.util.List;

@Component
public class BuscarVeterinariasUseCase {
    private final VeterinariaService veterinariaService;

    public BuscarVeterinariasUseCase(VeterinariaService veterinariaService) {
        this.veterinariaService = veterinariaService;
    }

    public List<Veterinaria> ejecutar(double latitud, double longitud, int radio) {
        return veterinariaService.obtenerVeterinariosCercanos(latitud, longitud, radio);
    }
}
