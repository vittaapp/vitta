/**
 * Cloud Functions (Firebase) — Vitta
 * FCM vía firebase-admin; triggers Firestore v2.
 *
 * firebase-admin NO se importa ni inicializa en el nivel raíz: el deploy
 * ejecuta/analiza el módulo sin credenciales de GCP y `initializeApp()` +
 * `firestore()` al cargar pueden provocar bloqueos y el error
 * "User code failed to load ... Timeout after 10000".
 */

const {setGlobalOptions} = require("firebase-functions");
const {onDocumentCreated, onDocumentUpdated} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

setGlobalOptions({maxInstances: 10});

/**
 * Carga e inicializa firebase-admin solo cuando una función se ejecuta
 * (no durante la carga del módulo en `firebase deploy`).
 * @returns {import("firebase-admin")}
 */
function getAdmin() {
  const admin = require("firebase-admin");
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin;
}

/**
 * Cola: al crear `notificaciones_pendientes/{docId}` envía FCM y marca envío o error.
 */
exports.enviarNotificacionTurno = onDocumentCreated(
  "notificaciones_pendientes/{docId}",
  async (event) => {
    const snap = event.data;
    if (!snap) {
      logger.warn("enviarNotificacionTurno: sin snapshot");
      return;
    }

    const data = snap.data();
    const token = typeof data.token === "string" ? data.token.trim() : "";
    const titulo = typeof data.titulo === "string" ? data.titulo : "";
    const cuerpo = typeof data.cuerpo === "string" ? data.cuerpo : "";
    const tipo = data.tipo != null ? String(data.tipo) : "";
    const turnoId = data.turnoId != null ? String(data.turnoId) : "";

    const ref = snap.ref;
    const admin = getAdmin();

    if (!token) {
      try {
        await ref.update({
          error: {mensaje: "Token FCM vacío o ausente."},
        });
      } catch (e) {
        logger.error("enviarNotificacionTurno: no se pudo guardar error (sin token)", e);
      }
      return;
    }

    try {
      await admin.messaging().send({
        token,
        notification: {
          title: titulo,
          body: cuerpo,
        },
        data: {
          tipo,
          turnoId,
        },
      });

      await ref.update({
        enviado: true,
        enviadoAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    } catch (err) {
      logger.error("enviarNotificacionTurno: fallo FCM o actualización", err);
      try {
        await ref.update({
          error: {mensaje: String(err.message || err)},
        });
      } catch (e2) {
        logger.error("enviarNotificacionTurno: no se pudo guardar error", e2);
      }
    }
  },
);

/**
 * Turno pasa de pendiente → aceptado: notifica al familiar.
 */
exports.onTurnoAceptado = onDocumentUpdated("turnos/{turnoId}", async (event) => {
  const change = event.data;
  if (!change) {
    return;
  }

  const before = change.before.exists ? change.before.data() : null;
  const after = change.after.exists ? change.after.data() : null;
  if (!after) {
    return;
  }

  const antes = before && before.estado;
  const despues = after.estado;
  if (antes !== "pendiente" || despues !== "aceptado") {
    return;
  }

  const turnoId = event.params.turnoId;
  const familiarId =
    typeof after.familiarId === "string" ? after.familiarId.trim() : "";

  if (!familiarId) {
    logger.warn("onTurnoAceptado: sin familiarId", {turnoId});
    return;
  }

  try {
    const admin = getAdmin();
    const userSnap = await admin.firestore().collection("usuarios").doc(familiarId).get();
    const token = (userSnap.data()?.fcmToken || "").toString().trim();
    if (!token) {
      logger.warn("onTurnoAceptado: sin fcmToken", {turnoId, familiarId});
      return;
    }

    await admin.messaging().send({
      token,
      notification: {
        title: "Turno confirmado",
        body: "Tu turno fue aceptado. El cuidador llegará pronto.",
      },
      data: {
        tipo: "turno_aceptado",
        turnoId: String(turnoId),
      },
    });
  } catch (err) {
    logger.error("onTurnoAceptado", err);
  }
});

/**
 * Check-in registrado y turno en activo: notifica al familiar.
 */
exports.onCheckinRealizado = onDocumentUpdated("turnos/{turnoId}", async (event) => {
  const change = event.data;
  if (!change) {
    return;
  }

  const before = change.before.exists ? change.before.data() : null;
  const after = change.after.exists ? change.after.data() : null;
  if (!after) {
    return;
  }

  const tieneCheckinAfter = after.checkinTime != null;
  const estadoActivo = after.estado === "activo";
  if (!estadoActivo || !tieneCheckinAfter) {
    return;
  }

  const antes = before || {};
  const transicionRelevante =
    antes.estado !== "activo" || antes.checkinTime == null;
  if (!transicionRelevante) {
    return;
  }

  const turnoId = event.params.turnoId;
  const familiarId =
    typeof after.familiarId === "string" ? after.familiarId.trim() : "";

  if (!familiarId) {
    logger.warn("onCheckinRealizado: sin familiarId", {turnoId});
    return;
  }

  try {
    const admin = getAdmin();
    const userSnap = await admin.firestore().collection("usuarios").doc(familiarId).get();
    const token = (userSnap.data()?.fcmToken || "").toString().trim();
    if (!token) {
      logger.warn("onCheckinRealizado: sin fcmToken", {turnoId, familiarId});
      return;
    }

    await admin.messaging().send({
      token,
      notification: {
        title: "El cuidador llegó",
        body: "Registró su llegada con GPS verificado.",
      },
      data: {
        tipo: "checkin",
        turnoId: String(turnoId),
      },
    });
  } catch (err) {
    logger.error("onCheckinRealizado", err);
  }
});
