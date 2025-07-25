class HistorialMedico {
  final String id;
  final String mascotaId;
  final DateTime fechaEvento;
  final String tipoEvento;
  final String? descripcion;
  final double? peso;
  final String? diagnostico;
  final String? tratamiento;
  final DateTime? fechaProximaRevision;
  final String? veterinario;

  HistorialMedico({
    required this.id,
    required this.mascotaId,
    required this.fechaEvento,
    required this.tipoEvento,
    this.descripcion,
    this.peso,
    this.diagnostico,
    this.tratamiento,
    this.fechaProximaRevision,
    this.veterinario,
  });

  factory HistorialMedico.fromJson(Map<String, dynamic> json) {
    return HistorialMedico(
      id: json['id'],
      mascotaId: json['mascotaId'],
      fechaEvento: DateTime.parse(json['fechaEvento']),
      tipoEvento: json['tipoEvento'],
      descripcion: json['descripcion'],
      peso: json['peso']?.toDouble(),
      diagnostico: json['diagnostico'],
      tratamiento: json['tratamiento'],
      fechaProximaRevision: json['fechaProximaRevision'] != null
          ? DateTime.parse(json['fechaProximaRevision'])
          : null,
      veterinario: json['veterinario'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'mascotaId': mascotaId,
      'fechaEvento': fechaEvento.toIso8601String().split('T')[0],
      'tipoEvento': tipoEvento,
      'descripcion': descripcion,
      'peso': peso,
      'diagnostico': diagnostico,
      'tratamiento': tratamiento,
      'fechaProximaRevision': fechaProximaRevision?.toIso8601String().split('T')[0],
      'veterinario': veterinario,
    };
  }
}

class HistorialMedicoRequest {
  final DateTime fechaEvento;
  final String tipoEvento;
  final String? descripcion;
  final double? peso;
  final String? diagnostico;
  final String? tratamiento;
  final DateTime? fechaProximaRevision;
  final String? veterinario;

  HistorialMedicoRequest({
    required this.fechaEvento,
    required this.tipoEvento,
    this.descripcion,
    this.peso,
    this.diagnostico,
    this.tratamiento,
    this.fechaProximaRevision,
    this.veterinario,
  });

  Map<String, dynamic> toJson() {
    return {
      'fechaEvento': fechaEvento.toIso8601String().split('T')[0],
      'tipoEvento': tipoEvento,
      'descripcion': descripcion,
      'peso': peso,
      'diagnostico': diagnostico,
      'tratamiento': tratamiento,
      'fechaProximaRevision': fechaProximaRevision?.toIso8601String().split('T')[0],
      'veterinario': veterinario,
    };
  }

  // Validaciones
  String? validateFechaEvento() {
    if (fechaEvento.isAfter(DateTime.now())) {
      return 'La fecha del evento no puede ser futura';
    }
    return null;
  }

  String? validateTipoEvento() {
    if (tipoEvento.isEmpty) {
      return 'El tipo de evento es obligatorio';
    }
    if (tipoEvento.length > 100) {
      return 'El tipo de evento no puede exceder 100 caracteres';
    }
    return null;
  }

  String? validateDescripcion() {
    if (descripcion != null && descripcion!.length > 1000) {
      return 'La descripción no puede exceder 1000 caracteres';
    }
    return null;
  }

  String? validatePeso() {
    if (peso != null) {
      if (peso! < 0.1) {
        return 'El peso debe ser mayor a 0.1 kg';
      }
      if (peso! > 200.0) {
        return 'El peso no puede exceder 200 kg';
      }
    }
    return null;
  }

  String? validateDiagnostico() {
    if (diagnostico != null && diagnostico!.length > 1000) {
      return 'El diagnóstico no puede exceder 1000 caracteres';
    }
    return null;
  }

  String? validateTratamiento() {
    if (tratamiento != null && tratamiento!.length > 1000) {
      return 'El tratamiento no puede exceder 1000 caracteres';
    }
    return null;
  }

  String? validateFechaProximaRevision() {
    if (fechaProximaRevision != null && 
        fechaProximaRevision!.isBefore(DateTime.now())) {
      return 'La fecha de próxima revisión debe ser futura';
    }
    return null;
  }

  String? validateVeterinario() {
    if (veterinario != null && veterinario!.length > 100) {
      return 'El nombre del veterinario no puede exceder 100 caracteres';
    }
    return null;
  }

  List<String> validateAll() {
    List<String> errors = [];
    
    String? error;
    error = validateFechaEvento();
    if (error != null) errors.add(error);
    
    error = validateTipoEvento();
    if (error != null) errors.add(error);
    
    error = validateDescripcion();
    if (error != null) errors.add(error);
    
    error = validatePeso();
    if (error != null) errors.add(error);
    
    error = validateDiagnostico();
    if (error != null) errors.add(error);
    
    error = validateTratamiento();
    if (error != null) errors.add(error);
    
    error = validateFechaProximaRevision();
    if (error != null) errors.add(error);
    
    error = validateVeterinario();
    if (error != null) errors.add(error);
    
    return errors;
  }
}