import logging
import random
import string
import json
import os
import threading
import uuid
import urllib.request
from datetime import datetime, timedelta
from urllib.parse import urlparse, parse_qs
from http.server import HTTPServer, BaseHTTPRequestHandler
from telegram import Update, InlineKeyboardMarkup, InlineKeyboardButton
from telegram.ext import Application, CommandHandler, ContextTypes, CallbackQueryHandler

# ─── CONFIGURACIÓN ────────────────────────────────────────────────────────────
BOT_TOKEN = "8681757167:AAEDE4tm3BSpgZvZyZd496OypdeEcZVvq10"
ADMIN_TELEGRAM_ID = "1210523861"  # ID del staff del restaurante

# Railway asigna el puerto dinámicamente via variable de entorno PORT
SERVER_PORT = int(os.environ.get("PORT", 8080))

# { "codigo": { "telegram_id": "...", "name": "...", "expires": datetime } }
codigos_activos = {}

# { "reserva_id": { "restaurante": ..., "fecha": ..., "hora": ..., ... , "estado": "pendiente" } }
reservas_pendientes = {}

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO
)

# ─── ENVIAR MENSAJE POR TELEGRAM (desde hilo HTTP, sin async) ─────────────────


def enviar_telegram(chat_id, texto, reply_markup=None):
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/sendMessage"
    payload = {"chat_id": chat_id, "text": texto, "parse_mode": "HTML"}
    if reply_markup:
        payload["reply_markup"] = json.dumps(reply_markup)
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url, data=data, headers={"Content-Type": "application/json"}
    )
    try:
        resp = urllib.request.urlopen(req, timeout=5)
        print(f"[TELEGRAM] Mensaje enviado OK: {resp.status}")
    except Exception as e:
        print(f"[TELEGRAM] Error enviando mensaje: {e}")

# ─── GENERAR CÓDIGO OTP ────────────────────────────────────────────────────────


def generar_codigo():
    return ''.join(random.choices(string.digits, k=6))

# ─── COMANDO /start ───────────────────────────────────────────────────────────


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    telegram_id = str(user.id)
    nombre = user.first_name or "Usuario"

    global codigos_activos
    codigos_activos = {
        k: v for k, v in codigos_activos.items()
        if v["telegram_id"] != telegram_id
    }

    codigo = generar_codigo()
    expira = datetime.now() + timedelta(minutes=10)

    codigos_activos[codigo] = {
        "telegram_id": telegram_id,
        "name": nombre,
        "expires": expira,
    }

    print(f"[LOG] Usuario: {nombre} | ID: {telegram_id} | Código: {codigo}")

    await update.message.reply_text(
        f"👋 Добро пожаловать в RestoBook, {nombre}!\n\n"
        f"🔑 Ваш код для входа:\n\n"
        f"`{codigo}`\n\n"
        f"⏱ Код действителен 10 минут.\n"
        f"Введите его в приложении RestoBook.",
        parse_mode="Markdown"
    )

# ─── CALLBACK DE BOTONES (Confirmar / Rechazar) ───────────────────────────────


async def on_callback(update: Update, context: ContextTypes.DEFAULT_TYPE):
    query = update.callback_query
    await query.answer()

    partes = query.data.split("_", 1)
    if len(partes) != 2:
        return
    accion, reserva_id = partes

    if reserva_id not in reservas_pendientes:
        await query.edit_message_text("⚠️ Reserva no encontrada o ya procesada.")
        return

    r = reservas_pendientes[reserva_id]

    if accion == "confirm":
        reservas_pendientes[reserva_id]["estado"] = "confirmada"
        texto = (
            f"✅ <b>Reserva #{reserva_id} CONFIRMADA</b>\n\n"
            f"👤 {r['nombre']}\n"
            f"🍽 {r['restaurante']}\n"
            f"📅 {r['fecha']}  |  🕐 {r['hora']} – {r['horaFin']}\n"
            f"👥 {r['personas']} гостей\n"
        )
        if r.get('comentario'):
            texto += f"💬 {r['comentario']}\n"
        texto += "\n<i>Клиент будет уведомлён в приложении.</i>"
        await query.edit_message_text(texto, parse_mode="HTML")
        print(f"[CALLBACK] ✅ Reserva {reserva_id} confirmada")

    elif accion == "reject":
        reservas_pendientes[reserva_id]["estado"] = "rechazada"
        texto = (
            f"❌ <b>Reserva #{reserva_id} RECHAZADA</b>\n\n"
            f"👤 {r['nombre']}\n"
            f"🍽 {r['restaurante']}\n"
            f"📅 {r['fecha']}  |  🕐 {r['hora']} – {r['horaFin']}\n"
        )
        await query.edit_message_text(texto, parse_mode="HTML")
        print(f"[CALLBACK] ❌ Reserva {reserva_id} rechazada")

