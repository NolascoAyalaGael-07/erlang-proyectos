-module(p17_eventos).
-behaviour(gen_server).

-export([
    start_link/0,
    registrar_partida/2,
    partida_actualizada/2,
    registrar_evento/1,
    suscribir/0,
    desuscribir/0,
    metricas/0,
    historial/0,
    duracion_partida/1
]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

-define(MAX_EVENTOS, 200).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

registrar_partida(Id, Pid) when is_binary(Id), is_pid(Pid) ->
    gen_server:call(?MODULE, {registrar_partida, Id, Pid}).

partida_actualizada(Id, Datos) when is_binary(Id), is_map(Datos) ->
    gen_server:cast(?MODULE, {partida_actualizada, Id, Datos}).

registrar_evento(Evento) when is_map(Evento) ->
    gen_server:cast(?MODULE, {registrar_evento, Evento}).

suscribir() ->
    gen_server:call(?MODULE, {suscribir, self()}).

desuscribir() ->
    gen_server:call(?MODULE, {desuscribir, self()}).

metricas() ->
    gen_server:call(?MODULE, metricas).

historial() ->
    gen_server:call(?MODULE, historial).

duracion_partida(Pid) when is_pid(Pid) ->
    gen_server:call(?MODULE, {duracion_partida, Pid}).

init([]) ->
    {ok, #{
        partidas => #{},
        suscriptores => #{},
        historial => [],
        duracion_total_ms => 0,
        partidas_finalizadas => 0,
        partidas_caidas => 0
    }}.

handle_call({registrar_partida, Id, Pid}, _From, Estado) ->
    Partidas = maps:get(partidas, Estado),
    case maps:is_key(Pid, Partidas) of
        true ->
            {reply, {error, partida_ya_registrada}, Estado};
        false ->
            Referencia = erlang:monitor(process, Pid),
            Partida = #{
                id => Id,
                monitor => Referencia,
                inicio_ms => erlang:monotonic_time(millisecond),
                finalizada => false
            },
            NuevoEstado = Estado#{partidas := Partidas#{Pid => Partida}},
            EstadoConEvento = anotar_evento(#{
                evento => partida_iniciada,
                severidad => info,
                id => Id
            }, NuevoEstado),
            {reply, ok, EstadoConEvento}
    end;

handle_call({suscribir, Pid}, _From, Estado) ->
    Suscriptores = maps:get(suscriptores, Estado),
    case maps:is_key(Pid, Suscriptores) of
        true ->
            {reply, ok, Estado};
        false ->
            Referencia = erlang:monitor(process, Pid),
            {reply, ok, Estado#{suscriptores := Suscriptores#{Pid => Referencia}}}
    end;

handle_call({desuscribir, Pid}, _From, Estado) ->
    Suscriptores = maps:get(suscriptores, Estado),
    case maps:take(Pid, Suscriptores) of
        {Referencia, NuevosSuscriptores} ->
            erlang:demonitor(Referencia, [flush]),
            {reply, ok, Estado#{suscriptores := NuevosSuscriptores}};
        error ->
            {reply, ok, Estado}
    end;

handle_call(metricas, _From, Estado) ->
    Finalizadas = maps:get(partidas_finalizadas, Estado),
    DuracionTotal = maps:get(duracion_total_ms, Estado),
    DuracionPromedio = case Finalizadas of
        0 -> null;
        _ -> DuracionTotal div Finalizadas
    end,
    Respuesta = #{
        partidas_finalizadas => Finalizadas,
        partidas_caidas => maps:get(partidas_caidas, Estado),
        duracion_promedio_ms => DuracionPromedio
    },
    {reply, Respuesta, Estado};

handle_call(historial, _From, Estado) ->
    {reply, maps:get(historial, Estado), Estado};

handle_call({duracion_partida, Pid}, _From, Estado) ->
    case maps:find(Pid, maps:get(partidas, Estado)) of
        {ok, Partida} ->
            {reply, duracion_ms(Partida), Estado};
        error ->
            {reply, null, Estado}
    end;

handle_call(_Solicitud, _From, Estado) ->
    {reply, {error, solicitud_desconocida}, Estado}.

handle_cast({registrar_evento, Evento}, Estado) ->
    {noreply, anotar_evento(Evento, Estado)};

handle_cast({partida_actualizada, Id, Datos}, Estado) ->
    Partidas = maps:get(partidas, Estado),
    case buscar_partida(Id, maps:to_list(Partidas)) of
        {ok, Pid, Partida} ->
            EventoActualizacion = #{
                evento => partida_actualizada,
                severidad => info,
                id => Id,
                partida => Datos
            },
            EstadoConEvento = anotar_evento(EventoActualizacion, Estado),
            case {maps:get(estado, Datos, undefined),
                  maps:get(finalizada, Partida)} of
                {terminado, false} ->
                    Duracion = duracion_ms(Partida),
                    EventoFinalizacion = #{
                        evento => partida_finalizada,
                        id => Id,
                        duracion_ms => Duracion,
                        partida => Datos
                    },
                    PartidaActualizada = Partida#{finalizada := true},
                    NuevoEstado = EstadoConEvento#{
                        partidas := Partidas#{Pid := PartidaActualizada},
                        duracion_total_ms :=
                            maps:get(duracion_total_ms, EstadoConEvento) +
                                Duracion,
                        partidas_finalizadas :=
                            maps:get(partidas_finalizadas, EstadoConEvento) + 1
                    },
                    {noreply, anotar_evento(EventoFinalizacion, NuevoEstado)};
                _ ->
                    {noreply, EstadoConEvento}
            end;
        error ->
            {noreply, Estado}
    end;
