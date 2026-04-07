# VITTA SALUD — Cursor Development Rules
# Versión 1.0 — Abril 2026
# Este archivo define las reglas técnicas que Cursor debe seguir en TODO momento.

---

## STACK TECNOLÓGICO — NO CAMBIAR

- **Framework:** Flutter (Dart)
- **Backend:** Firebase (Auth + Firestore + Storage)
- **Estado:** Riverpod
- **Navegación:** Go Router
- **Pagos:** MercadoPago SDK (futuro)
- **Mapas/GPS:** Google Maps Flutter (futuro)
- **Plataforma principal:** Android (Samsung Galaxy A22 — ID: R58T210VCKX)

---

## ESTRUCTURA DE CARPETAS — RESPETAR SIEMPRE

```
lib/
  main.dart
  firebase_options.dart
  models/
    usuario_model.dart
    paciente_model.dart
    turno_model.dart
    profesional_lista_item.dart
    bandeja_perfil_profesional.dart
    bitacora_evento.dart
    perfil_paciente_registro.dart
  services/
    auth_service.dart
  views/
    login_view.dart
    familiar_dashboard_view.dart
    area_profesional_view.dart          ← reemplazar por dashboard real
    medico_dashboard_view.dart          ← crear
    lista_cuidadores_view.dart
    profesional_detalle_view.dart
    checkin_view.dart                   ← mejorar con GPS real
    registro_profesional_view.dart
    perfil_paciente_familiar_view.dart
    panel_control_view.dart
    home_view.dart
  utils/
    geo_tucuman.dart
  constants/
    contacto_vitta.dart
```

---

## ROLES DE USUARIO — CRÍTICO

Hay exactamente **4 roles** en Vitta. Nunca crear otros sin consultar:

```dart
// Valores exactos del campo 'rol' en Firestore
'familiar'      // Familia que contrata cuidadores
'profesional'   // Cuidador/Enfermero que presta servicio
'medico'        // Médico afiliado o vinculado — ÚNICO que puede prescribir
'admin'         // Administrador interno de Vitta
```

### Jerarquía clínica — RESPETAR SIEMPRE

```
N1 Cuidador       → registra acciones básicas
N2 Estudiante     → registra + supervisa N1
N3 Enfermero      → registra + supervisa + valida técnica
Médico            → ÚNICO que crea/modifica indicaciones_medicas
```

**REGLA NO NEGOCIABLE:** Solo el rol `medico` puede escribir en la colección `indicaciones_medicas`. Nunca permitir que N1, N2 o N3 escriban en esa colección.

---

## MODELO DE DATOS FIRESTORE

### Colecciones principales

```
/usuarios/{uid}
  - id: string
  - nombre: string
  - email: string
  - rol: string           // 'familiar' | 'profesional' | 'medico' | 'admin'
  - fotoUrl: string
  - telefono: string?
  - pacientesIds: string[]
  - nivel: string?        // Solo profesionales: 'N1' | 'N2' | 'N3'
  - matricula: string?    // Solo N3 y médicos
  - especialidad: string?
  - createdAt: timestamp

/pacientes/{id}
  - id: string
  - nombre: string
  - edad: int
  - familiarId: string    // uid del familiar responsable
  - medicoId: string?     // uid del médico vinculado
  - patologias: string[]
  - alergias: string[]
  - grupoSanguineo: string
  - medicacionHabitual: map[]
  - nivelCuidado: string  // 'N1' | 'N2' | 'N3'
  - planActivo: string    // 'acompañamiento' | 'salud' | 'clinico'

/turnos/{id}
  - id: string
  - pacienteId: string
  - profesionalId: string
  - familiarId: string
  - fechaInicio: timestamp
  - fechaFin: timestamp
  - estado: string        // 'pendiente' | 'activo' | 'completado' | 'cancelado'
  - tipoServicio: string  // 'domicilio' | 'hospitalario'
  - nivelRequerido: string
  - monto: double
  - checkInGps: geopoint?
  - checkOutGps: geopoint?
  - checkinTime: timestamp?
  - checkoutTime: timestamp?

/registros_clinicos/{id}
  - turnoId: string
  - profesionalId: string
  - pacienteId: string
  - timestamp: timestamp  // INMUTABLE — nunca permitir update
  - signosVitales: map    // presion, pulso, temperatura, saturacion
  - medicacionAdministrada: map[]
  - observaciones: string
  - fotos: string[]

/indicaciones_medicas/{id}
  - medicoId: string      // SOLO médico puede crear/modificar
  - pacienteId: string
  - medicamento: string
  - dosis: string
  - frecuencia: string
  - viaAdministracion: string
  - fechaInicio: timestamp
  - fechaFin: timestamp?
  - activa: bool
  - firmadoDigitalmenteAt: timestamp
```

---

## PALETA DE COLORES — SIEMPRE USAR ESTOS

```dart
// Colores primarios de Vitta — NO cambiar por otros
static const Color azulVitta = Color(0xFF1A3E6F);      // Azul Cobalto — principal
static const Color tealVitta = Color(0xFF5DCAA5);      // Verde Menta — acento
static const Color fondoApp  = Color(0xFFE8EEF5);      // Fondo general
static const Color blancoCard = Color(0xFFFFFFFF);     // Cards

// Colores semánticos
static const Color rojoEmergencia = Color(0xFFB71C1C); // Botón de pánico / urgencia
static const Color fondoRojo      = Color(0xFFFFEBEE); // Fondo rojo claro
static const Color verdeConfianza = Color(0xFF2E7D32); // Semáforo verde
static const Color amberMedio     = Color(0xFFF57F17); // Semáforo amarillo
static const Color azulOscuro     = Color(0xFF0D47A1); // Variante azul existente
```

