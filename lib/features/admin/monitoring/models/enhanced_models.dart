import 'package:uuid/uuid.dart';

class Opcion {
  String valor;
  String? descripcion;
  int? orden;

  Opcion({required this.valor, this.descripcion, this.orden});

  Map<String, dynamic> toJson() {
    return {'valor': valor, 'descripcion': descripcion, 'orden': orden};
  }

  factory Opcion.fromJson(Map<String, dynamic> json) {
    return Opcion(
      valor: json['valor']?.toString() ?? json['value']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? json['description']?.toString(),
      orden: json['orden'] as int? ?? json['order'] as int?,
    );
  }

  Opcion copyWith({String? valor, String? descripcion, int? orden}) {
    return Opcion(
      valor: valor ?? this.valor,
      descripcion: descripcion ?? this.descripcion,
      orden: orden ?? this.orden,
    );
  }
}

class Pregunta {
  int id;
  String texto;
  bool seleccionada;
  List<Opcion>? opciones;
  String? tipoRespuesta;
  String? respuestaSeleccionada;
  bool obligatoria;
  int? min;
  int? max;
  String? dependeDe;
  int orden;
  bool activa;
  int? apiarioId;
  String? categoria;
  DateTime? fechaCreacion;
  DateTime? fechaActualizacion;

  // Clave única para Flutter (para ReorderableListView)
  final String _flutterKey;

  Pregunta({
    required this.id,
    required this.texto,
    required this.seleccionada,
    this.tipoRespuesta = "texto",
    this.opciones,
    this.respuestaSeleccionada,
    this.obligatoria = false,
    this.min,
    this.max,
    this.dependeDe,
    this.orden = 0,
    this.activa = true,
    this.apiarioId,
    this.categoria,
    this.fechaCreacion,
    this.fechaActualizacion,
  }) : _flutterKey = (id is int) ? id.toString() : const Uuid().v4();

  // Getter para la clave que usará ValueKey
  String get flutterKey => _flutterKey;

  factory Pregunta.fromJson(Map<String, dynamic> json) {
    final optionsList = json['opciones'] ?? json['options'];
    return Pregunta(
      id: json['id'] is String
          ? int.tryParse(json['id'].toString()) ?? 0
          : json['id'] as int? ?? json['question_id'] as int? ?? 0,
      texto: json['pregunta']?.toString() ?? json['question_text']?.toString() ?? json['texto']?.toString() ?? '',
      seleccionada: json['seleccionada'] as bool? ?? false,
      tipoRespuesta: json['tipo']?.toString() ??
          json['question_type']?.toString() ??
          json['tipoRespuesta']?.toString() ??
          'texto',
      obligatoria: json['obligatoria'] as bool? ?? json['is_required'] as bool? ?? false,
      opciones: optionsList is List
          ? optionsList.map((o) {
              if (o is String) return Opcion(valor: o);
              if (o is Map<String, dynamic>) return Opcion.fromJson(o);
              return Opcion(valor: o.toString());
            }).toList()
          : null,
      min: json['min'] as int? ?? json['min_value'] as int?,
      max: json['max'] as int? ?? json['max_value'] as int?,
      dependeDe: json['depende_de']?.toString() ?? json['depends_on']?.toString() ?? json['dependeDe']?.toString(),
      orden: json['orden'] as int? ?? json['display_order'] as int? ?? 0,
      activa: json['activa'] as bool? ?? json['is_active'] as bool? ?? true,
      apiarioId: json['apiario_id'] as int? ?? json['apiary_id'] as int?,
      categoria: json['category']?.toString() ?? json['categoria']?.toString(),
      fechaCreacion: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      fechaActualizacion: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question_text': texto,
      'question_type': tipoRespuesta,
      'is_required': obligatoria,
      'options': opciones?.map((o) => o.valor).toList(),
      'min_value': min,
      'max_value': max,
      'depends_on': dependeDe,
      'seleccionada': seleccionada,
      'display_order': orden,
      'is_active': activa,
      'apiary_id': apiarioId,
      'category': categoria,
    };
  }

