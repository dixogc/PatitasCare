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

    // Método para calcular distancia usando fórmula de Haversine
    public double calcularDistancia(double lat1, double lon1, double lat2, double lon2) {
        final int R = 6371; // Radio de la Tierra en kilómetros

        double latDistance = Math.toRadians(lat2 - lat1);
        double lonDistance = Math.toRadians(lon2 - lon1);

        double a = Math.sin(latDistance / 2) * Math.sin(latDistance / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(lonDistance / 2) * Math.sin(lonDistance / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

        return R * c;
    }
}
