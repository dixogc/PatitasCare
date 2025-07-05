package com.kmd.patitas_care.domain.repository;

import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import com.kmd.patitas_care.domain.model.entity.enums.ContextoBusqueda;

import java.util.List;

public interface VeterinariaRepository {
    List<Veterinaria> buscarVeterinariosCercanos(double latitud, double longitud, int radio);

    List<Veterinaria> buscarVeterinariosCercanos(double latitud, double longitud);

    List<Veterinaria> buscarVeterinariosConContexto(double latitud, double longitud, ContextoBusqueda contexto);
}
