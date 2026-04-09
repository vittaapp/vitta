import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/models/domain/profesional_domain.dart';
import 'package:vitta_app/models/entities/profesional_entity.dart';
import 'package:vitta_app/models/ui/profesional_ui.dart';

void main() {
  group('ProfesionalEntity', () {
    test('fromDoc mapea tipo y datos base', () {
      final entity = ProfesionalEntity.fromDoc('u1', {
        'nombre': 'Laura',
        'email': 'laura@test.com',
        'rol': 'profesional',
        'tipo': 'auxiliarEnfermeria',
        'calificacionPromedio': 4.6,
        'cantidadResenas': 20,
      });

      expect(entity.id, 'u1');
      expect(entity.tipo, TipoProfesional.auxiliarEnfermeria);
      expect(entity.calificacionPromedio, 4.6);
      expect(entity.cantidadResenas, 20);
    });
  });

  group('ProfesionalDomain', () {
    test('regla puedeAtenderRiesgo por tipo', () {
      const cuidador = ProfesionalDomain(
        id: '1',
        nombre: 'C',
        email: 'c@test.com',
        rol: 'profesional',
        tipo: TipoProfesional.cuidadorDomiciliario,
      );
      const auxiliar = ProfesionalDomain(
        id: '2',
        nombre: 'A',
        email: 'a@test.com',
        rol: 'profesional',
        tipo: TipoProfesional.auxiliarEnfermeria,
      );
      const enfermero = ProfesionalDomain(
        id: '3',
        nombre: 'E',
        email: 'e@test.com',
        rol: 'profesional',
        tipo: TipoProfesional.enfermeroUniversitario,
      );

      expect(cuidador.puedeAtenderRiesgo('verde'), isTrue);
      expect(cuidador.puedeAtenderRiesgo('rojo'), isFalse);
      expect(auxiliar.puedeAtenderRiesgo('amarillo'), isTrue);
      expect(auxiliar.puedeAtenderRiesgo('rojo'), isFalse);
      expect(enfermero.puedeAtenderRiesgo('rojo'), isTrue);
    });

    test('estaValidado depende de identidad y disponibilidad', () {
      const d = ProfesionalDomain(
        id: '4',
        nombre: 'Val',
        email: 'v@test.com',
        rol: 'profesional',
        tipo: TipoProfesional.enfermeroUniversitario,
        identidadValidada: true,
        disponibilidadManana: true,
      );

      expect(d.estaDisponible(), isTrue);
      expect(d.estaValidado(), isTrue);
      expect(d.calificacionFormato, 'Sin calificaciones');
    });
  });

  group('ProfesionalUI', () {
    test('from(domain) traduce estado para UI', () {
      const domain = ProfesionalDomain(
        id: '5',
        nombre: 'UI',
        email: 'ui@test.com',
        rol: 'profesional',
        tipo: TipoProfesional.enfermeroUniversitario,
        identidadValidada: true,
        disponibilidadManana: true,
        calificacionPromedio: 4.7,
        cantidadResenas: 12,
      );

      final ui = ProfesionalUI.from(domain);
      expect(ui.tipo, contains('Enfermero/a'));
      expect(ui.estaValidado, isTrue);
      expect(ui.badgeCalificacion, isNotEmpty);
      expect(ui.textoEstado, anyOf('Profesional destacado', 'Muy calificado'));
    });
  });
}
