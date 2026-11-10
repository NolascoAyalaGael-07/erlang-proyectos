# Preparacion de entrega — rubrica Demo Proyecto Erlang

La rubrica adjunta evalua ocho criterios y describe cinco niveles: Excelente,
Bueno, Aceptable, Insuficiente y Deficiente. No se asignan porcentajes ni
ponderaciones porque el documento no los muestra.

| Criterio | Evidencia verificable del proyecto | Como mostrarlo |
|---|---|---|
| Solucion funcional en Erlang | `src/p17_partida.erl` implementa la partida con `gen_statem`; `src/p17_partidas_sup.erl` administra partidas independientes. | Crear una partida, alternar movimientos y mostrar el resultado en `/`. |
| Montaje y ejecucion en VM | Validacion local en Ubuntu WSL 2 con Erlang/OTP 27 y rebar3 3.26.0. | Mostrar la distro en ejecucion, la version de OTP y el arranque con `rebar3 shell`. |
| Demostracion del proyecto | Cliente de juego, panel administrativo, API HTTP, WebSocket y diagnostico. | Seguir el guion de `GUION_LOOM.md` de principio a fin, sin sustituir el backend por datos de muestra. |
| Diseno UIX con Google Stitch | Proyecto Stitch **Tres en Raya P17**, exportaciones originales en `design/stitch_tres_en_raya_p17/` y paginas conectadas en `priv/admin*.html`. | Mostrar el proyecto en Stitch y despues las mismas vistas servidas por `/admin`. |
| Manual de uso en Gist | `entrega/README.md` es el reporte listo para copiarse a un Gist. | Crear un Gist secreto y no incluir cookies, credenciales ni archivos locales de configuracion. |
| Calidad tecnica del codigo | Modulos OTP separados por responsabilidad y pruebas en `test/`. | Mostrar `p17_partida`, los supervisores, el handler HTTP y la prueba de recuperacion; ejecutar `rebar3 eunit`. |
| Integracion backend, entorno y UIX | `/api/admin`, `/api/admin/eventos`, `/metrics`, `/health` y `/ws/juego` alimentan las vistas web. | Hacer un movimiento y observar el cambio en el dashboard y en la bitacora. |
| Presentacion y argumentacion tecnica | Las decisiones de supervision y el limite de las acciones administrativas estan documentados en `README.md`. | Explicar por que una partida caida no se reinicia con estado perdido y por que no se agrega un proceso de dominio por jugador. |

## Evidencias propuestas

- Captura del proyecto original de Stitch y capturas reales de las paginas
  funcionales (no usar las pantallas exportadas como prueba del backend).
- Video Loom mostrando una ejecucion completa y narracion tecnica.
- Grabacion Asciinema de comandos y resultados reales de Erlang/OTP.
- Manual de cliente en Gist secreto.
- Codigo fuente completo del proyecto entregado como carpeta o ZIP desde el
  workspace. El repositorio base asignado no contiene automaticamente estos
  cambios locales: no afirmar que el enlace remoto incluye cambios no subidos.

Para crear el Gist, copia `entrega/README.md` en `README.md` en gist.github.com,
selecciona **Create secret gist** y entrega su URL en Idoceo.
Un Gist secreto no aparece en busquedas, pero cualquiera que tenga el enlace
puede leerlo; no es un mecanismo de control de acceso.

## Estado y honestidad de la evidencia

`entrega/evidencias/validacion.cast` registra una ejecucion real de EUnit:
9 pruebas, 0 fallos; tambien conserva respuestas exitosas de `/health` y
`/metrics`. Las capturas locales muestran una partida de demostracion con
nombres ficticios, tanto activa como terminada. El resultado actual de la
instancia puede cambiar al reiniciar el nodo.

No se ha grabado ni subido un Loom ni se ha publicado el Gist. El usuario debe
realizar esas acciones desde sus cuentas. No se hizo commit ni push; el codigo
local debe incluirse en la entrega como carpeta o ZIP.
