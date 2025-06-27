# Usar OpenJDK 17
FROM openjdk:17-jdk-slim

# Instalar Maven
RUN apt-get update && apt-get install -y maven

# Establecer directorio de trabajo
WORKDIR /app

# Copiar archivos de configuración Maven
COPY pom.xml .
COPY mvnw .
COPY .mvn .mvn

# Hacer ejecutable el Maven wrapper
RUN chmod +x mvnw

# Copiar código fuente
COPY src src

# Compilar la aplicación
RUN ./mvnw clean package -DskipTests

# Exponer puerto (usar número fijo aquí)
EXPOSE 8080

# Encontrar y ejecutar el JAR dinámicamente
CMD ["sh", "-c", "java -Dserver.port=$PORT -jar target/*.jar"]