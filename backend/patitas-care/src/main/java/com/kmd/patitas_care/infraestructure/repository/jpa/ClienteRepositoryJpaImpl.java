package com.kmd.patitas_care.infraestructure.repository.jpa;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Veterinario;
import com.kmd.patitas_care.domain.repository.ClienteRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public class ClienteRepositoryJpaImpl implements ClienteRepository {
    private final ClienteJpaRepository jpaRepository;

    public ClienteRepositoryJpaImpl(ClienteJpaRepository jpaRepository){this.jpaRepository = jpaRepository;}

    @Override
    public void guardar(Cliente cliente){
        jpaRepository.save(cliente);
    }
    @Override
    public Optional<Cliente> buscarPorCorreo(String correo){
        return jpaRepository.findByCorreo(correo);
    }
    @Override
    public Optional<Cliente> buscarPorId(String id){
        return jpaRepository.findById(id);
    }
    @Override
    public void eliminarPorId(String id){
        jpaRepository.deleteById(id);
    }
    @Override
    public List<Cliente> obtenerTodos(){
        return jpaRepository.findAll();
    }
}
