package com.kmd.patitas_care.infraestructure.repository.jpa.impl;

import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.repository.VeterinarioRepository;
import com.kmd.patitas_care.infraestructure.repository.jpa.VeterinarioJpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class VeterinarioRepositoryJpaImpl implements VeterinarioRepository {
    private final VeterinarioJpaRepository jpaRepository;

    public VeterinarioRepositoryJpaImpl(VeterinarioJpaRepository jpaRepository){
        this.jpaRepository = jpaRepository;
    }

    @Override
    public void guardar(Veterinario veterinario){
        jpaRepository.save(veterinario);
    }
    @Override
    public Optional<Veterinario> buscarPorCorreo(String correo){
        return jpaRepository.findByCorreo(correo);
    }
    @Override
    public Optional<Veterinario> buscarPorId(String id){
        return jpaRepository.findById(id);
    }
    @Override
    public void eliminarPorId(String id){
        jpaRepository.deleteById(id);
    }
    @Override
    public List<Veterinario> obtenerTodos(){
        return jpaRepository.findAll();
    }
}
