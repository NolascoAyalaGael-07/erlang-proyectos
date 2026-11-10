# Capturas para adjuntar en Idoceo

Guarda capturas sin recortes que oculten la URL, el estado o el contexto. Usa
datos ficticios de demostracion y evita mostrar tokens, cookies o informacion
personal.

| Evidencia guardada | Que demuestra | Criterio |
|---|---|---|
| `design/stitch_tres_en_raya_p17/*/screen.png` | Disenos originales exportados de Google Stitch. | Diseno UIX |
| `entrega/evidencias/juego-activo.png` | Cliente real con la partida #333 en curso y dos movimientos. | Solucion, demo, integracion |
| `entrega/evidencias/admin-dashboard.png` | Dashboard real con la partida #333 activa. | Demo, integracion |
| `entrega/evidencias/detalle-partida.png` | Vista Stitch conectada a la partida #333. | UIX, integracion |
| `entrega/evidencias/bitacora-eventos.png` | Eventos generados durante la partida. | UIX, integracion |
| `entrega/evidencias/juego-finalizado.png` | Partida real terminada con ganador. | Solucion, demo |
| `entrega/evidencias/health.png` y `metrics.png` | Respuestas HTTP reales del backend. | Montaje, integracion |
| `entrega/evidencias/validacion.cast` | OTP 27, rebar3 3.26.0, EUnit (9 pruebas, 0 fallos), `/health` y `/metrics`. | Erlang, calidad, entorno |

Las capturas `screen.png` dentro de `design/stitch_tres_en_raya_p17/` son
evidencia del diseno original; no sustituyen las capturas de las paginas
funcionales. Para las capturas 04–06, deja una partida activa mientras tomas
las imagenes.

## Capturas reales en el workspace

Las capturas de ejecucion se guardaron desde `http://localhost:8080/` y
`http://localhost:8080/admin`. Se uso la partida temporal #333 con nombres
ficticios; se capturo durante el juego y despues de terminarla.

## Manual de captura

1. Inicia el servidor y abre el cliente en una ventana limpia.
2. Inicia una partida con nombres ficticios.
3. Captura el cliente; abre otra pestaña para `/admin` y captura el dashboard.
4. Usa **Ver detalle** para capturar el detalle y abre la bitacora para mostrar
   los eventos correspondientes.
5. Captura `/health` y `/metrics` como respuestas del servidor.
6. Registra el resultado real de EUnit y el entorno WSL en otra captura.
