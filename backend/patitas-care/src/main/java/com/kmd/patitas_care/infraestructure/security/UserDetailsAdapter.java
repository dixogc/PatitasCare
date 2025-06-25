package com.kmd.patitas_care.infraestructure.security;

import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;
import java.util.Collection;
import java.util.Collections;

public class UserDetailsAdapter implements UserDetails {
    private final String id;
    private final String correo;
    private final String passwordHash;
    private final Collection<? extends GrantedAuthority> authorities;

    public UserDetailsAdapter(String id, String correo, String passwordHash, Collection<? extends GrantedAuthority> authorities) {
        this.id = id;
        this.correo = correo;
        this.passwordHash = passwordHash;
        this.authorities = authorities;
    }

    public String getId() {return id;}

    @Override
    public Collection<? extends GrantedAuthority> getAuthorities() {
        return authorities;
    }

    @Override
    public String getPassword() {
        return passwordHash;
    }

    @Override
    public String getUsername() {
        return correo;
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
}
