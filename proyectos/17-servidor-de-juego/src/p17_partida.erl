-module(p17_partida).
-behaviour(gen_statem).

-export([start_link/2, mover/3, estado/1]).
-export([init/1, callback_mode/0, handle_event/4]).

start_link(Jugador1, Jugador2) ->
    gen_statem:start_link(?MODULE, {Jugador1, Jugador2}, []).

mover(Pid, Jugador, Posicion) ->
    gen_statem:call(Pid, {mover, Jugador, Posicion}).

estado(Pid) ->
    gen_statem:call(Pid, estado).

init({Jugador1, Jugador2}) ->
    Tablero = lists:duplicate(9, vacio),
    {ok, jugando, #{
        jugadores => [Jugador1, Jugador2],
        tablero => Tablero,
        turno => Jugador1
    }}.

callback_mode() ->
    handle_event_function.

handle_event({call, From}, estado, Estado, Datos) ->
    {keep_state, Datos, [{reply, From, #{estado => Estado, datos => Datos}}]};
handle_event({call, From}, {mover, Jugador, Posicion}, jugando, Datos) ->
    procesar_movimiento(From, Jugador, Posicion, Datos);
handle_event({call, From}, {mover, _Jugador, _Posicion}, terminado, _Datos) ->
    {keep_state_and_data, [{reply, From, {error, partida_terminada}}]};
handle_event(_Tipo, _Evento, _Estado, _Datos) ->
    keep_state_and_data.

procesar_movimiento(From, Jugador, Posicion, Datos) ->
    Jugadores = maps:get(jugadores, Datos),
    Turno = maps:get(turno, Datos),
    Tablero = maps:get(tablero, Datos),
    case validar_movimiento(Jugador, Turno, Posicion, Jugadores, Tablero) of
        ok ->
            {Antes, [_Casilla | Despues]} =
                lists:split(Posicion - 1, Tablero),
            NuevoTablero = Antes ++ [Jugador | Despues],
            case ganador(NuevoTablero, Jugador) of
                true ->
                    NuevosDatos = Datos#{
                        tablero := NuevoTablero,
                        ganador => Jugador
                    },
                    {next_state, terminado, NuevosDatos,
                     [{reply, From, {ok, ganador}}]};
                false ->
                    case lists:member(vacio, NuevoTablero) of
                        false ->
                            NuevosDatos = Datos#{
                                tablero := NuevoTablero,
                                resultado => empate
                            },
                            {next_state, terminado, NuevosDatos,
                             [{reply, From, {ok, empate}}]};
                        true ->
                            [OtroJugador] = lists:delete(Jugador, Jugadores),
                            NuevosDatos = Datos#{
                                tablero := NuevoTablero,
                                turno := OtroJugador
                            },
                            {keep_state, NuevosDatos,
                             [{reply, From, {ok, movimiento_aplicado}}]}
                    end
            end;
        {error, Razon} ->
            {keep_state_and_data, [{reply, From, {error, Razon}}]}
    end.

validar_movimiento(Jugador, Turno, Posicion, Jugadores, Tablero) ->
    EsJugador = lists:member(Jugador, Jugadores),
    EsSuTurno = Jugador =:= Turno,
    EsPosicion = is_integer(Posicion) andalso
                 Posicion >= 1 andalso
                 Posicion =< 9,
    case {EsJugador, EsSuTurno, EsPosicion} of
        {false, _, _} ->
            {error, jugador_no_participa};
        {true, false, _} ->
            {error, no_es_tu_turno};
        {true, true, false} ->
            {error, posicion_invalida};
        {true, true, true} ->
            case lists:nth(Posicion, Tablero) of
                vacio -> ok;
                _ -> {error, casilla_ocupada}
            end
    end.

ganador(Tablero, Jugador) ->
    Lineas = [
        [1, 2, 3], [4, 5, 6], [7, 8, 9],
        [1, 4, 7], [2, 5, 8], [3, 6, 9],
        [1, 5, 9], [3, 5, 7]
    ],
    lists:any(
        fun([A, B, C]) ->
            lists:nth(A, Tablero) =:= Jugador andalso
            lists:nth(B, Tablero) =:= Jugador andalso
            lists:nth(C, Tablero) =:= Jugador
        end,
        Lineas
    ).
