# Diseno UIX — Servidor de Juego P17

## Evidencia Google Stitch

Las pantallas de administracion se generaron en Google Stitch dentro del
proyecto existente **Tres en Raya P17**. El proyecto conserva las pantallas
originales del juego y agrega estas tres vistas administrativas:

1. **Dashboard en tiempo real — Servidor P17**: estado del nodo y el cluster
   OTP, metricas de partidas, cola de matchmaking y alertas.
2. **Detalle de partida (OTP) — Servidor P17**: estado del proceso, jugadores,
   turno, tablero, inspeccion y acciones de operacion.
3. **Bitacora de eventos y alertas — Servidor P17**: metricas historicas,
   filtros, eventos y panel de inspeccion.

Proyecto Stitch: [Tres en Raya P17](https://stitch.withgoogle.com/projects/5621764506680375490?pli=1)

## Exportacion original

El ZIP exportado desde Stitch se descomprimio en
[`stitch_tres_en_raya_p17/`](./stitch_tres_en_raya_p17/). Los archivos
`screen.png` son capturas exportadas por Stitch y `code.html` contiene el
prototipo correspondiente a cada pantalla. El directorio `p17_tactical_grid/`
incluye el sistema de diseno exportado.

### Pantallas administrativas

- [Dashboard — captura](./stitch_tres_en_raya_p17/dashboard_en_tiempo_real_servidor_p17/screen.png)
- [Detalle OTP — captura](./stitch_tres_en_raya_p17/detalle_de_partida_otp_servidor_p17/screen.png)
- [Bitacora — captura](./stitch_tres_en_raya_p17/bit_cora_de_eventos_y_alertas_servidor_p17/screen.png)

La generacion pidio las tres vistas en espanol, con navegacion comun, colores
accesibles para estados saludable/alerta/falla, tipografia legible y diseno
responsive. Se usaron datos de demostracion en los prototipos originales.
Las exportaciones usan Tailwind CSS y Material Symbols desde CDN; se requiere
conexion a internet para conservar el estilo completo al abrir las pantallas.

## Integracion funcional

Las tres exportaciones HTML de Stitch se sirven como pantallas de la aplicacion:
el dashboard en `priv/admin.html`, el detalle en `priv/admin-detail.html` y la
bitacora en `priv/admin-events.html`. `priv/admin-stitch.js` conecta sus datos
con `/api/admin`, `/api/partidas/:id`, `/api/admin/eventos`, `/metrics`,
`/health` y `/ws/juego`; tambien implementa filtros y exportacion de eventos.
Los valores de demostracion no se muestran mientras se cargan los datos reales.
Los controles para operaciones que no existen en la API estan deshabilitados,
en vez de simular acciones de OTP o Mnesia.

## Verificacion manual

Inicia el servidor con `rebar3 shell` y abre `/admin`. Selecciona **Ver detalle**
en una partida activa para abrir su tablero en vivo; `/admin?vista=eventos`
muestra el historial y permite filtrar o descargar JSON/CSV. Realiza una jugada
desde `/` y comprueba la actualizacion en el dashboard y la bitacora.
`/health` y `/metrics` son endpoints JSON, no pantallas. Abre el enlace de Stitch
para revisar la evidencia original en el canvas.
