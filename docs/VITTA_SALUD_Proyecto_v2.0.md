# Vitta App — Proyecto v2.0

## Estado del proyecto (post-refactor)

**Fecha:** Abril 2026
**Stack:** Flutter + Firebase + Riverpod
**Plataforma:** Android / iOS / Web

---

## Resumen del refactor completado

El proyecto pasó de una estructura monolítica (vistas de 1000–1900 líneas, lógica de roles dispersa, modelos duplicados) a una arquitectura modular, testeable y mantenible.

### Métricas del refactor

| Métrica | Antes | Después |
|---|---|---|
| `familiar_dashboard_view.dart` | 1880 líneas | ~534 líneas |
| `area_profesional_view.dart` | 1186 líneas | ~180 líneas |
| Widgets reutilizables en `lib/widgets/` | 0 | 19 |
| Modelos de datos | 6 archivos planos | 4 capas (entity/domain/ui/mapper) |
| Tests totales | 5 | 19 |
| Imports rotos | 0 | 0 |
| `flutter analyze` | errores | limpio |

---

## Arquitectura de capas

```
┌────────────────────────────────────────────────┐
│  Views (delgadas — solo layout + providers)    │
├────────────────────────────────────────────────┤
│  Widgets modulares (lib/widgets/)              │
│  ├── common/   → genéricos reutilizables       │
│  └── dashboard/ → específicos de dashboards   │
├────────────────────────────────────────────────┤
│  Providers (Riverpod)                          │
├────────────────────────────────────────────────┤
│  Domain models (lógica de negocio pura)        │
├────────────────────────────────────────────────┤
│  Entity models (persistencia Firestore)        │
├────────────────────────────────────────────────┤
│  Firebase / Firestore                          │
└────────────────────────────────────────────────┘
```

---

## Roadmap post-refactor

### Prioridad Alta
- [ ] Tests de integración para flujo de login por rol
- [ ] Tests de widget para `FamiliarDashboardView` con providers mockeados
- [ ] Tests de widget para `AreaProfesionalView` con providers mockeados
- [ ] CI/CD: GitHub Actions con `flutter test` en cada PR

### Prioridad Media
- [ ] `MedicoDashboardView`: modularizar siguiendo patrón FASE 4
- [ ] `AdminAprobacionesView`: implementar funcionalidad real de aprobaciones
- [ ] Mapper para `Usuario` → `UsuarioDomain` (completar arquitectura de capas)
- [ ] Error boundaries centralizados (hoy cada vista maneja sus errores)

### Prioridad Baja
- [ ] Storybook / Widgetbook para previsualizar widgets modulares
- [ ] Internacionalización (i18n) para textos hardcodeados
- [ ] Performance: `const` audit en widgets estáticos

---

## Guía rápida para nuevos devs

### Agregar un nuevo rol
1. Agregar la constante en `RolesVitta` (`lib/models/usuario_model.dart`)
2. Agregar el caso en `RoleRouter.widgetForRole()` (`lib/core/navigation/role_router.dart`)
3. Agregar test en `test/core/navigation/role_router_test.dart`

### Agregar un nuevo widget de dashboard
1. Crear en `lib/widgets/dashboard/nombre_widget.dart`
2. Clase pública: `NombreWidget extends StatelessWidget`
3. Usar en la vista correspondiente
4. Agregar test en `test/widgets/dashboard_widgets_test.dart`

### Agregar un nuevo modelo
1. Crear `entities/nombre_entity.dart` (datos + serialización)
2. Crear `domain/nombre_domain.dart` (extends entity + lógica de negocio)
3. Crear `ui/nombre_ui.dart` (view-model para presentación)
4. Crear `mappers/nombre_mapper.dart` (conversiones entre capas)
5. Agregar tests en `test/models/nombre_test.dart`

---

## Tests — estado actual

```
test/
├── core/
│   └── navigation/
│       ├── role_router_test.dart       (5 tests)
│       └── app_navigator_test.dart     (10 tests)
├── models/
│   ├── paciente_test.dart              (4 tests)
│   └── profesional_test.dart          (4 tests)
├── widgets/
│   └── dashboard_widgets_test.dart    (3 tests)
└── widget_test.dart                   (1 test smoke)

Total: 19 tests — All passed ✅
```
