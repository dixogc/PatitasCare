package com.kmd.patitas_care.domain.model.entity;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import jakarta.persistence.*;

@Entity
@Inheritance(strategy = InheritanceType.JOINED)
public abstract class Usuario {
    @Id
    private String id;
    @Column(nullable = false)
    private String nombre;
    @Column(nullable = false, unique = true)
    private String correo;
    @Column(nullable = false)
    private String passwordHash;
    @Enumerated(EnumType.STRING)
    private TipoDeUsuario tipo;

    protected Usuario() {
    }
    protected Usuario(String id, String nombre, String correo, String passwordHash, TipoDeUsuario tipo) {
        this.id = id;
        this.nombre = nombre;
        this.correo = correo;
        this.passwordHash = passwordHash;
        this.tipo = tipo;
    }

    public String getId(){ return id;}
    public String getNombre(){
        return nombre;
    }
    public String getCorreo(){
        return correo;
    }
    public String getPasswordHash(){ return passwordHash;}
    public TipoDeUsuario getTipo(){ return tipo;}

    public abstract static class UsuarioBuilder<T extends UsuarioBuilder<T>>{
        protected String id;
        protected String nombre;
        protected String correo;
        protected String passwordHash;
        protected TipoDeUsuario tipo;

        public T setId(String id){this.id = id; return self();}
        public T setNombre(String nombre){this.nombre = nombre; return self();}
        public T setCorreo(String correo){this.correo = correo; return self();}
        public T setPasswordHash(String passwordHash){this.passwordHash = passwordHash; return self();}
        public T setTipo(TipoDeUsuario tipo){this.tipo = tipo; return self();}

        protected abstract T self();
        public abstract Usuario build();
    }
}

