package com.kmd.patitas_care.infraestructure.config;

import io.github.cdimascio.dotenv.Dotenv;
import jakarta.annotation.PostConstruct;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DotEnvConfig {
    @PostConstruct
    public void loadEnvVariables() {
        try {
            Dotenv dotenv = Dotenv.configure()
                    .directory("./") // busca .env en la raíz del proyecto
                    .ignoreIfMissing() // no falla si no existe
                    .load();

            // Cargar variables al sistema
            dotenv.entries().forEach(entry -> {
                System.setProperty(entry.getKey(), entry.getValue());
            });
        } catch (Exception e) {
            // En producción (Render) no hay .env, así que ignoramos
        }
    }
}
