/// Niveles de cuidado del paciente (Secc. 5 y 11 — `pacientes.nivelCuidado`).
enum NivelCuidadoPaciente {
  n1(1, 'Nivel 1'),
  n2(2, 'Nivel 2'),
  n3(3, 'Nivel 3');

  const NivelCuidadoPaciente(this.valor, this.etiqueta);

  final int valor;
  final String etiqueta;

  static NivelCuidadoPaciente desdeEntero(int v) {
    return NivelCuidadoPaciente.values.firstWhere(
      (e) => e.valor == v,
      orElse: () => NivelCuidadoPaciente.n1,
    );
  }
}
