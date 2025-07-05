package com.kmd.patitas_care.domain.service;

import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.domain.model.entity.enums.ContextoBusqueda;
import com.kmd.patitas_care.domain.repository.VeterinariaRepository;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class VeterinariaService {
    private final VeterinariaRepository veterinariaRepository;
    private static final int RADIO_DEFAULT_KM = 5;

    public VeterinariaService(VeterinariaRepository veterinariaRepository) {
        this.veterinariaRepository = veterinariaRepository;
    }

    public List<Veterinaria> obtenerVeterinariosCercanos(double latitud, double longitud, int radio) {
        validarCoordenadas(latitud, longitud);
        validarRadio(radio);
        return veterinariaRepository.buscarVeterinariosCercanos(latitud, longitud, radio);
    }

    public List<Veterinaria> obtenerVeterinariosCercanos(double latitud, double longitud) {
        validarCoordenadas(latitud, longitud);
        return veterinariaRepository.buscarVeterinariosCercanos(latitud, longitud);
    }

    public List<Veterinaria> obtenerVeterinariosConContexto(double latitud, double longitud,
                                                            ContextoBusqueda contexto) {
        validarCoordenadas(latitud, longitud);
        return veterinariaRepository.buscarVeterinariosConContexto(latitud, longitud, contexto);
    }

    public List<Veterinaria> obtenerVeterinariosCercanosInteligente(double latitud, double longitud,
                                                                    Integer radio, String contexto) {
        validarCoordenadas(latitud, longitud);

        if (contexto != null && !contexto.isEmpty()) {
            try {
                ContextoBusqueda ctx =
                        ContextoBusqueda.valueOf(contexto.toUpperCase());
                return obtenerVeterinariosConContexto(latitud, longitud, ctx);
            } catch (IllegalArgumentException e) {
            }
        }

        if (radio != null) {
            return obtenerVeterinariosCercanos(latitud, longitud, radio);
        }

        return obtenerVeterinariosCercanos(latitud, longitud);
    }

    private void validarCoordenadas(double latitud, double longitud) {
        if (latitud < -90 || latitud > 90) {
            throw new IllegalArgumentException("Latitud inválida");
        }
        if (longitud < -180 || longitud > 180) {
            throw new IllegalArgumentException("Longitud inválida");
        }
    }

    private void validarRadio(int radio) {
        if (radio <= 0 || radio > 50) {
            throw new IllegalArgumentException("Radio debe estar entre 1 y 50 km");
        }
    }
}
