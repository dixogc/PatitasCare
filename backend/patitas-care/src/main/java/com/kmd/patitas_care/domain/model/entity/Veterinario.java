package com.kmd.patitas_care.domain.model.entity;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class Veterinario extends Usuario {
    private List<Clinica> clinicas;
    private List<Cita> citas;
    private List<Consulta> consultas;
    private List<Mensaje> mensajes;

    protected Veterinario(){}

    protected Veterinario(String id, String nombre, String correo, String passwordHash, TipoDeUsuario tipo,
                          List<Clinica> clinicas, List<Cita> citas, List<Consulta> consultas, List<Mensaje> mensajes){
        super(id, nombre, correo, passwordHash, tipo);
        this.clinicas = clinicas != null ? new ArrayList<>(clinicas) : new ArrayList<>();
        this.citas = citas != null ? new ArrayList<>(citas) : new ArrayList<>();
        this.consultas = consultas != null ? new ArrayList<>(consultas) : new ArrayList<>();
        this.mensajes = mensajes != null ? new ArrayList<>(mensajes) : new ArrayList<>();
    }

    public List<Clinica> getClinicas(){
        return clinicas != null ? Collections.unmodifiableList(clinicas) : Collections.emptyList();
    }
    public List<Cita> getCitas(){
        return citas != null ? Collections.unmodifiableList(citas) : Collections.emptyList();
    }
    public List<Consulta> getConsultas(){
        return consultas != null ? Collections.unmodifiableList(consultas) : Collections.emptyList();
    }
    public List<Mensaje> getMensajes(){
        return mensajes != null ? Collections.unmodifiableList(mensajes) : Collections.emptyList();
    }

    public static class VeterinarioBuilder extends UsuarioBuilder<VeterinarioBuilder> {
        private List<Clinica> clinicas;
        private List<Cita> citas;
        private List<Consulta> consultas;
        private List<Mensaje> mensajes;

        public VeterinarioBuilder setClinicas(List<Clinica> clinicas){this.clinicas = clinicas; return this;}
        public VeterinarioBuilder setCitas(List<Cita> citas){this.citas = citas; return this;}
        public VeterinarioBuilder setConsultas(List<Consulta> consultas){this.consultas = consultas; return this;}
        public VeterinarioBuilder setMensajes(List<Mensaje> mensajes){this.mensajes = mensajes; return this;}

        @Override
        protected VeterinarioBuilder self() {return this;}
        @Override
        public Veterinario build(){
            if(id == null || nombre == null || correo == null || passwordHash == null){
                throw  new IllegalStateException("Faltan campos obligatorios");
            }
            return new Veterinario(id, nombre, correo, passwordHash, tipo, clinicas, citas, consultas, mensajes);
        }
    }
}
