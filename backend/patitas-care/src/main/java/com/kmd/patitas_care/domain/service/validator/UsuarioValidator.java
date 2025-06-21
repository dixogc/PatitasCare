package com.kmd.patitas_care.domain.service.validator;

import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import com.kmd.patitas_care.infraestructure.exception.BadRequestException;
import com.kmd.patitas_care.infraestructure.exception.GlobalExceptionHandler;
import com.kmd.patitas_care.infraestructure.exception.InvalidAccountTypeException;
import com.kmd.patitas_care.infraestructure.exception.InvalidPasswordException;
import org.springframework.web.bind.MethodArgumentNotValidException;

import java.util.regex.Pattern;

public class UsuarioValidator {
    private static final String EMAIL_REGEX = "^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$";
    private static final Pattern EMAIL_PATTERN = Pattern.compile(EMAIL_REGEX);

    public static void validarDatosDeRegistro(String nombre, String correo, String password){
        validarNombre(nombre);
        validarCorreo(correo);
        validarPassword(password);
    }

    public static void validarNombre(String nombre){
        if(nombre == null || nombre.trim().isEmpty()){
            throw new BadRequestException("El nombre no puede estar vacío");
        }
        if(nombre.trim().length() < 2){
            throw new BadRequestException("El nombre no puede tener menos de 2 caracteres");
        }
    }
    public static void validarPassword(String password){
        if(password == null || password.trim().isEmpty()){
            throw new BadRequestException("La contraseña no puede estar vacía");
        }
        if(password.trim().length() < 8){
            throw new InvalidPasswordException("La contraseña debe tener 8 caracteres o más");
        }
    }
    public static void validarCorreo(String correo){
        if(correo == null || correo.trim().isEmpty()){
            throw new BadRequestException("El correo no puede estar vacío");
        }
        if(!EMAIL_PATTERN.matcher(correo).matches()){
            throw new IllegalArgumentException("El formato del correo no es válido");
        }
    }
    public static void validarTipoDeUsuarioCliente(TipoDeUsuario tipoDeUsuario){
        if(tipoDeUsuario != TipoDeUsuario.CLIENTE){
            throw new InvalidAccountTypeException("Veterinario");
        }
    }
    public static void validarTipoDeUsuarioVeterinario(TipoDeUsuario tipoDeUsuario){
        if(tipoDeUsuario != TipoDeUsuario.VETERINARIO){
            throw new InvalidAccountTypeException("Cliente");
        }
    }

}
