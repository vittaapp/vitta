import 'package:flutter_test/flutter_test.dart';
import 'package:vitta_app/utils/plan_nivel_mapper.dart';

void main() {
  group('PlanNivelMapper', () {
    test('acompañamiento retorna nivel 1', () {
      final nivel = PlanNivelMapper.obtenerNivelSegunPlan('acompañamiento');
      expect(nivel, 1);
    });

    test('salud retorna nivel 2', () {
      final nivel = PlanNivelMapper.obtenerNivelSegunPlan('salud');
      expect(nivel, 2);
    });

    test('clínico retorna nivel 3', () {
      final nivel = PlanNivelMapper.obtenerNivelSegunPlan('clínico');
      expect(nivel, 3);
    });

    test('plan desconocido retorna nivel 1 (default seguro)', () {
      final nivel = PlanNivelMapper.obtenerNivelSegunPlan('otro');
      expect(nivel, 1);
    });

    test('plan vacío retorna nivel 1 (default seguro)', () {
      final nivel = PlanNivelMapper.obtenerNivelSegunPlan('');
      expect(nivel, 1);
    });

    test('obtener descripción acompañamiento contiene N1', () {
      final desc = PlanNivelMapper.obtenerDescripcion('acompañamiento');
      expect(desc.contains('N1'), true);
    });

    test('obtener descripción salud contiene N1 y N2', () {
      final desc = PlanNivelMapper.obtenerDescripcion('salud');
      expect(desc.contains('N1'), true);
      expect(desc.contains('N2'), true);
    });

    test('obtener descripción clínico contiene N1, N2 y N3', () {
      final desc = PlanNivelMapper.obtenerDescripcion('clínico');
      expect(desc.contains('N1'), true);
      expect(desc.contains('N2'), true);
      expect(desc.contains('N3'), true);
    });

    test('validar profesional N1 en plan acompañamiento — válido', () {
      final valido = PlanNivelMapper.esProfesionalValido(1, 'acompañamiento');
      expect(valido, true);
    });

    test('rechazar profesional N3 en plan acompañamiento — inválido', () {
      final valido = PlanNivelMapper.esProfesionalValido(3, 'acompañamiento');
      expect(valido, false);
    });

    test('rechazar profesional N2 en plan acompañamiento — inválido', () {
      final valido = PlanNivelMapper.esProfesionalValido(2, 'acompañamiento');
      expect(valido, false);
    });

    test('aceptar profesional N2 en plan salud — válido', () {
      final valido = PlanNivelMapper.esProfesionalValido(2, 'salud');
      expect(valido, true);
    });

    test('aceptar profesional N1 en plan salud — válido', () {
      final valido = PlanNivelMapper.esProfesionalValido(1, 'salud');
      expect(valido, true);
    });

    test('rechazar profesional N3 en plan salud — inválido', () {
      final valido = PlanNivelMapper.esProfesionalValido(3, 'salud');
      expect(valido, false);
    });

    test('aceptar profesional N3 en plan clínico — válido', () {
      final valido = PlanNivelMapper.esProfesionalValido(3, 'clínico');
      expect(valido, true);
    });

    test('obtener etiqueta nivel 1', () {
      expect(PlanNivelMapper.obtenerEtiquetaNivel(1), 'N1 - Cuidador');
    });

    test('obtener etiqueta nivel 2', () {
      expect(PlanNivelMapper.obtenerEtiquetaNivel(2), 'N2 - Estudiante');
    });

    test('obtener etiqueta nivel 3', () {
      expect(PlanNivelMapper.obtenerEtiquetaNivel(3), 'N3 - Enfermero');
    });

    test('nivel desconocido retorna Desconocido', () {
      expect(PlanNivelMapper.obtenerEtiquetaNivel(99), 'Desconocido');
    });

    test('sin tilde (acompanamiento) equivale a con tilde', () {
      final nivel1 = PlanNivelMapper.obtenerNivelSegunPlan('acompañamiento');
      final nivel2 = PlanNivelMapper.obtenerNivelSegunPlan('acompanamiento');
      expect(nivel1, nivel2);
    });

    test('sin tilde (clinico) equivale a con tilde', () {
      final nivel1 = PlanNivelMapper.obtenerNivelSegunPlan('clínico');
      final nivel2 = PlanNivelMapper.obtenerNivelSegunPlan('clinico');
      expect(nivel1, nivel2);
    });

    test('case-insensitive para SALUD en mayúsculas', () {
      final nivel = PlanNivelMapper.obtenerNivelSegunPlan('SALUD');
      expect(nivel, 2);
    });
  });
}
