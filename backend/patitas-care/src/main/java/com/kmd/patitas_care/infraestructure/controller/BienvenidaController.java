package com.kmd.patitas_care.infraestructure.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class BienvenidaController {
    @GetMapping("/")
    public String home() {
        return "¡Back end desplegado con éxito!";
    }
}
