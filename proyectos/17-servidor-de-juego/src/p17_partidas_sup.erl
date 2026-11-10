-module(p17_partidas_sup).
-behaviour(supervisor).

-export([
    start_link/0,
    iniciar_partida/2,
    iniciar_partida_con_id/2,
    obtener_partida/1,
    mover_partida/3,
    detener_partida/1,
    partidas/0
]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

iniciar_partida(Jugador1, Jugador2) ->
    case iniciar_partida_con_id(Jugador1, Jugador2) of
        {ok, _Id, Pid} ->
            {ok, Pid};
        Error ->
            Error
    end.

iniciar_partida_con_id(Jugador1, Jugador2) ->
    Id = integer_to_binary(erlang:unique_integer([positive, monotonic])),
    Especificacion = #{
        id => Id,
        start => {p17_partida, start_link, [Jugador1, Jugador2]},
        restart => temporary,
        shutdown => 5000,
        type => worker,
        modules => [p17_partida]
    },
    case supervisor:start_child(?MODULE, Especificacion) of
        {ok, Pid} ->
            ok = p17_eventos:registrar_partida(Id, Pid),
            {ok, Id, Pid};
        {ok, Pid, _Informacion} ->
            ok = p17_eventos:registrar_partida(Id, Pid),
            {ok, Id, Pid};
        Error ->
            Error
    end.

obtener_partida(Id) when is_binary(Id) ->
    case buscar_pid(Id) of
        {ok, Pid} ->
            try
                {ok, p17_partida:estado(Pid)}
            catch
                exit:_ ->
                    {error, partida_no_encontrada}
            end;
        error ->
            {error, partida_no_encontrada}
    end;
obtener_partida(_Id) ->
    {error, id_invalido}.

mover_partida(Id, Jugador, Posicion) when is_binary(Id) ->
    case buscar_pid(Id) of
        {ok, Pid} ->
            try
                case p17_partida:mover(Pid, Jugador, Posicion) of
                    {ok, _} = Movimiento ->
                        Datos = p17_partida:estado(Pid),
                        ok = p17_eventos:partida_actualizada(Id, Datos),
                        Movimiento;
                    Error ->
                        Error
                end
            catch
                exit:_ ->
                    {error, partida_no_encontrada}
            end;
        error ->
            {error, partida_no_encontrada}
    end;
mover_partida(_Id, _Jugador, _Posicion) ->
    {error, id_invalido}.

detener_partida(Pid) when is_pid(Pid) ->
    case lists:keyfind(Pid, 2, supervisor:which_children(?MODULE)) of
        {_Id, Pid, worker, [p17_partida]} ->
            case is_process_alive(Pid) of
                true ->
                    gen_statem:stop(Pid),
                    ok;
                false ->
                    {error, partida_ya_terminada}
            end;
        _ ->
            {error, partida_no_encontrada}
    end.

partidas() ->
    [
        #{id => Id, pid => Pid}
        || {Id, Pid, worker, [p17_partida]} <-
               supervisor:which_children(?MODULE),
           is_pid(Pid)
    ].

buscar_pid(Id) ->
    case lists:keyfind(Id, 1, supervisor:which_children(?MODULE)) of
        {Id, Pid, worker, [p17_partida]} when is_pid(Pid) ->
            {ok, Pid};
        _ ->
            error
    end.

init([]) ->
    {ok, {#{strategy => one_for_one, intensity => 10, period => 60}, []}}.