# ─── SERVIDOR HTTP PARA FLUTTER ───────────────────────────────────────────────


class VerifyHandler(BaseHTTPRequestHandler):

    def log_message(self, format, *args):
        pass

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, GET, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type")
        self.end_headers()

    def do_GET(self):
        if self.path.startswith("/estado"):
            query = parse_qs(urlparse(self.path).query)
            reserva_id = query.get("id", [None])[0]
            if reserva_id and reserva_id in reservas_pendientes:
                estado = reservas_pendientes[reserva_id]["estado"]
                self._responder(200, json.dumps({"estado": estado}))
            else:
                self._responder(404, json.dumps({"error": "not found"}))
        else:
            self._responder(404, json.dumps({"error": "Not found"}))

    def do_POST(self):
        content_length = int(self.headers.get("Content-Length", 0))
        body = self.rfile.read(content_length)

        if self.path == "/verify":
            try:
                data = json.loads(body)
                codigo = data.get("code", "").strip()
                print(f"[VERIFY] Código recibido: {codigo}")

                if codigo in codigos_activos:
                    entrada = codigos_activos[codigo]
                    if datetime.now() < entrada["expires"]:
                        del codigos_activos[codigo]
                        print(f"[VERIFY] ✅ Código correcto para: {entrada['name']}")
                        self._responder(200, json.dumps({
                            "valid": True,
                            "name": entrada["name"],
                            "telegram_id": entrada["telegram_id"],
                        }))
                    else:
                        del codigos_activos[codigo]
                        print(f"[VERIFY] ❌ Código expirado")
                        self._responder(200, json.dumps({"valid": False, "reason": "expired"}))
                else:
                    print(f"[VERIFY] ❌ Código no encontrado")
                    self._responder(200, json.dumps({"valid": False, "reason": "invalid"}))
            except Exception as e:
                print(f"[VERIFY] Error: {e}")
                self._responder(400, json.dumps({"valid": False, "reason": "error"}))

        elif self.path == "/reserva":
            try:
                data = json.loads(body)
                reserva_id = uuid.uuid4().hex[:8]
                reservas_pendientes[reserva_id] = {
                    "restaurante": data.get("restaurante", ""),
                    "fecha":       data.get("fecha", ""),
                    "hora":        data.get("hora", ""),
                    "horaFin":     data.get("horaFin", ""),
                    "personas":    data.get("personas", 1),
                    "comentario":  data.get("comentario", ""),
                    "telefono":    data.get("telefono", ""),
                    "nombre":      data.get("nombre", ""),
                    "telegram_id": data.get("telegram_id", ""),
                    "estado":      "pendiente",
                }

                r = reservas_pendientes[reserva_id]
                texto = (
                    f"🔔 <b>Nueva reserva #{reserva_id}</b>\n\n"
                    f"👤 <b>{r['nombre']}</b>\n"
                    f"📞 <code>{r['telefono']}</code>\n"
                    f"🍽 {r['restaurante']}\n"
                    f"📅 {r['fecha']}  |  🕐 {r['hora']} – {r['horaFin']}\n"
                    f"👥 {r['personas']} гостей\n"
                )
                if r['comentario']:
                    texto += f"💬 {r['comentario']}\n"

                keyboard = {
                    "inline_keyboard": [[
                        {"text": "✅ Подтвердить", "callback_data": f"confirm_{reserva_id}"},
                        {"text": "❌ Отклонить",   "callback_data": f"reject_{reserva_id}"},
                    ]]
                }
                enviar_telegram(ADMIN_TELEGRAM_ID, texto, keyboard)
                print(f"[RESERVA] Nueva reserva {reserva_id} de {r['nombre']}")
                self._responder(200, json.dumps({"id": reserva_id}))

            except Exception as e:
                print(f"[RESERVA] Error: {e}")
                self._responder(400, json.dumps({"error": str(e)}))

        else:
            self._responder(404, json.dumps({"error": "Not found"}))

    def _responder(self, status, body):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        self.wfile.write(body.encode("utf-8"))


def iniciar_servidor():
    servidor = HTTPServer(("0.0.0.0", SERVER_PORT), VerifyHandler)
    print(f"🌐 Servidor HTTP escuchando en puerto {SERVER_PORT}...")
    servidor.serve_forever()

# ─── MAIN ─────────────────────────────────────────────────────────────────────


def main():
    print("🤖 Bot RestoBook iniciando...")

    hilo_servidor = threading.Thread(target=iniciar_servidor, daemon=True)
    hilo_servidor.start()

    app = Application.builder().token(BOT_TOKEN).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CallbackQueryHandler(on_callback))

    print("✅ Todo listo. Esperando mensajes de Telegram...")
    app.run_polling()


if __name__ == "__main__":
    main()
