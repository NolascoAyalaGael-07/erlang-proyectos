# Manual de uso — Tres en Raya P17

## Proposito

Servidor de Tres en Raya implementado en Erlang/OTP. Cada partida se ejecuta
como un proceso independiente; el cliente web permite crear partidas y realizar
movimientos. El panel administrativo Stitch muestra el estado del servidor y
se alimenta con datos reales del backend.

## Requisitos

- Erlang/OTP y rebar3 instalados.
- En la validacion de esta entrega: Ubuntu en WSL 2, Erlang/OTP 27 y rebar3
  3.26.0.
- Navegador web. Se necesita Internet para cargar los estilos e iconos externos
  usados por las pantallas exportadas de Stitch.

## Instalacion y arranque local

Abre Ubuntu/WSL y cambia al directorio raiz del proyecto. Sustituye `USUARIO`
por el usuario de Windows que contiene la carpeta del proyecto:

```bash
cd /mnt/c/Users/USUARIO/Downloads/17-servidor-de-juego
rebar3 compile
rebar3 eunit
rebar3 shell
```

La aplicacion escucha por defecto en el puerto `8080`, configurable como
`http_port` en `config/sys.config`. Si el puerto ya esta ocupado, verifica que
no haya otra instancia ejecutandose antes de iniciar una segunda.

## Uso del juego

1. Abre `http://localhost:8080/`.
2. Escribe dos nombres distintos y selecciona **Crear partida**.
3. Alterna los turnos usando las casillas vacias del tablero.
4. El servidor valida el jugador y la posicion. La partida termina al formar
   una linea o cuando el tablero queda lleno.

## Uso del panel administrativo

- `http://localhost:8080/admin`: dashboard con partidas, cola de espera,
  duracion promedio, salud y eventos.
- `http://localhost:8080/admin?vista=detalle&id=ID`: detalle de una partida
  activa. Reemplaza `ID` por el identificador que muestra el dashboard.
- `http://localhost:8080/admin?vista=eventos`: bitacora, filtros y exportacion
  de eventos.
- Las pantallas se actualizan por WebSocket y polling de respaldo.
- Las acciones sin endpoint real estan deshabilitadas; los movimientos se
  realizan desde la pantalla del juego.

## Diagnostico y API

- `GET /health`: disponibilidad del servicio.
- `GET /metrics`: metricas del nodo Erlang y del juego.
- `GET /api/admin`: partidas activas, jugadores en espera y duracion promedio.
- `GET /api/admin/eventos`: eventos recientes del nodo.
- `GET /ws/juego`: eventos de actualizacion y caida de partidas.
- `GET /api/partidas`: partidas activas.
- `POST /api/partidas?jugador1=Ana&jugador2=Luis`: crea una partida.
- `GET /api/partidas/ID`: consulta su estado.
- `POST /api/partidas/ID/movimientos?jugador=Ana&posicion=1`: envia un
  movimiento; la posicion debe ser valida y le toca al jugador indicado.

El historial de eventos y las metricas del juego son volatiles: se reinician al
reiniciar el nodo. El promedio solo considera partidas terminadas con ganador
o empate; las caidas no cuentan como partidas completadas.

## Arquitectura resumida

- El supervisor raiz usa `one_for_one`.
- `p17_partidas_sup` administra partidas dinamicas. Cada partida es un
  `gen_statem` y tiene reinicio `temporary`: al perder el proceso tambien se
  pierde el tablero en memoria, por lo que reiniciarlo como si conservara el
  estado seria engañoso.
- No existe un proceso de dominio separado por jugador porque el estado de
  jugador es minimo y ya lo valida el proceso de partida.
- Las conexiones WebSocket tienen su propio proceso Cowboy.

## Solucion de problemas

- **El puerto 8080 esta ocupado:** verifica procesos existentes; no inicies una
  instancia duplicada. Cambia `http_port` solo si necesitas otro puerto.
- **No compila o no inicia:** ejecuta `rebar3 compile` desde la raiz y conserva
  el mensaje de error completo para diagnosticar dependencias/configuracion.
- **No se ve el estilo Stitch:** comprueba la conexion a Internet; las
  exportaciones cargan Tailwind e iconos desde CDN.
- **El dashboard no muestra una partida:** crea una desde `/` y vuelve al
  dashboard. No se muestran datos de muestra como si fueran datos reales.

## Seguridad y limites

El panel y las API administrativas no tienen autenticacion. Usalos solo en una
red de confianza; no expongas el servidor publicamente sin anadir controles de
acceso. El ejemplo de systemd es una plantilla y no se instala ni se habilita
automaticamente.
