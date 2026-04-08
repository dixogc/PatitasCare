# PatitasCare
Backend RESTFul diseñado para gestionar expedientes médicos de mascotas, con control de historial médico, búsquedas de ubicación en tiempo real y notificaciones.

## Stack tecnológico
* **Lenguajes:** Java
* **Framework:** Spring Boot
* **Base de Datos:** PostgreSQL(Supabase)
* **Seguridad:** JSON Web Tokens (JWT)
* **Contenedores:** Docker
* **Despliegue:** Render
* **Geoloclización:** OpenStreetMap API

## Arquitectura y Diseño
El sistema implementa una combinación de **Arquitectura Limpia (Clean Architecture)** y **Arquitectura Hexagonal (Ports & Adapters)**. 
Esta estructura permite:
* Independencia del Framework.
* Facilidad de pruebas (Testability).
* Independencia de la interfaz de usuario y la base de datos.

## Características principales
* **Autenticación JWT:** Implementación fr flujos de login/registro.
* **Gestión de recursos:** Endpoint para operaciones CRUD de mascotas y registros médicos.
* **Geolocalización:** Búsquedas de ubicación en tiempo real integradas con OpenStreetMap.
* **Manejo de errores:** Middleware para estandarización de respuestas HTTP.
* Sistema de alertas y notificaciones internas.

## Documentación de endpoints

https://patitas-care.onrender.com/swagger-ui/index.html
