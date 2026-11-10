-module(p17_eventos_tests).
-include_lib("eunit/include/eunit.hrl").

ciclo_de_vida_de_partidas_test_() ->
    {setup,
     fun iniciar_eventos/0,
     fun detener_eventos/1,
     fun(_Pid) ->
         [
             ?_test(notifica_y_mide_finalizacion()),
             ?_test(notifica_caida()),
             ?_test(websocket_serializa_aviso())
         ]
     end}.

iniciar_eventos() ->
    {ok, Pid} = p17_eventos:start_link(),
    unlink(Pid),
    Pid.

detener_eventos(Pid) ->
    gen_server:stop(Pid).

notifica_y_mide_finalizacion() ->
    ok = p17_eventos:suscribir(),
    Pid = proceso_esperando(),
    Id = <<"partida-finalizada">>,
    try
        ok = p17_eventos:registrar_partida(Id, Pid),
        ?assertEqual(
            Id,
            maps:get(id, hd(p17_eventos:historial()))
        ),
        ?assert(is_integer(p17_eventos:duracion_partida(Pid))),
        ok = p17_eventos:partida_actualizada(Id, #{estado => jugando}),
        _ = recibir_evento(partida_actualizada, Id),
        Datos = #{estado => terminado, datos => #{resultado => empate}},
        ok = p17_eventos:partida_actualizada(Id, Datos),
        _ = recibir_evento(partida_actualizada, Id),
        Finalizacion = recibir_evento(partida_finalizada, Id),
        ?assert(is_integer(maps:get(duracion_ms, Finalizacion))),
        Metricas = p17_eventos:metricas(),
        ?assertEqual(1, maps:get(partidas_finalizadas, Metricas)),
        ?assert(is_integer(maps:get(duracion_promedio_ms, Metricas))),
        Eventos = p17_eventos:historial(),
        ?assert(lists:any(
            fun(Evento) ->
                maps:get(evento, Evento) =:= partida_finalizada andalso
                    maps:get(id, Evento) =:= Id
            end,
            Eventos
        ))
    after
        exit(Pid, kill),
        ok = p17_eventos:desuscribir()
    end.

notifica_caida() ->
    ok = p17_eventos:suscribir(),
    Pid = proceso_esperando(),
    Id = <<"partida-caida">>,
    try
        ok = p17_eventos:registrar_partida(Id, Pid),
        exit(Pid, kill),
        _ = recibir_evento(partida_caida, Id),
        ?assertEqual(1, maps:get(partidas_caidas, p17_eventos:metricas())),
        ?assertMatch(
            #{evento := partida_caida, severidad := error, id := Id},
            hd(p17_eventos:historial())
        )
    after
        ok = p17_eventos:desuscribir()
    end.

websocket_serializa_aviso() ->
    {ok, Estado} = p17_ws_handler:websocket_init(#{}),
    try
        Aviso = #{
            evento => partida_caida,
            id => <<"42">>
        },
        {reply, {text, Mensaje}, Estado} =
            p17_ws_handler:websocket_info({p17_eventos, Aviso}, Estado),
        ?assertNotEqual(
            nomatch,
            binary:match(Mensaje, <<"\"evento\":\"partida_caida\"">>)
        ),
        ?assertNotEqual(nomatch, binary:match(Mensaje, <<"\"id\":\"42\"">>))
    after
        ok = p17_eventos:desuscribir()
    end.

proceso_esperando() ->
    spawn(fun() -> receive detener -> ok end end).

recibir_evento(Nombre, Id) ->
    receive
        {p17_eventos, #{evento := Nombre, id := Id} = Evento} ->
            Evento
    after 1000 ->
        ?assert(false)
    end.
