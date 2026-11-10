-module(p17_partida_tests).
-include_lib("eunit/include/eunit.hrl").

turno_y_estado_inicial_test() ->
    {ok, Pid} = p17_partida:start_link(jugador_x, jugador_o),
    unlink(Pid),
    try
        Estado = p17_partida:estado(Pid),
        ?assertEqual(jugando, maps:get(estado, Estado)),
        Datos = maps:get(datos, Estado),
        ?assertEqual(jugador_x, maps:get(turno, Datos)),
        ?assertEqual(lists:duplicate(9, vacio), maps:get(tablero, Datos))
    after
        gen_statem:stop(Pid)
    end.

rechaza_movimiento_fuera_de_turno_test() ->
    {ok, Pid} = p17_partida:start_link(jugador_x, jugador_o),
    unlink(Pid),
    try
        ?assertEqual(
            {error, no_es_tu_turno},
            p17_partida:mover(Pid, jugador_o, 1)
        )
    after
        gen_statem:stop(Pid)
    end.

rechaza_casilla_ocupada_test() ->
    {ok, Pid} = p17_partida:start_link(jugador_x, jugador_o),
    unlink(Pid),
    try
        ?assertEqual(
            {ok, movimiento_aplicado},
            p17_partida:mover(Pid, jugador_x, 1)
        ),
        ?assertEqual(
            {error, casilla_ocupada},
            p17_partida:mover(Pid, jugador_o, 1)
        )
    after
        gen_statem:stop(Pid)
    end.

detecta_ganador_test() ->
    {ok, Pid} = p17_partida:start_link(jugador_x, jugador_o),
    unlink(Pid),
    try
        ?assertEqual({ok, movimiento_aplicado},
                     p17_partida:mover(Pid, jugador_x, 1)),
        ?assertEqual({ok, movimiento_aplicado},
                     p17_partida:mover(Pid, jugador_o, 4)),
        ?assertEqual({ok, movimiento_aplicado},
                     p17_partida:mover(Pid, jugador_x, 2)),
        ?assertEqual({ok, movimiento_aplicado},
                     p17_partida:mover(Pid, jugador_o, 5)),
        ?assertEqual({ok, ganador},
                     p17_partida:mover(Pid, jugador_x, 3)),
        Estado = p17_partida:estado(Pid),
        ?assertEqual(terminado, maps:get(estado, Estado)),
        ?assertEqual(jugador_x, maps:get(ganador, maps:get(datos, Estado)))
    after
        gen_statem:stop(Pid)
    end.

rechaza_movimiento_despues_de_terminar_test() ->
    {ok, Pid} = p17_partida:start_link(jugador_x, jugador_o),
    unlink(Pid),
    try
        p17_partida:mover(Pid, jugador_x, 1),
        p17_partida:mover(Pid, jugador_o, 4),
        p17_partida:mover(Pid, jugador_x, 2),
        p17_partida:mover(Pid, jugador_o, 5),
        p17_partida:mover(Pid, jugador_x, 3),
        ?assertEqual(
            {error, partida_terminada},
            p17_partida:mover(Pid, jugador_o, 6)
        )
    after
        gen_statem:stop(Pid)
    end.
