package com.kmd.patitas_care.domain.service.validator;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.domain.repository.UsuarioRepository;

import java.util.regex.Pattern;

public class UsuarioValidator {
    private static final String EMAIL_REGEX = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";
    private static final Pattern EMAIL_PATTERN = Pattern.compile(EMAIL_REGEX);

    public static void validarDatosDeRegistro(String nombre, String correo, String password, TipoDeUsuario tipoDeUsuario){
        validarNombre(nombre);
        validarCorreo(correo);
        validarPassword(password);
        validarTipoDeUsuario(tipoDeUsuario);
    }

    public static void validarNombre(String nombre){
        if(nombre == null || nombre.trim().isEmpty()){
            throw new IllegalArgumentException("El nombre no puede estar vacío");
        }
        if(nombre.trim().length() < 2){
            throw new IllegalArgumentException("El nombre debe tener mínimo 2 caracteres");
        }
    }
    public static void validarPassword(String password){
        if(password == null || password.trim().isEmpty()){
            throw new IllegalArgumentException("La contraseña no puede estar vacía");
        }
        if(password.trim().length() < 8){
            throw new IllegalArgumentException("La contraseña debe tener mínimo 8 caracteres");
        }
    }
    public static void validarCorreo(String correo){
        if(correo == null || correo.trim().isEmpty()){
            throw new IllegalArgumentException("El correo no puede estar vacío");
        }
        if(!EMAIL_PATTERN.matcher(correo).matches()){
            throw new IllegalArgumentException("El formato del correo no es válido");
        }
    }
    public static void validarTipoDeUsuario(TipoDeUsuario tipoDeUsuario){
        if(tipoDeUsuario == null){
            throw new IllegalArgumentException("Debe seleccionar un tipo de usuario");
        }
    }

}
