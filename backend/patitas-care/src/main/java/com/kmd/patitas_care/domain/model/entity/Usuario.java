package com.kmd.patitas_care.domain.model.entity;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;

public abstract class Usuario {
    private String id;
    private String nombre;
    private String correo;
    private String passwordHash;
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
    public TipoDeUsuario getTipo(){ return tipo;}

    public boolean esCorreoValido() {
        if(correo == null || correo.trim().isEmpty()) return false;
        return correo.matches("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$");
    }
    public boolean puedeSerRegistrado() {
        return nombre != null && !nombre.trim().isEmpty() && esCorreoValido();
    }

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

