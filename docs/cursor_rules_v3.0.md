# Cursor Rules — Vitta App v3.0

## Arquitectura actual (post-refactor FASE 1–5)

### Estructura de carpetas clave

```
lib/
├── core/
│   └── navigation/
│       ├── role_router.dart       # Mapeo rol → Widget
│       └── app_navigator.dart     # Navegación centralizada
├── models/
│   ├── entities/                  # Persistencia Firestore (inmutables)
│   │   ├── paciente_entity.dart
│   │   └── profesional_entity.dart
│   ├── domain/                    # Lógica de negocio
│   │   ├── paciente_domain.dart
│   │   └── profesional_domain.dart
│   └── ui/                        # View-models para UI
│       ├── paciente_ui.dart
│       └── profesional_ui.dart
├── mappers/
│   ├── paciente_mapper.dart
│   └── profesional_mapper.dart
├── widgets/
│   ├── common/                    # Widgets genéricos reutilizables
│   │   ├── section_title_widget.dart
│   │   └── pulse_radio_icon_widget.dart
│   └── dashboard/                 # Widgets de dashboards
│       ├── access_card_widget.dart
│       ├── chip_disponibilidad_widget.dart
│       ├── dashboard_header_widget.dart
│       ├── daily_resumen_widget.dart
│       ├── emergency_button_widget.dart
│       ├── empty_requests_card_widget.dart
│       ├── my_patients_card_widget.dart
│       ├── my_profile_card_widget.dart
│       ├── onboarding_familiar_widget.dart
│       ├── professional_header_widget.dart
│       ├── professional_onboarding_widget.dart
│       ├── professional_turnos_panel_widget.dart
│       ├── professional_wallet_card_widget.dart
│       ├── recent_bitacora_widget.dart
│       ├── report_incident_button_widget.dart
│       ├── service_status_widget.dart
│       └── turno_card_widget.dart
└── views/                         # Vistas delgadas (solo layout + providers)
```

---

## Reglas de arquitectura

### 1. Navegación por roles
- **SIEMPRE** usar `RoleRouter.widgetForRole(rol)` o `AppNavigator.replaceWithRoleHome(context, rol)`
- **NUNCA** hardcodear `Navigator.push(... FamiliarDashboardView ...)` fuera de `role_router.dart`
- Roles válidos: `RolesVitta.familiar`, `RolesVitta.profesional`, `RolesVitta.enfermeroN3`, `RolesVitta.medico`, `RolesVitta.admin`

### 2. Modelos — flujo de capas
```
Firestore → PacienteEntity.fromDoc()
         → PacienteMapper.toDomain()   → PacienteDomain  (lógica de negocio)
         → PacienteMapper.toUI()       → PacienteUI      (presentación)
```
- **Entities**: solo datos + serialización (`fromDoc`, `toMap`, `copyWith`)
- **Domain**: hereda entity + métodos de negocio (no importa `material.dart`)
- **UI**: importa `material.dart`, solo getters de presentación (colores, íconos, textos)
- **Mappers**: conversiones entre capas (métodos estáticos)

### 3. Widgets modulares
- Un widget privado `_NombreWidget` que supere ~50 líneas → extraer a `lib/widgets/`
- Widgets de dashboard → `lib/widgets/dashboard/`
- Widgets genéricos (sin dependencia de un dominio) → `lib/widgets/common/`
- Nombre de archivo: `snake_case_widget.dart`, clase: `PascalCaseWidget`

### 4. Vistas (views)
- Las vistas **no deben tener clases privadas grandes** tras el refactor
- Solo contienen: `build()` con layout, llamadas a providers, y uso de widgets modulares
- Si una vista supera 300 líneas, evaluar extracción de widgets

### 5. Providers
- `pacientePrincipalProvider`: devuelve `PacienteEntity?` (no `PacienteFirestore`)
- `usuarioActualProvider`: devuelve `Usuario?` (de `usuario_model.dart`)
- No crear providers que devuelvan tipos legacy eliminados

### 6. Tests
- Tests unitarios de modelos → `test/models/`
- Tests de navegación → `test/core/navigation/`
- Tests de widgets → `test/widgets/`
- Tests de vistas → `test/views/` (a crear)
- Todo test nuevo debe pasar `flutter test` sin errores antes del commit

---

## Roles y vistas asociadas

| Rol (`RolesVitta.*`) | Vista destino |
|---|---|
| `familiar` | `FamiliarDashboardView` |
| `profesional` | `AreaProfesionalView` |
| `enfermeroN3` | `AreaProfesionalView` |
| `medico` | `MedicoDashboardView` |
| `admin` | `AdminAprobacionesView` |
| *(desconocido)* | `PanelControlView` |
