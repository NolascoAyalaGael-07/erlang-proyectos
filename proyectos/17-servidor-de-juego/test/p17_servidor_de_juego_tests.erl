-module(p17_servidor_de_juego_tests).
-include_lib("eunit/include/eunit.hrl").

supervision_y_matchmaking_test_() ->
    {setup,
     fun iniciar_arbol/0,
     fun detener_arbol/1,
     fun(_Contexto) ->
         ?_test(probar_supervision_y_matchmaking())
     end}.

iniciar_arbol() ->
    PuertoConfigurado =
        application:get_env(p17_servidor_de_juego, http_port),
    ok = application:set_env(p17_servidor_de_juego, http_port, 0),
    {ok, AplicacionesIniciadas} = application:ensure_all_started(cowboy),
    {ok, AplicacionesIniciadasInets} =
        application:ensure_all_started(inets),
    {ok, Pid} = p17_servidor_de_juego_sup:start_link(),
    unlink(Pid),
    {Pid, AplicacionesIniciadas ++ AplicacionesIniciadasInets,
     PuertoConfigurado}.

detener_arbol({Pid, AplicacionesIniciadas, PuertoConfigurado}) ->
    case is_process_alive(Pid) of
        true ->
            gen_server:stop(Pid, shutdown, 5000);
        false ->
            ok
    end,
    lists:foreach(
        fun(Aplicacion) ->
            application:stop(Aplicacion)
        end,
        lists:reverse(AplicacionesIniciadas)
    ),
    restaurar_puerto(PuertoConfigurado),
    ok.

restaurar_puerto(undefined) ->
    application:unset_env(p17_servidor_de_juego, http_port);
restaurar_puerto({ok, Puerto}) ->
    application:set_env(p17_servidor_de_juego, http_port, Puerto).

probar_supervision_y_matchmaking() ->
    ?assertEqual(pong, p17_servidor_de_juego_server:ping()),
    ?assert(is_map(p17_servidor_de_juego_server:state())),

    {ok, Partida1} =
        p17_partidas_sup:iniciar_partida(jugador_a, jugador_b),
    {ok, Partida2} =
        p17_partidas_sup:iniciar_partida(jugador_c, jugador_d),

    ?assertEqual(2, length(p17_partidas_sup:partidas())),
    ?assertEqual(ok, p17_partidas_sup:detener_partida(Partida1)),
    ?assert(is_process_alive(Partida2)),
    ?assertEqual(1, length(p17_partidas_sup:partidas())),

    ?assertEqual(
        {esperando, 1},
        p17_matchmaking:entrar(jugador_e, self())
    ),

    Resultado =
        p17_matchmaking:entrar(jugador_f, self()),
    ?assertMatch(
        {partida_iniciada, _, jugador_f, jugador_e},
        Resultado
    ),

    {partida_iniciada, PartidaMatch, jugador_f, jugador_e} = Resultado,

    receive
        {partida_iniciada, PartidaMatch, jugador_e, jugador_f} ->
            ok
    after 1000 ->
        ?assert(false)
    end,

    receive
        {partida_iniciada, PartidaMatch, jugador_f, jugador_e} ->
            ok
    after 1000 ->
        ?assert(false)
    end,

    Estado = p17_matchmaking:estado(),
    ?assertEqual([], maps:get(jugadores_en_espera, Estado)),
    ?assert(is_process_alive(PartidaMatch)),

    {ok, IdPartida, PartidaConId} =
        p17_partidas_sup:iniciar_partida_con_id(jugador_g, jugador_h),
    {ok, DatosPartida} =
        p17_partidas_sup:obtener_partida(IdPartida),

    ?assert(is_binary(IdPartida)),
    ?assertEqual(jugando, maps:get(estado, DatosPartida)),
    ?assert(is_process_alive(PartidaConId)),

    {ok, {{_, 200, _}, _, Panel}} = solicitar_get("/admin"),
    ?assertNotEqual(
        nomatch,
        binary:match(Panel, <<"P17 ADMIN">>)
    ),
    ?assertNotEqual(
        nomatch,
        binary:match(Panel, <<"Centro de Supervisión Erlang/OTP"/utf8>>)
    ),
    ?assertNotEqual(
        nomatch,
        binary:match(Panel, <<"/admin-stitch.js">>)
    ),
    {ok, {{_, 200, _}, _, DetalleAdmin}} =
        solicitar_get("/admin?vista=detalle"),
    ?assertNotEqual(
        nomatch,
        binary:match(DetalleAdmin, <<"btn-restart-process">>)
    ),
    {ok, {{_, 200, _}, _, EventosAdmin}} =
        solicitar_get("/admin?vista=eventos"),
    ?assertNotEqual(
        nomatch,
        binary:match(EventosAdmin, <<"events-table-body">>)
    ),
    {ok, {{_, 200, _}, HeadersAdminJs, AdminJs}} =
        solicitar_get("/admin-stitch.js"),
    ?assertEqual(
        "application/javascript; charset=utf-8",
        proplists:get_value("content-type", HeadersAdminJs)
    ),
    ?assertNotEqual(nomatch, binary:match(AdminJs, <<"/api/admin">>)),
    {ok, {{_, 200, _}, _, Dashboard}} = solicitar_get("/api/admin"),
    ?assertNotEqual(
        nomatch,
        binary:match(Dashboard, <<"\"partidas_activas\":3">>)
    ),
    ?assertNotEqual(nomatch, binary:match(Dashboard, <<"\"pid\":\"<">>)),
    ?assertNotEqual(nomatch, binary:match(Dashboard, <<"\"tablero\"">>)),
    ?assertNotEqual(
        nomatch,
        binary:match(Dashboard, <<"\"cantidad_en_espera\":0">>)
    ),
    {ok, {{_, 200, _}, _, Eventos}} = solicitar_get("/api/admin/eventos"),
    ?assertNotEqual(nomatch, binary:match(Eventos, <<"\"eventos\"">>)),
    ?assertNotEqual(
        nomatch,
        binary:match(Eventos, <<"\"partida_iniciada\"">>)
    ),
    {ok, {{_, 200, _}, HeadersHealth, Health}} = solicitar_get("/health"),
    ?assertEqual("application/json; charset=utf-8",
                 proplists:get_value("content-type", HeadersHealth)),
    ?assertNotEqual(nomatch, binary:match(Health, <<"\"status\":\"ok\"">>)),
    {ok, {{_, 200, _}, _, Metricas}} = solicitar_get("/metrics"),
    ?assertNotEqual(
        nomatch,
        binary:match(Metricas, <<"\"diagnostico\"">>)
    ),
    ?assertNotEqual(
        nomatch,
        binary:match(Metricas, <<"\"procesos_mayor_memoria\"">>)
    ),
    ?assertNotEqual(
        nomatch,
        binary:match(Metricas, <<"\"memoria_usada_bytes\"">>)
    ),
    probar_recuperacion_falla_partida().

