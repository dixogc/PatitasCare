package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.domain.repository.VeterinariaRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class VeterinariaService {
    private final VeterinariaRepository veterinariaRepository;

    public VeterinariaService(VeterinariaRepository veterinariaRepository) {
        this.veterinariaRepository = veterinariaRepository;
    }

    public List<Veterinaria> obtenerVeterinariosCercanos(double latitud, double longitud, int radio) {
        // Validaciones de dominio
        if (latitud < -90 || latitud > 90) {
            throw new IllegalArgumentException("Latitud inválida");
        }
        if (longitud < -180 || longitud > 180) {
            throw new IllegalArgumentException("Longitud inválida");
        }
        if (radio <= 0 || radio > 50) {
            throw new IllegalArgumentException("Radio debe estar entre 1 y 50 km");
        }

        return veterinariaRepository.buscarVeterinariosCercanos(latitud, longitud, radio);
    }
}
