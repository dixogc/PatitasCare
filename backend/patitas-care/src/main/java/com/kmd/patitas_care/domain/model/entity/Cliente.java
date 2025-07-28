package com.kmd.patitas_care.domain.model.entity;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.domain.repository.Autenticable;
import jakarta.persistence.CascadeType;
import jakarta.persistence.Entity;
import jakarta.persistence.OneToMany;
import lombok.Data;
import lombok.Getter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;
import java.util.List;


@Entity
public class Cliente extends Usuario implements Autenticable, UserDetails {

    public Cliente(){}

    public Cliente(String id, String nombre, String correo, String passwordHash, TipoDeUsuario tipo){
        super(id, nombre, correo, passwordHash, tipo);

    }

    @Override
    public String getUsername() {
        return this.getCorreo();
    }

    @Override
    public String getPassword() {
        return this.getPasswordHash();
    }

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return Collections.singletonList(new SimpleGrantedAuthority("ROLE_CLIENTE"));
    }

    @Override
    public boolean isAccountNonExpired() {
        return true;
    }

    @Override
    public boolean isAccountNonLocked() {
        return true;
    }

    @Override
    public boolean isCredentialsNonExpired() {
        return true;
    }

    @Override
    public boolean isEnabled() {
        return true;
    }

    public static class ClienteBuilder extends UsuarioBuilder<ClienteBuilder> {

        @Override
        protected ClienteBuilder self(){return this;}
        @Override
        public Cliente build(){
            if(id == null || nombre == null || correo == null || passwordHash == null){
                throw  new IllegalStateException("Faltan campos obligatorios");
            }
            return new Cliente(id, nombre, correo, passwordHash, tipo);
        }
    }
}
