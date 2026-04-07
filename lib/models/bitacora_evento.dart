/// Entrada de la bitácora de cuidado (demo; en producción vendría del backup/API).
class BitacoraEvento {
  const BitacoraEvento({
    required this.hora,
    required this.descripcion,
  });

  final String hora;
  final String descripcion;
}

/// Lista de eventos mostrada en el dashboard del familiar.
const List<BitacoraEvento> kBitacoraEventosDemo = [
  BitacoraEvento(hora: '09:15', descripcion: 'Control de presión'),
  BitacoraEvento(hora: '12:30', descripcion: 'Almuerzo finalizado'),
  BitacoraEvento(hora: '14:45', descripcion: 'Siesta tranquila'),
];
