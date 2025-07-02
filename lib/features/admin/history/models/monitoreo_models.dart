class MonitoreoModel {
  final int id;
  final int idColmena;
  final int idApiario;
  final String fecha;
  final List<RespuestaModel> respuestas;
  final Map<String, dynamic>? datosAdicionales;
  final bool sincronizado;
  final String? apiarioNombre;
  final int? numeroColmena;

  MonitoreoModel({
    required this.id,
    required this.idColmena,
    required this.idApiario,
    required this.fecha,
    required this.respuestas,
    this.datosAdicionales,
    this.sincronizado = false,
    this.apiarioNombre,
    this.numeroColmena,
  });

  factory MonitoreoModel.fromJson(Map<String, dynamic> json) {
    return MonitoreoModel(
      id: json['id'] as int? ?? 0,
      idColmena: json['id_colmena'] as int? ?? 0,
      idApiario: json['id_apiario'] as int? ?? 0,
      fecha: json['fecha']?.toString() ?? DateTime.now().toIso8601String(),
      respuestas:
          (json['respuestas'] as List?)
              ?.map((r) => RespuestaModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      datosAdicionales: json['datos_adicionales'] as Map<String, dynamic>?,
      sincronizado: json['sincronizado'] as bool? ?? false,
      apiarioNombre: json['apiario_nombre']?.toString(),
      numeroColmena: json['numero_colmena'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'id_colmena': idColmena,
      'id_apiario': idApiario,
      'fecha': fecha,
      'respuestas': respuestas.map((r) => r.toJson()).toList(),
      'datos_adicionales': datosAdicionales,
      'sincronizado': sincronizado,
    };
  }

  // Método para generar datos de gráficas basado en respuestas
  Map<String, dynamic> generateChartData() {
    Map<String, dynamic> chartData = {
      'produccion': <double>[],
      'salud': <double>[],
      'poblacion': <double>[],
      'fechas': <String>[],
    };

    for (var respuesta in respuestas) {
      switch (respuesta.preguntaId.toLowerCase()) {
        case 'produccion_miel':
          if (respuesta.tipoRespuesta == 'number') {
            chartData['produccion'].add(
              double.tryParse(respuesta.respuesta) ?? 0.0,
            );
          }
          break;
        case 'estado_salud':
          if (respuesta.tipoRespuesta == 'number') {
            chartData['salud'].add(double.tryParse(respuesta.respuesta) ?? 0.0);
          }
          break;
        case 'poblacion_estimada':
          if (respuesta.tipoRespuesta == 'number') {
            chartData['poblacion'].add(
              double.tryParse(respuesta.respuesta) ?? 0.0,
            );
          }
          break;
      }
    }

    chartData['fechas'].add(fecha);
    return chartData;
  }
}

class RespuestaModel {
  final int? id;
  final int? monitoreoId;
  final String preguntaId;
  final String preguntaTexto;
  final String respuesta;
  final String tipoRespuesta;

  RespuestaModel({
    this.id,
    this.monitoreoId,
    required this.preguntaId,
    required this.preguntaTexto,
    required this.respuesta,
    required this.tipoRespuesta,
  });

  factory RespuestaModel.fromJson(Map<String, dynamic> json) {
    return RespuestaModel(
      id: json['id'] as int?,
      monitoreoId: json['monitoreo_id'] as int?,
      preguntaId: json['pregunta_id']?.toString() ?? '',
      preguntaTexto: json['pregunta_texto']?.toString() ?? '',
      respuesta: json['respuesta']?.toString() ?? '',
      tipoRespuesta: json['tipo_respuesta']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'monitoreo_id': monitoreoId,
      'pregunta_id': preguntaId,
      'pregunta_texto': preguntaTexto,
      'respuesta': respuesta,
      'tipo_respuesta': tipoRespuesta,
    };
  }
}

class QuestionModel {
  final int id;
  final int apiaryId;
  final String questionText;
  final String questionType;
  final bool isRequired;
  final int displayOrder;
  final int? minValue;
  final int? maxValue;
  final List<String>? options;
  final String? dependsOn;
  final bool isActive;

  QuestionModel({
    required this.id,
    required this.apiaryId,
    required this.questionText,
    required this.questionType,
    this.isRequired = false,
    this.displayOrder = 0,
    this.minValue,
    this.maxValue,
    this.options,
    this.dependsOn,
    this.isActive = true,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as int? ?? 0,
      apiaryId: json['apiary_id'] as int? ?? 0,
      questionText: json['question_text']?.toString() ?? '',
      questionType: json['question_type']?.toString() ?? '',
      isRequired: json['is_required'] as bool? ?? false,
      displayOrder: json['display_order'] as int? ?? 0,
      minValue: json['min_value'] as int?,
      maxValue: json['max_value'] as int?,
      options: json['options'] != null
          ? List<String>.from(json['options'].map((e) => e.toString()))
          : null,
      dependsOn: json['depends_on']?.toString(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
