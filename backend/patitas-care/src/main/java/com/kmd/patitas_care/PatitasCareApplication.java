package com.kmd.patitas_care;

import com.kmd.patitas_care.domain.model.entity.Cliente;
import com.kmd.patitas_care.domain.model.entity.Usuario;
import com.kmd.patitas_care.domain.model.entity.enums.TipoDeUsuario;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@EntityScan(basePackages = {
		"com.kmd.patitas_care.domain.model.entity"
})
@EnableJpaRepositories(basePackages = {
		"com.kmd.patitas_care.infraestructure.repository.jpa",
		"com.kmd.patitas_care.infraestructure.repository.jpa.impl"

})
@ComponentScan(basePackages = {
		"com.kmd.patitas_care"
})
public class PatitasCareApplication {

	public static void main(String[] args) {
		SpringApplication.run(PatitasCareApplication.class, args);
	}
}
