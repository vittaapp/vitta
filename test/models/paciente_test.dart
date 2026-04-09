import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/models/domain/paciente_domain.dart';
import 'package:vitta_app/models/entities/paciente_entity.dart';
import 'package:vitta_app/models/ui/paciente_ui.dart';

void main() {
  group('PacienteEntity', () {
    test('fromDoc mapea datos principales', () {
      final entity = PacienteEntity.fromDoc('p1', {
        'familiarId': 'f1',
        'nombre': 'Juan',
        'edad': 82,
        'nivelCuidado': 2,
        'planActivo': 'Plan Hogar',
      });

      expect(entity.id, 'p1');
      expect(entity.familiarId, 'f1');
      expect(entity.nombre, 'Juan');
      expect(entity.edad, 82);
      expect(entity.nivelCuidado, 2);
      expect(entity.planActivo, 'Plan Hogar');
    });

    test('toMap y copyWith conservan estructura', () {
      const base = PacienteEntity(
        id: 'p1',
        familiarId: 'f1',
        nombre: 'Juan',
        edad: 80,
      );
      final updated = base.copyWith(nombre: 'Juan Perez', nivelCuidado: 3);
      final map = updated.toMap();

      expect(map['id'], 'p1');
      expect(map['nombre'], 'Juan Perez');
      expect(map['nivelCuidado'], 3);
      expect(updated.edad, 80);
    });
  });

  group('PacienteDomain', () {
    test('reglas de negocio de seguimiento y riesgo', () {
      const domain = PacienteDomain(
        id: 'p1',
        familiarId: 'f1',
        nombre: 'Paciente',
        riesgo: NivelRiesgo.rojo,
        historia: HistoriaClinica(medicamentos: ['A'], alergias: ['B']),
      );

      expect(domain.necesitaSeguimiento(), isTrue);
      expect(domain.tieneMedicamentos(), isTrue);
      expect(domain.tieneAlergias(), isTrue);
      expect(domain.descripcionRiesgo, contains('Crítico'));
    });
  });

  group('PacienteUI', () {
    test('from(domain) traduce datos para UI', () {
      const domain = PacienteDomain(
        id: 'p2',
        familiarId: 'f2',
        nombre: 'Ana',
        edad: 70,
        localidad: 'CABA',
        provincia: 'Buenos Aires',
        riesgo: NivelRiesgo.amarillo,
        historia: HistoriaClinica(),
      );

      final ui = PacienteUI.from(domain);
      expect(ui.nombre, 'Ana');
      expect(ui.edadFormato, '70 años');
      expect(ui.ubicacion, contains('CABA'));
      expect(ui.textoRiesgo, contains('Intermedio'));
      expect(ui.colorRiesgo, Colors.orange);
    });
  });
}