solicitar_get(Ruta) ->
    Puerto = ranch:get_port(http_listener),
    Url = lists:flatten(
        io_lib:format("http://127.0.0.1:~B~s", [Puerto, Ruta])
    ),
    httpc:request(get, {Url, []}, [], [{body_format, binary}]).

probar_recuperacion_falla_partida() ->
    {ok, IdCaida, PidCaida} =
        p17_partidas_sup:iniciar_partida_con_id(jugador_i, jugador_j),
    {ok, _IdSana, PidSana} =
        p17_partidas_sup:iniciar_partida_con_id(jugador_k, jugador_l),
    ?assertEqual(
        {ok, movimiento_aplicado},
        p17_partidas_sup:mover_partida(IdCaida, jugador_i, 1)
    ),
    _ = p17_eventos:metricas(),
    Cliente1 = suscriptor_de_prueba(),
    Cliente2 = suscriptor_de_prueba(),
    try
        esperar_suscriptor(Cliente1),
        esperar_suscriptor(Cliente2),
        exit(PidCaida, kill),
        esperar_aviso_caida(IdCaida),
        esperar_aviso_caida(IdCaida),

        ?assertNot(is_process_alive(PidCaida)),
        ?assert(is_process_alive(whereis(p17_servidor_de_juego_sup))),
        ?assert(is_process_alive(PidSana)),
        ?assertMatch(
            {error, partida_no_encontrada},
            p17_partidas_sup:obtener_partida(IdCaida)
        ),
        ?assertEqual(
            {error, partida_no_encontrada},
            p17_partidas_sup:mover_partida(IdCaida, jugador_j, 2)
        ),
        ?assertEqual(
            {ok, movimiento_aplicado},
            p17_partidas_sup:mover_partida(_IdSana, jugador_k, 1)
        ),
        ?assertEqual(1, maps:get(partidas_caidas, p17_eventos:metricas()))
    after
        exit(Cliente1, kill),
        exit(Cliente2, kill),
        _ = p17_partidas_sup:detener_partida(PidSana)
    end.

suscriptor_de_prueba() ->
    Padre = self(),
    spawn(fun() ->
        ok = p17_eventos:suscribir(),
        Padre ! {suscriptor_listo, self()},
        receive
            {p17_eventos, Evento} ->
                Padre ! {aviso_suscriptor, self(), Evento}
        end
    end).

esperar_suscriptor(Pid) ->
    receive
        {suscriptor_listo, Pid} ->
            ok
    after 1000 ->
        ?assert(false)
    end.

esperar_aviso_caida(Id) ->
    receive
        {aviso_suscriptor, _Pid, #{evento := partida_caida, id := Id}} ->
            ok
    after 1000 ->
        ?assert(false)
    end.