  Pregunta copyWith({
    int? id,
    String? texto,
    bool? seleccionada,
    List<Opcion>? opciones,
    String? tipoRespuesta,
    String? respuestaSeleccionada,
    bool? obligatoria,
    int? min,
    int? max,
    String? dependeDe,
    int? orden,
    bool? activa,
    int? apiarioId,
    String? categoria,
  }) {
    return Pregunta(
      id: id ?? this.id,
      texto: texto ?? this.texto,
      seleccionada: seleccionada ?? this.seleccionada,
      opciones: opciones ?? this.opciones,
      tipoRespuesta: tipoRespuesta ?? this.tipoRespuesta,
      respuestaSeleccionada:
          respuestaSeleccionada ?? this.respuestaSeleccionada,
      obligatoria: obligatoria ?? this.obligatoria,
      min: min ?? this.min,
      max: max ?? this.max,
      dependeDe: dependeDe ?? this.dependeDe,
      orden: orden ?? this.orden,
      activa: activa ?? this.activa,
      apiarioId: apiarioId ?? this.apiarioId,
      categoria: categoria ?? this.categoria,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: DateTime.now(),
    );
  }
}

class Apiario {
  final int id;
  final String nombre;
  final String ubicacion;
  final int? userId;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;
  final List<Colmena>? colmenas;
  final List<Pregunta>? preguntas;
  final Map<String, dynamic>? metadatos;

  Apiario({
    required this.id,
    required this.nombre,
    required this.ubicacion,
    this.userId,
    this.fechaCreacion,
    this.fechaActualizacion,
    this.colmenas,
    this.preguntas,
    this.metadatos,
  });

  factory Apiario.fromJson(Map<String, dynamic> json) {
    return Apiario(
      id: json['id'] ?? 0,
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
      ubicacion: json['ubicacion']?.toString() ?? json['location']?.toString() ?? '',
      userId: json['user_id'] as int?,
      fechaCreacion: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      fechaActualizacion: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
      colmenas: json['colmenas'] != null
          ? (json['colmenas'] as List).map((c) => Colmena.fromJson(c)).toList()
          : null,
      preguntas: json['preguntas'] != null
          ? (json['preguntas'] as List)
              .map((p) => Pregunta.fromJson(p))
              .toList()
          : null,
      metadatos: json['metadatos'] as Map<String, dynamic>? ?? json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': nombre,
      'location': ubicacion,
      'user_id': userId,
      'metadata': metadatos,
    };
  }

  Apiario copyWith({
    int? id,
    String? nombre,
    String? ubicacion,
    int? userId,
    List<Colmena>? colmenas,
    List<Pregunta>? preguntas,
    Map<String, dynamic>? metadatos,
  }) {
    return Apiario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      ubicacion: ubicacion ?? this.ubicacion,
      userId: userId ?? this.userId,
      fechaCreacion: fechaCreacion,
      fechaActualizacion: DateTime.now(),
      colmenas: colmenas ?? this.colmenas,
      preguntas: preguntas ?? this.preguntas,
      metadatos: metadatos ?? this.metadatos,
    );
  }
}

class Colmena {
  final int id;
  final int numeroColmena;
  final int idApiario;
  final Map<String, dynamic>? metadatos;
  final DateTime? fechaCreacion;
  final bool activa;

  Colmena({
    required this.id,
    required this.numeroColmena,
    required this.idApiario,
    this.metadatos,
    this.fechaCreacion,
    this.activa = true,
  });

  factory Colmena.fromJson(Map<String, dynamic> json) {
    return Colmena(
      id: json['id'] as int? ?? 0,
      numeroColmena: json['numero_colmena'] as int? ?? json['hive_number'] as int? ?? 0,
      idApiario: json['id_apiario'] as int? ?? json['apiary_id'] as int? ?? 0,
      metadatos: json['metadatos'] as Map<String, dynamic>? ?? json['metadata'] as Map<String, dynamic>?,
      fechaCreacion: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      activa: json['activa'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hive_number': numeroColmena,
      'apiary_id': idApiario,
      'metadata': metadatos,
      'activa': activa,
    };
  }
}

class NotificacionReina {
  final int id;
  final int apiarioId;
  final int? colmenaId;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String prioridad;
  final bool leida;
  final DateTime fechaCreacion;
  final DateTime? fechaVencimiento;
  final Map<String, dynamic>? metadatos;

  NotificacionReina({
    required this.id,
    required this.apiarioId,
    this.colmenaId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.prioridad = 'media',
    this.leida = false,
    required this.fechaCreacion,
    this.fechaVencimiento,
    this.metadatos,
  });

