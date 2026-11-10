# Prompt para Google Stitch — #17 Servidor de juego

Disena la interfaz de: **Servidor de juego** (Sistemas distribuidos).
Contexto: (tres en raya, trivia, ajedrez): un proceso por partida y matchmaking.

Pantallas minimas:
1. Dashboard principal con el estado en tiempo real.
2. Detalle de un elemento (uno de los procesos del dominio).
3. Historial / bitacora de eventos y alertas.

Requisitos: legible en celular, colores de estado (ok / alerta / falla), espanol.

Exporta el zip desde Stitch y descomprimelo en esta carpeta (`design/`),
incluyendo `DESIGN.md`.

## Pantallas de administración

Agrega tres pantallas nuevas al proyecto de Stitch sin modificar las pantallas
existentes del juego:

1. Dashboard en tiempo real para el estado OTP, partidas activas, jugadores en
   matchmaking, duracion promedio, actividad y alertas.
2. Detalle de una partida/proceso con ID, PID, estado `gen_statem`, jugadores,
   turno, tablero, duracion y estado de salud.
3. Bitacora de eventos y alertas con filtros por fecha, partida, tipo y
   severidad; incluye movimientos, finalizaciones y caidas de procesos.

Conserva una identidad visual P17 con azules noche y acentos cyan, texto en
espanol, contraste accesible y adaptacion movil sin desbordamientos. Usa datos
de demostracion realistas y diferencia visualmente los estados saludable,
alerta y falla. Exporta desde Stitch las tres pantallas para incluir sus
archivos `screen.png` y `code.html` junto con este documento.
