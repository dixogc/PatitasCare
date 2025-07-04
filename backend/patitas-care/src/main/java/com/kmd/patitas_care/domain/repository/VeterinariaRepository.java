package com.kmd.patitas_care.domain.repository;

import com.kmd.patitas_care.domain.model.entity.Veterinaria;
import java.util.List;

public interface VeterinariaRepository {
    List<Veterinaria> buscarVeterinariosCercanos(double latitud, double longitud, int radio);
}