---

## TIPOGRAFÍA

```dart
// Títulos y botones principales
fontFamily: 'Montserrat', fontWeight: FontWeight.bold

// Cuerpo de texto y formularios
fontFamily: 'Poppins', fontWeight: FontWeight.normal

// Tamaño mínimo en cualquier texto de la UI: 14px
// Tamaño mínimo en botones: 16px
// Alto mínimo de botones táctiles: 56px (accesibilidad adultos mayores)
```

---

## REGLAS DE UI/UX — OBLIGATORIAS

```
1. BOTONES: mínimo 56px de alto, border radius 12-14, texto en negrita
2. UNA ACCIÓN por pantalla siempre que sea posible
3. MENSAJES DE ERROR: en español, humanos, nunca mostrar códigos técnicos
4. LOADING: siempre mostrar CircularProgressIndicator con color azulVitta
5. FORMULARIOS: validar en tiempo real, no solo al submit
6. IMÁGENES: siempre tener errorBuilder con ícono de fallback
7. SNACKBARS: behavior: SnackBarBehavior.floating siempre
8. NAVEGACIÓN post-login: usar pushAndRemoveUntil para limpiar historial
```

---

## NAVEGACIÓN POR ROL — LÓGICA CENTRAL

```dart
void navegarSegunRol(String rol, BuildContext context) {
  switch (rol) {
    case 'familiar':
      // → FamiliarDashboardView
    case 'profesional':
      // → AreaProfesionalView (cuando esté listo: ProfesionalDashboardView)
    case 'medico':
      // → MedicoDashboardView
    case 'admin':
      // → AdminAprobacionesView
  }
}
```

---

## SEGURIDAD — REGLAS ESTRICTAS

```
1. HISTORIAL CLÍNICO: NUNCA hacer update ni delete en registros_clinicos
   Solo se permite add (append). Los registros son inmutables por diseño.

2. INDICACIONES MÉDICAS: verificar rol == 'medico' ANTES de cualquier
   operación de escritura en indicaciones_medicas. Nunca confiar solo
   en las reglas de Firestore — validar también en el cliente.

3. DATOS SENSIBLES: nunca loguear con print() datos de pacientes,
   credenciales ni información de salud en producción.

4. FOTOS DE PACIENTES: nunca mostrar a profesionales no asignados.

5. GPS: solo activar tracking cuando hay un turno activo.
   Nunca trackear ubicación en background sin turno.
```

---

## SERVICIOS EXISTENTES — USAR, NO RECREAR

```dart
// Auth service ya implementado en lib/services/auth_service.dart
// Métodos disponibles:
AuthService().registrar(email, password, nombre, rol)
AuthService().login(email, password)
AuthService().loginConGoogle()
AuthService().logout()
AuthService().authStateChanges  // Stream<User?>
```

---

## MÓDULOS PENDIENTES — ORDEN DE PRIORIDAD

```
PRIORIDAD 1 — EN CURSO
  [ ] Dashboard del profesional (AreaProfesionalView → reemplazar)
  [ ] Conectar datos reales del familiar a Firestore
  [ ] Check-in/out con GPS real

PRIORIDAD 2 — PRÓXIMAS SEMANAS
  [ ] Dashboard del médico (MedicoDashboardView — nuevo)
  [ ] Rol 'medico' en usuario_model.dart
  [ ] Sistema de turnos completo
  [ ] Wallet del profesional

PRIORIDAD 3 — FASE 2
  [ ] Receta digital con QR (solo rol medico)
  [ ] Módulo de equipamiento Vitta Equipos
  [ ] Acompañamiento hospitalario
  [ ] Historia clínica con QR de emergencia

PRIORIDAD 4 — FASE 3
  [ ] Teleconsulta por video
  [ ] MercadoPago SDK integrado
  [ ] GPS en vivo durante turno
  [ ] Módulo social — padrinazgo
```

---

## COMANDOS ÚTILES

```bash
# Correr en dispositivo físico
flutter run -d R58T210VCKX

# Correr en Chrome (sin celular)
flutter run -d chrome

# Limpiar build
flutter clean && flutter pub get

# Ver dispositivos conectados
flutter devices

# Analizar código
flutter analyze
```

---

## ESTILO DE CÓDIGO — DART

```dart
// Siempre usar const donde sea posible
const SizedBox(height: 16)

// Siempre manejar errores en llamadas Firebase
try {
  // operación
} catch (e) {
  debugPrint('Error: $e');
  return null;
}

// Siempre verificar mounted antes de setState async
if (!mounted) return;
setState(() { ... });

// Nombres de archivos: snake_case
// Nombres de clases: PascalCase
// Nombres de variables: camelCase
// Constantes: _camelCase con guión bajo si son privadas
```

---

## CONTEXTO DEL NEGOCIO — PARA DECISIONES DE DISEÑO

```
App de salud domiciliaria — usuarios de 35 a 70 años
Usuario más crítico: familiar de 60 años bajo estrés
Flujo clave: contratar cuidador N3 en menos de 5 minutos
Diferencial: historia clínica digital + médico de cabecera incluido
Mercado inicial: Tucumán, Argentina
Lanzamiento: 2026
```

---

*Vitta Salud — cursor_rules.md v1.0 — Abril 2026*
*Mantener actualizado con cada nuevo módulo que se agregue*