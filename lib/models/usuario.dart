class Usuario {
  final int idUsuario;
  final String nombre;
  final String correo;
  final String rol;
  final String estado;

  Usuario({
    required this.idUsuario,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.estado,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) => Usuario(
    idUsuario: json['id_usuario'],
    nombre: json['nombre'],
    correo: json['correo'] ?? '',
    rol: json['rol'],
    estado: json['estado'] ?? 'Activo',
  );

  Map<String, dynamic> toJson() => {
    'id_usuario': idUsuario,
    'nombre': nombre,
    'correo': correo,
    'rol': rol,
    'estado': estado,
  };

  bool get esPresidente => rol == 'Presidente';
  bool get esTesorero => rol == 'Tesorero';
  bool get esOperador => rol == 'Operador';
  bool get esHabitante => rol == 'Habitante';
}
// Modelo Usuario con rol helpers: esPresidente, esTesorero, etc
