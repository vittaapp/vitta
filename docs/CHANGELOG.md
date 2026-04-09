# CHANGELOG — Vitta App

## [Unreleased]

---

## [v3.0] — 2026-04-08

### Refactor end-to-end (FASE 1–5)

#### FASE 1 — Centralización de navegación por roles
- Creado `lib/core/navigation/role_router.dart`: mapeo único `rol → Widget`
- Creado `lib/core/navigation/app_navigator.dart`: navegación post-frame segura
- Soporta 5 roles: `familiar`, `profesional`, `enfermero_n3`, `medico`, `admin`
- Guard anti-rebuild en `FamiliarDashboardView`
- 5 tests unitarios en `test/core/navigation/role_router_test.dart`

#### FASE 2 — Modularización FamiliarDashboardView
- Extraídos 9 widgets privados a `lib/widgets/dashboard/` y `lib/widgets/common/`:
  `onboarding_familiar`, `dashboard_header`, `emergency_button`,
  `service_status`, `pulse_radio_icon`, `daily_resumen`,
  `recent_bitacora`, `my_patients_card`, `access_card`
- `familiar_dashboard_view.dart`: 1880 líneas → ~534 líneas

#### FASE 3 — Consolidación de modelos (arquitectura 4 capas)
- Nueva estructura `lib/models/{entities,domain,ui}` y `lib/mappers/`
- **Paciente**: `PacienteEntity` → `PacienteDomain` → `PacienteUI` + `PacienteMapper`
- **Profesional**: `ProfesionalEntity` → `ProfesionalDomain` → `ProfesionalUI` + `ProfesionalMapper`
- Eliminados: `paciente_firestore.dart`, `paciente_model.dart`, `profesional_model.dart`, `profesional_lista_item.dart`
- Fix cascada en vistas: `lista_cuidadores`, `profesional_detalle`, `seleccion_profesional`, `solicitar_turno`

#### FASE 4 — Modularización AreaProfesionalView
- Extraídos 10 widgets privados a `lib/widgets/dashboard/` y `lib/widgets/common/`:
  `professional_header`, `section_title`, `professional_wallet_card`,
  `empty_requests_card`, `chip_disponibilidad`, `report_incident_button`,
  `my_profile_card`, `professional_turnos_panel`, `turno_card`, `professional_onboarding`
- `area_profesional_view.dart`: 1186 líneas → ~180 líneas
- Fix `paciente_principal_provider`: `PacienteFirestore` → `PacienteEntity`

#### FASE 5 — Suite de tests de regresión
- 19 tests en verde (`flutter test` — All tests passed)
- Nuevos archivos:
  - `test/core/navigation/app_navigator_test.dart`
  - `test/models/paciente_test.dart`
  - `test/models/profesional_test.dart`
  - `test/widgets/dashboard_widgets_test.dart`
- Corregido `test/widget_test.dart` (plantilla obsoleta `MyApp`)

---

## [v2.0] — Commits anteriores

- `8730576` feat: centralizar navegación de roles - FASE 1
- `95c8bd7` refactor: modularizar dashboard familiar y consolidar modelos
- `dcbff65` chore: eliminar archivo duplicado admin_aprobaciones_view.dart
