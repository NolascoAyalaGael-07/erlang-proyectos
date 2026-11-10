# Guion para Loom y defensa en pizarron

Duracion recomendada: 5–7 minutos. La grabacion debe mostrar la aplicacion real
en ejecucion; no ocultes los cambios de pantalla ni presentes una maqueta como
si fuera el backend.

## Antes de grabar

1. En Ubuntu/WSL 2, entra al proyecto, ejecuta `rebar3 compile` y
   `rebar3 eunit`, y despues inicia `rebar3 shell`.
2. Comprueba que `/health` responde y que el puerto `8080` no pertenece a una
   instancia vieja.
3. Abre el juego, `/admin`, el panel de Stitch y el codigo en VS Code.
4. Cierra pestañas con informacion personal y no muestres cookies ni
   credenciales.

## Recorrido sugerido

### 0:00–0:35 — Presentacion y entorno

> Presento el servidor de Tres en Raya del proyecto 17. Esta implementado en
> Erlang/OTP y lo ejecuto en Ubuntu WSL 2. Primero verifico compilacion y
> pruebas; luego la aplicacion atiende en el puerto 8080.

Muestra el terminal con Erlang/OTP, `rebar3 eunit` y la shell de la aplicacion.

### 0:35–1:45 — Flujo del juego

> Desde el cliente creo una partida con dos jugadores. Cada movimiento llega
> al backend, que valida el turno y actualiza el estado de la partida.

En `/`, crea una partida con nombres de demostracion y realiza varios
movimientos. Deja una partida activa para consultar el panel.

### 1:45–3:00 — Stitch conectado al backend

> Estas vistas se diseniaron en Google Stitch y se integraron al servidor.
> El dashboard no usa los datos de muestra del prototipo: consulta las API
> reales. El detalle muestra el estado de una partida y la bitacora muestra
> eventos recibidos.

Abre el proyecto **Tres en Raya P17** en Stitch y despues `/admin`. Muestra el
detalle de la partida activa, `/admin?vista=eventos` y un movimiento que
actualice el dashboard/bitacora.

### 3:00–3:45 — Salud y metricas

> `/health` permite comprobar disponibilidad y `/metrics` agrega diagnostico
> del nodo con Recon y metricas del juego. El historial y los contadores de
> partidas viven en memoria y se reinician con el nodo.

Abre `/health` y `/metrics` en el navegador o consulta `GET /metrics` desde la
terminal.

### 3:45–5:15 — OTP, pruebas y decisiones

> La supervision raiz es `one_for_one`. Las partidas son hijos dinamicos y
> temporales: si una partida cae, el tablero en memoria no existe para
> restaurarlo, asi que se registra la caida y las otras partidas siguen
> aisladas. No anadi un proceso de dominio por jugador porque duplicaria un
> estado minimo; cada partida ya valida identidad y turno.

Muestra `src/p17_servidor_de_juego_sup.erl`, `src/p17_partidas_sup.erl`,
`src/p17_partida.erl` y la prueba de recuperacion en `test/`. Explica que el
test detiene deliberadamente una partida y comprueba el comportamiento del
supervisor/servicio.

### 5:15–6:00 — Cierre

> El proyecto conserva el juego web y las rutas existentes. La release y el
> ejemplo systemd estan preparados como artefactos, pero no instale ni habilite
> servicios del sistema. El codigo entregado incluye la integracion y las
> pruebas que acabo de mostrar.

## Puntos para el pizarron

1. Dibujar `supervisor raiz -> supervisor de partidas -> gen_statem por partida`.
2. Explicar por que el reinicio `temporary` evita presentar como recuperado un
   tablero que se perdio.
3. Trazar un movimiento: navegador -> Cowboy/HTTP -> partida -> respuesta y
   evento -> WebSocket -> dashboard.
4. Distinguir liveness (`/health`) de diagnostico (`/metrics`).
5. Aclarar que el panel no ejecuta operaciones administrativas que el backend
   no implemente.

## Preguntas que conviene poder responder

- **Por que no un proceso por jugador?** El estado actual por jugador es minimo;
  la partida ya valida ambos jugadores. La conexion WebSocket si obtiene su
  proceso Cowboy.
- **Que pasa si cae una partida?** Se notifica la caida; al ser temporal no se
  recrea un proceso con un tablero perdido. Las demas partidas quedan aisladas.
- **Que se reinicia al reiniciar el nodo?** El historial y las metricas
  volatiles; no hay persistencia del tablero.
- **Que hace Recon?** Aporta diagnostico de memoria/procesos al endpoint
  `/metrics`; no reemplaza las metricas de dominio del juego.
- **Como se evita la falsa sensacion de seguridad?** El panel no tiene
  autenticacion y debe limitarse a una red de confianza.
- **Se instalo systemd?** No. Solo se entrega una plantilla de unidad.
