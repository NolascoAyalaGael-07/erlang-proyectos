-module(p17_http_handler).

-export([init/2]).

init(Req, inicio) ->
    case cowboy_req:method(Req) of
        <<"GET">> ->
            servir_interfaz(Req);
        _ ->
            responder(405, #{error => method_not_allowed}, Req)
    end;

init(Req, admin_dashboard) ->
    case cowboy_req:method(Req) of
        <<"GET">> ->
            servir_panel_admin(Req);
        _ ->
            responder(405, #{error => method_not_allowed}, Req)
    end;

init(Req, admin_stitch_js) ->
    case cowboy_req:method(Req) of
        <<"GET">> ->
            servir_archivo_privado(
                "admin-stitch.js",
                <<"application/javascript; charset=utf-8">>,
                Req
            );
        _ ->
            responder(405, #{error => method_not_allowed}, Req)
    end;

init(Req, admin_api) ->
    case cowboy_req:method(Req) of
        <<"GET">> ->
            servir_datos_admin(Req);
        _ ->
            responder(405, #{error => method_not_allowed}, Req)
    end;

init(Req, admin_events_api) ->
    case cowboy_req:method(Req) of
        <<"GET">> ->
            Eventos = p17_eventos:historial(),
            responder(200, #{
                total => length(Eventos),
                eventos => Eventos
            }, Req);
        _ ->
            responder(405, #{error => method_not_allowed}, Req)
    end;

init(Req, metrics) ->
    case cowboy_req:method(Req) of
        <<"GET">> ->
            servir_metricas(Req);
        _ ->
            responder(405, #{error => method_not_allowed}, Req)
    end;

init(Req, health) ->
    case cowboy_req:method(Req) of
        <<"GET">> ->
            responder(200, #{
                status => ok,
                service => p17_servidor_de_juego
            }, Req);
        _ ->
            responder(405, #{error => method_not_allowed}, Req)
    end;

init(Req, partidas) ->
    manejar_partidas(cowboy_req:method(Req), Req);

init(Req, partida) ->
    case cowboy_req:method(Req) of
        <<"GET">> ->
            Id = cowboy_req:binding(id, Req),
            case p17_partidas_sup:obtener_partida(Id) of
                {ok, Datos} ->
                    responder(200, Datos, Req);
                {error, Razon} ->
                    responder(404, #{error => Razon}, Req)
            end;
        _ ->
            responder(405, #{error => method_not_allowed}, Req)
    end;

init(Req, movimiento) ->
    case cowboy_req:method(Req) of
        <<"POST">> ->
            manejar_movimiento(Req);
        _ ->
            responder(405, #{error => method_not_allowed}, Req)
    end.

servir_interfaz(Req) ->
    servir_archivo_privado("index.html", Req).

servir_panel_admin(Req) ->
    Vista = proplists:get_value(
        <<"vista">>,
        cowboy_req:parse_qs(Req),
        <<"dashboard">>
    ),
    case Vista of
        <<"dashboard">> ->
            servir_pantalla_stitch("admin.html", Req);
        <<"detalle">> ->
            servir_pantalla_stitch("admin-detail.html", Req);
        <<"eventos">> ->
            servir_pantalla_stitch("admin-events.html", Req);
        _ ->
            responder(400, #{error => vista_admin_invalida}, Req)
    end.

servir_pantalla_stitch(Nombre, Req) ->
    case leer_archivo_privado(Nombre) of
        {ok, Contenido} ->
            Pagina = binary:replace(
                Contenido,
                <<"</body>">>,
                <<"<script src=\"/admin-stitch.js?v=1\"></script>\n</body>">>
            ),
            responder_html(Pagina, Req);
        {error, no_se_encontro_directorio_priv} ->
            responder(500, #{error => no_se_encontro_directorio_priv}, Req);
        {error, _Razon} ->
            responder(500, #{error => no_se_encontro_interfaz}, Req)
    end.

servir_archivo_privado(Nombre, Req) ->
    servir_archivo_privado(
        Nombre,
        <<"text/html; charset=utf-8">>,
        Req
    ).

servir_archivo_privado(Nombre, TipoContenido, Req) ->
    case leer_archivo_privado(Nombre) of
        {ok, Contenido} ->
            ReqActualizado = cowboy_req:reply(
                200,
                #{
                    <<"content-type">> => TipoContenido,
                    <<"cache-control">> => <<"no-store">>
                },
                Contenido,
                Req
            ),
            {ok, ReqActualizado, undefined};
        {error, no_se_encontro_directorio_priv} ->
            responder(500, #{error => no_se_encontro_directorio_priv}, Req);
        {error, _Razon} ->
            responder(500, #{error => no_se_encontro_interfaz}, Req)
    end.

leer_archivo_privado(Nombre) ->
    case code:priv_dir(p17_servidor_de_juego) of
        {error, _Razon} ->
            {error, no_se_encontro_directorio_priv};
        PrivDir ->
            Ruta = filename:join(PrivDir, Nombre),
            file:read_file(Ruta)
    end.

responder_html(Contenido, Req) ->
    ReqActualizado = cowboy_req:reply(
        200,
        #{
            <<"content-type">> => <<"text/html; charset=utf-8">>,
            <<"cache-control">> => <<"no-store">>
        },
        Contenido,
        Req
    ),
    {ok, ReqActualizado, undefined}.

servir_datos_admin(Req) ->
    PartidasActivas = partidas_admin(),
    EstadoMatchmaking = p17_matchmaking:estado(),
    Metricas = p17_eventos:metricas(),
    responder(200, #{
        partidas_activas => length(PartidasActivas),
        partidas => PartidasActivas,
        jugadores_en_espera =>
            maps:get(jugadores_en_espera, EstadoMatchmaking),
        cantidad_en_espera =>
            maps:get(cantidad_en_espera, EstadoMatchmaking),
        duracion_promedio_ms => maps:get(duracion_promedio_ms, Metricas),
        partidas_finalizadas => maps:get(partidas_finalizadas, Metricas),
        partidas_caidas => maps:get(partidas_caidas, Metricas)
    }, Req).

servir_metricas(Req) ->
    EstadoMatchmaking = p17_matchmaking:estado(),
    MetricasPartidas = p17_eventos:metricas(),
    PartidasActivas = partidas_admin(),
    ProcesosConMasMemoria = [
        #{
            pid => list_to_binary(pid_to_list(Pid)),
            memoria_bytes => Memoria
        }
        || {Pid, Memoria, _Identificadores} <- recon:proc_count(memory, 5)
    ],
    Diagnostico = #{
        memoria_usada_bytes => recon_alloc:memory(used),
        procesos => erlang:system_info(process_count),
        limite_procesos => erlang:system_info(process_limit),
        run_queue => erlang:statistics(run_queue),
        procesos_mayor_memoria => ProcesosConMasMemoria
    },
    responder(200, #{
        partidas_activas => length(PartidasActivas),
        jugadores_en_espera => maps:get(cantidad_en_espera, EstadoMatchmaking),
        duracion_promedio_ms =>
            maps:get(duracion_promedio_ms, MetricasPartidas),
        partidas_finalizadas =>
            maps:get(partidas_finalizadas, MetricasPartidas),
        partidas_caidas => maps:get(partidas_caidas, MetricasPartidas),
        diagnostico => Diagnostico
    }, Req).

partidas_admin() ->
    lists:filtermap(
        fun(#{id := Id, pid := Pid}) ->
            case p17_partidas_sup:obtener_partida(Id) of
                {ok, #{estado := jugando, datos := Datos}} ->
                    {true, #{
                        id => Id,
                        pid => list_to_binary(pid_to_list(Pid)),
                        estado => jugando,
                        datos => Datos,
                        duracion_ms => p17_eventos:duracion_partida(Pid)
                    }};
                _ ->
                    false
            end
        end,
        p17_partidas_sup:partidas()
    ).

manejar_partidas(<<"GET">>, Req) ->
    Activas = [
        #{id => maps:get(id, Partida)}
        || Partida <- p17_partidas_sup:partidas()
    ],
    responder(200, #{partidas => Activas}, Req);

manejar_partidas(<<"POST">>, Req) ->
    Parametros = cowboy_req:parse_qs(Req),
    Jugador1 = proplists:get_value(<<"jugador1">>, Parametros),
    Jugador2 = proplists:get_value(<<"jugador2">>, Parametros),
    crear_partida(Jugador1, Jugador2, Req);

manejar_partidas(_Metodo, Req) ->
    responder(405, #{error => method_not_allowed}, Req).

crear_partida(Jugador1, Jugador2, Req)
        when is_binary(Jugador1), byte_size(Jugador1) > 0,
             is_binary(Jugador2), byte_size(Jugador2) > 0 ->
    case p17_partidas_sup:iniciar_partida_con_id(Jugador1, Jugador2) of
        {ok, Id, _Pid} ->
            case p17_partidas_sup:obtener_partida(Id) of
                {ok, Datos} ->
                    responder(201, #{id => Id, partida => Datos}, Req);
                {error, Razon} ->
                    responder(500, #{error => Razon}, Req)
            end;
        {error, Razon} ->
            responder(500, #{error => Razon}, Req)
    end;
crear_partida(_Jugador1, _Jugador2, Req) ->
    responder(400, #{
        error => parametros_requeridos,
        requeridos => [jugador1, jugador2]
    }, Req).

manejar_movimiento(Req) ->
    Id = cowboy_req:binding(id, Req),
    Parametros = cowboy_req:parse_qs(Req),
    Jugador = proplists:get_value(<<"jugador">>, Parametros),
    PosicionTexto = proplists:get_value(<<"posicion">>, Parametros),
    case parsear_posicion(PosicionTexto) of
        {ok, Posicion} when is_binary(Jugador), byte_size(Jugador) > 0 ->
            aplicar_movimiento(Id, Jugador, Posicion, Req);
        _ ->
            responder(400, #{
                error => parametros_requeridos,
                requeridos => [jugador, posicion]
            }, Req)
    end.

aplicar_movimiento(Id, Jugador, Posicion, Req) ->
    case p17_partidas_sup:mover_partida(Id, Jugador, Posicion) of
        {ok, Resultado} ->
            case p17_partidas_sup:obtener_partida(Id) of
                {ok, Datos} ->
                    responder(200, #{
                        resultado => Resultado,
                        partida => Datos
                    }, Req);
                {error, Razon} ->
                    responder(404, #{error => Razon}, Req)
            end;
        {error, partida_no_encontrada} ->
            responder(404, #{error => partida_no_encontrada}, Req);
        {error, Razon} ->
            responder(409, #{error => Razon}, Req)
    end.

parsear_posicion(Texto) when is_binary(Texto) ->
    try
        {ok, binary_to_integer(Texto)}
    catch
        error:badarg ->
            error
    end;
parsear_posicion(_Texto) ->
    error.

responder(Codigo, Datos, Req) ->
    Cuerpo = iolist_to_binary(p17_json:encode(Datos)),
    ReqActualizado = cowboy_req:reply(
        Codigo,
        #{<<"content-type">> => <<"application/json; charset=utf-8">>},
        Cuerpo,
        Req
    ),
    {ok, ReqActualizado, undefined}.
