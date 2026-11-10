# #17 — Servidor de juego

**Dominio:** Sistemas distribuidos

(tres en raya, trivia, ajedrez): un proceso por partida y matchmaking.

## Equipo

| Rol | Integrante |
|---|---|
| Backend (OTP) | |
| Frontend (Stitch + cowboy) | |
| Ops/QA | |

## Arranque

```bash
rebar3 compile
rebar3 eunit
rebar3 shell
```

## API y panel

- `GET /` conserva la pantalla del juego; `GET /admin` sirve el dashboard exportado de Google Stitch.
- `GET /admin?vista=detalle&id=:id` y `GET /admin?vista=eventos` sirven las pantallas Stitch de detalle y bitacora.
- `GET /api/partidas`, `POST /api/partidas`, `GET /api/partidas/:id` y `POST /api/partidas/:id/movimientos` conservan la API del juego.
- Las tres pantallas Stitch se conectan mediante `priv/admin-stitch.js`; muestran datos de las API del servidor y se actualizan por WebSocket y polling.
- `GET /api/admin` entrega partidas en juego con PID, estado, tablero, turno y duracion, jugadores en espera y promedio de duracion de partidas finalizadas.
- `GET /api/admin/eventos` devuelve los ultimos 200 eventos del nodo; el historial es en memoria y se reinicia junto con el servidor.
- `GET /metrics` devuelve esas metricas junto con memoria, uso de procesos y los cinco procesos con mayor consumo de memoria, recopilados con `recon`.
- `GET /ws/juego` transmite eventos JSON `partida_actualizada`, `partida_finalizada`, `partida_caida` y `partida_terminada`.
- `GET /health` conserva el chequeo de disponibilidad.

Las operaciones administrativas que el backend no expone (por ejemplo, pausar
una partida, ejecutar GC o terminar un proceso) aparecen deshabilitadas en la
interfaz. El detalle de partida es de solo lectura; los movimientos siguen
realizandose desde la pantalla del juego.

El promedio se calcula solo con partidas que concluyen con ganador o empate; las caidas no se cuentan como partidas completadas. Las metricas son volatiles y se reinician al reiniciar el nodo. El panel, las metricas y la API no incluyen autenticacion; deben exponerse solo en una red de confianza.

El puerto HTTP predeterminado es `8080` y se configura en `config/sys.config` (`http_port`). Las pruebas usan el puerto efimero `0` para no competir con una instancia local.

## Arquitectura OTP

- El supervisor raiz usa `one_for_one`: una falla de matchmaking, diagnostico o HTTP no reinicia las partidas ni los demas servicios.
- `p17_partidas_sup` es un supervisor dinamico `one_for_one`. Cada partida es un `gen_statem` con reinicio `temporary`: su tablero vive solo en memoria, por lo que reiniciarla como si conservara el juego seria incorrecto. Una caida termina esa partida y no afecta a sus pares.
- Los IDs de partidas son los IDs de hijos dinamicos del supervisor. Las consultas usan `supervisor:which_children/1`, asi un hijo que ya cayo no deja una entrada de ETS obsoleta.
- `p17_matchmaking` conserva la cola de espera y `p17_eventos` observa el ciclo de vida, calcula duraciones y distribuye avisos.

No se implementa un proceso de dominio adicional por jugador. En este tres en raya el estado por jugador se limita a su nombre y turno, y el `gen_statem` de partida ya valida ambos; otro `gen_server` por jugador duplicaria estado y supervision sin aislar trabajo significativo. Cada conexion WebSocket ya tiene su propio proceso Cowboy. Conviene agregar procesos de jugador cuando haya sesiones persistentes, presencia/reconexion, inventario o estado que deba sobrevivir entre partidas.

## Release y systemd

`rebar3 release` ensambla la release de produccion en `_build/default/rel/p17_servidor_de_juego`; `rebar3 tar` genera el paquete distribuible. La release usa `config/sys.config` y `config/vm.args`. Antes de desplegar, reemplaza el cookie de ejemplo en `vm.args`, confirma el nombre del nodo y limita el acceso a los endpoints de administracion.

`ops/p17-servidor-de-juego.service.example` es una plantilla, no se instala ni se habilita automaticamente. Ajusta usuario, grupo y ruta para el host; la ruta de estado debe ser escribible por el usuario del servicio.

## Material de entrega academica

La carpeta `entrega/` contiene `README.md`, el reporte de practica listo para
copiar a un Gist, el mapa de la rubrica, el guion para Loom, la lista de
capturas y la grabacion Asciinema real en `entrega/evidencias/validacion.cast`.
Las capturas originales de Stitch se conservan en
`design/stitch_tres_en_raya_p17/`.

**Demostracion Loom:** [Ver video](https://www.loom.com/share/e04a9b309dcb4c2fa35a5b2c9c3696a2)