handle_cast(_Mensaje, Estado) ->
    {noreply, Estado}.

handle_info({'DOWN', Referencia, process, Pid, Razon}, Estado) ->
    Partidas = maps:get(partidas, Estado),
    case maps:take(Pid, Partidas) of
        {#{monitor := Referencia} = Partida, NuevasPartidas} ->
            manejar_caida_partida(Pid, Partida, NuevasPartidas, Razon, Estado);
        _ ->
            eliminar_suscriptor(Pid, Referencia, Estado)
    end;
handle_info(_Mensaje, Estado) ->
    {noreply, Estado}.

manejar_caida_partida(_Pid, Partida, NuevasPartidas, Razon, Estado) ->
    EstadoActualizado = Estado#{partidas := NuevasPartidas},
    case maps:get(finalizada, Partida) of
        true ->
            {noreply, EstadoActualizado};
        false ->
            Id = maps:get(id, Partida),
            case Razon of
                normal ->
                    Evento = #{
                        evento => partida_terminada,
                        severidad => warning,
                        id => Id
                    },
                    {noreply, anotar_evento(Evento, EstadoActualizado)};
                shutdown ->
                    {noreply, EstadoActualizado};
                {shutdown, _} ->
                    {noreply, EstadoActualizado};
                _ ->
                    Evento = #{
                        evento => partida_caida,
                        severidad => error,
                        id => Id
                    },
                    NuevoEstado = EstadoActualizado#{
                        partidas_caidas :=
                            maps:get(partidas_caidas, EstadoActualizado) + 1
                    },
                    {noreply, anotar_evento(Evento, NuevoEstado)}
            end
    end.

eliminar_suscriptor(Pid, Referencia, Estado) ->
    Suscriptores = maps:get(suscriptores, Estado),
    case maps:find(Pid, Suscriptores) of
        {ok, Referencia} ->
            {noreply, Estado#{
                suscriptores := maps:remove(Pid, Suscriptores)
            }};
        _ ->
            {noreply, Estado}
    end.

buscar_partida(_Id, []) ->
    error;
buscar_partida(Id, [{Pid, #{id := Id} = Partida} | _Resto]) ->
    {ok, Pid, Partida};
buscar_partida(Id, [_Entrada | Resto]) ->
    buscar_partida(Id, Resto).

duracion_ms(Partida) ->
    max(
        0,
        erlang:monotonic_time(millisecond) - maps:get(inicio_ms, Partida)
    ).

anotar_evento(EventoSinFecha, Estado) ->
    Evento = EventoSinFecha#{
        timestamp_ms => erlang:system_time(millisecond)
    },
    Historial = [Evento | maps:get(historial, Estado)],
    EstadoActualizado = Estado#{
        historial := lists:sublist(Historial, ?MAX_EVENTOS)
    },
    notificar(Evento, EstadoActualizado),
    EstadoActualizado.

notificar(Evento, Estado) ->
    maps:foreach(
        fun(Pid, _Referencia) ->
            Pid ! {p17_eventos, Evento}
        end,
        maps:get(suscriptores, Estado)
    ),
    ok.
