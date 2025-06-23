package com.kmd.patitas_care.domain.model.entity;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.domain.repository.Autenticable;
import jakarta.persistence.Entity;
import lombok.Data;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.UserDetails;

import java.util.Collection;
import java.util.Collections;


@Entity
public class Cliente extends Usuario implements Autenticable, UserDetails {
//    @OneToMany(mappedBy = "cliente", cascade = CascadeType.ALL, orphanRemoval = true)
//    private List<Mascota> mascotas;
//    @OneToMany(mappedBy = "cliente", cascade = CascadeType.ALL, orphanRemoval = true)
//    private List<Cita> citas;
//    @OneToMany(mappedBy = "cliente", cascade = CascadeType.ALL, orphanRemoval = true)
//    private List<Notificacion> notificaciones;
//    @OneToMany(mappedBy = "cliente", cascade = CascadeType.ALL, orphanRemoval = true)
//    private List<Mensaje> mensajes;

    public Cliente(){}

    public Cliente(String id, String nombre, String correo, String passwordHash, TipoDeUsuario tipo){
//                   List<Mascota> mascotas, List<Cita> citas, List<Notificacion> notificaciones, List<Mensaje> mensajes){
        super(id, nombre, correo, passwordHash, tipo);
//        this.mascotas = mascotas != null ? new ArrayList<>(mascotas) : new ArrayList<>();
//        this.citas = citas != null ? new ArrayList<>(citas) : new ArrayList<>();
//        this.notificaciones = notificaciones != null ? new ArrayList<>(notificaciones) : new ArrayList<>();
//        this.mensajes = mensajes != null ? new ArrayList<>(mensajes) : new ArrayList<>();
    }

    @Override
    public String getUsername() {
        return this.getNombre(); // o el campo que uses como username
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


//    public List<Mascota> getMascotas(){
//        return mascotas != null ? Collections.unmodifiableList(mascotas) : Collections.emptyList();
//    }
//    public List<Cita> getCitas(){
//        return citas != null ? Collections.unmodifiableList(citas) : Collections.emptyList();
//    }
//    public List<Notificacion> getNotificaciones(){
//        return notificaciones != null ? Collections.unmodifiableList(notificaciones) : Collections.emptyList();
//    }
//    public List<Mensaje> getMensajes(){
//        return mensajes != null ? Collections.unmodifiableList(mensajes) : Collections.emptyList();
//    }

    public static class ClienteBuilder extends UsuarioBuilder<ClienteBuilder> {
//        private List<Mascota> mascotas;
//        private List<Cita> citas;
//        private List<Notificacion> notificaciones;
//        private List<Mensaje> mensajes;
//
//        public ClienteBuilder setMascotas(List<Mascota> mascotas){this.mascotas = mascotas; return this;}
//        public ClienteBuilder setCitas(List<Cita> citas){this.citas = citas; return  this;}
//        public ClienteBuilder setNotificaciones(List<Notificacion> notificaciones){this.notificaciones = notificaciones; return  this;}
//        public ClienteBuilder setMensajes(List<Mensaje> mensajes){this.mensajes = mensajes; return this;}

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
