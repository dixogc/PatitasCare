package com.kmd.patitas_care.domain.model.entity;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
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