  factory NotificacionReina.fromJson(Map<String, dynamic> json) {
    return NotificacionReina(
      id: json['id'] as int? ?? 0,
      apiarioId: json['apiario_id'] as int? ?? json['apiary_id'] as int? ?? 0,
      colmenaId: json['colmena_id'] as int? ?? json['hive_id'] as int?,
      tipo: json['tipo']?.toString() ?? json['type']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? json['title']?.toString() ?? '',
      mensaje: json['mensaje']?.toString() ?? json['message']?.toString() ?? '',
      prioridad: json['prioridad']?.toString() ?? json['priority']?.toString() ?? 'media',
      leida: json['leida'] as bool? ?? json['read'] as bool? ?? false,
      fechaCreacion: DateTime.parse(
        json['fecha_creacion']?.toString() ??
            json['created_at']?.toString() ??
            DateTime.now().toIso8601String(),
      ),
      fechaVencimiento: json['fecha_vencimiento'] != null ||
              json['expires_at'] != null
          ? DateTime.tryParse(
              json['fecha_vencimiento']?.toString() ?? json['expires_at']?.toString() ?? '')
          : null,
      metadatos: json['metadatos'] as Map<String, dynamic>? ?? json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'apiario_id': apiarioId,
      'colmena_id': colmenaId,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'prioridad': prioridad,
      'leida': leida,
      'fecha_creacion': fechaCreacion.toIso8601String(),
      'fecha_vencimiento': fechaVencimiento?.toIso8601String(),
      'metadatos': metadatos,
    };
  }
}

class Usuario {
  final int id;
  final String nombre;
  final String username;
  final String email;
  final String phone;
  final String? profilePicture;
  final DateTime? fechaCreacion;

  Usuario({
    required this.id,
    required this.nombre,
    required this.username,
    required this.email,
    required this.phone,
    this.profilePicture,
    this.fechaCreacion,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre']?.toString() ?? json['name']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      profilePicture: json['profile_picture']?.toString() ?? json['profile_picture_url']?.toString(),
      fechaCreacion: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'username': username,
      'email': email,
      'phone': phone,
      'profile_picture': profilePicture,
    };
  }
}

class MonitoreoRespuesta {
  final String preguntaId;
  final String preguntaTexto;
  final dynamic respuesta;
  final String? tipoRespuesta;
  final DateTime? fechaRespuesta;

  MonitoreoRespuesta({
    required this.preguntaId,
    required this.preguntaTexto,
    required this.respuesta,
    this.tipoRespuesta,
    this.fechaRespuesta,
  });

  Map<String, dynamic> toJson() {
    return {
      'pregunta_id': preguntaId,
      'pregunta_texto': preguntaTexto,
      'respuesta': respuesta,
      'tipo_respuesta': tipoRespuesta,
      'fecha_respuesta': fechaRespuesta?.toIso8601String(),
    };
  }

  factory MonitoreoRespuesta.fromJson(Map<String, dynamic> json) {
    return MonitoreoRespuesta(
      preguntaId: json['pregunta_id']?.toString() ?? '',
      preguntaTexto: json['pregunta_texto']?.toString() ?? '',
      respuesta: json['respuesta'],
      tipoRespuesta: json['tipo_respuesta']?.toString(),
      fechaRespuesta: json['fecha_respuesta'] != null
          ? DateTime.tryParse(json['fecha_respuesta'].toString())
          : null,
    );
  }
}

class PreguntaTemplate {
  final String id;
  final String categoria;
  final String texto;
  final String tipoRespuesta;
  final bool obligatoria;
  final List<String>? opciones;
  final int? min;
  final int? max;

  PreguntaTemplate({
    required this.id,
    required this.categoria,
    required this.texto,
    required this.tipoRespuesta,
    required this.obligatoria,
    this.opciones,
    this.min,
    this.max,
  });

  factory PreguntaTemplate.fromJson(Map<String, dynamic> json) {
    final optionsList = json['options'] ?? json['opciones'];
    return PreguntaTemplate(
      id: json['id']?.toString() ?? '',
      categoria: json['category']?.toString() ?? json['categoria']?.toString() ?? '',
      texto: json['question_text']?.toString() ?? json['pregunta']?.toString() ?? '',
      tipoRespuesta: json['question_type']?.toString() ?? json['tipo']?.toString() ?? 'texto',
      obligatoria: json['is_required'] as bool? ?? json['obligatoria'] as bool? ?? false,
      opciones: optionsList is List
          ? optionsList.map((e) => e.toString()).toList()
          : null,
      min: json['min_value'] as int? ?? json['min'] as int?,
      max: json['max_value'] as int? ?? json['max'] as int?,
    );
  }
}


