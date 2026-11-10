-module(p17_matchmaking).
-behaviour(gen_server).

-export([start_link/0, entrar/2, cancelar/1, estado/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

entrar(Jugador, ClientePid) when is_pid(ClientePid) ->
    gen_server:call(?MODULE, {entrar, Jugador, ClientePid});
entrar(_Jugador, _ClientePid) ->
    {error, cliente_invalido}.

cancelar(Jugador) ->
    gen_server:call(?MODULE, {cancelar, Jugador}).

estado() ->
    gen_server:call(?MODULE, estado).

init([]) ->
    {ok, #{espera => queue:new()}}.

handle_call({entrar, Jugador, ClientePid}, _From, Estado) ->
    Espera = maps:get(espera, Estado),
    JugadoresEnEspera = queue:to_list(Espera),
    case ya_esta_en_espera(Jugador, JugadoresEnEspera) of
        true ->
            {reply, {error, ya_estas_en_espera}, Estado};
        false ->
            agregar_o_emparejar(Jugador, ClientePid, Espera, Estado)
    end;

handle_call({cancelar, Jugador}, _From, Estado) ->
    Espera = maps:get(espera, Estado),
    ListaOriginal = queue:to_list(Espera),
    NuevaLista = [
        Entrada
        || Entrada <- ListaOriginal,
           maps:get(jugador, Entrada) =/= Jugador
    ],
    case length(NuevaLista) =:= length(ListaOriginal) of
        true ->
            {reply, {error, no_estas_en_espera}, Estado};
        false ->
            NuevoEstado = Estado#{espera := queue:from_list(NuevaLista)},
            ok = p17_eventos:registrar_evento(#{
                evento => jugador_retirado_de_espera,
                severidad => info,
                jugador => Jugador
            }),
            {reply, ok, NuevoEstado}
    end;

handle_call(estado, _From, Estado) ->
    Espera = queue:to_list(maps:get(espera, Estado)),
    Jugadores = [maps:get(jugador, Entrada) || Entrada <- Espera],
    PartidasActivas = p17_partidas_sup:partidas(),
    Respuesta = #{
        jugadores_en_espera => Jugadores,
        cantidad_en_espera => length(Jugadores),
        partidas_activas => length(PartidasActivas)
    },
    {reply, Respuesta, Estado};

handle_call(_Solicitud, _From, Estado) ->
    {reply, {error, solicitud_desconocida}, Estado}.

handle_cast(_Mensaje, Estado) ->
    {noreply, Estado}.

handle_info(_Mensaje, Estado) ->
    {noreply, Estado}.

agregar_o_emparejar(Jugador, ClientePid, Espera, Estado) ->
    case queue:out(Espera) of
        {empty, _} ->
            Entrada = #{jugador => Jugador, cliente => ClientePid},
            NuevaEspera = queue:in(Entrada, Espera),
            NuevoEstado = Estado#{espera := NuevaEspera},
            ok = p17_eventos:registrar_evento(#{
                evento => jugador_en_espera,
                severidad => info,
                jugador => Jugador
            }),
            {reply, {esperando, 1}, NuevoEstado};

        {{value, Oponente}, Resto} ->
            emparejar(Jugador, ClientePid, Oponente, Resto, Estado)
    end.

emparejar(Jugador, ClientePid, Oponente, Resto, Estado) ->
    JugadorOponente = maps:get(jugador, Oponente),
    ClienteOponente = maps:get(cliente, Oponente),
    case p17_partidas_sup:iniciar_partida_con_id(
        JugadorOponente,
        Jugador
    ) of
        {ok, Id, PartidaPid} ->
            notificar_jugadores(
                ClienteOponente,
                ClientePid,
                PartidaPid,
                JugadorOponente,
                Jugador
            ),
            ok = p17_eventos:registrar_evento(#{
                evento => jugadores_emparejados,
                severidad => info,
                id => Id,
                jugadores => [JugadorOponente, Jugador]
            }),
            NuevoEstado = Estado#{espera := Resto},
            Respuesta = {partida_iniciada, PartidaPid, Jugador, JugadorOponente},
            {reply, Respuesta, NuevoEstado};

        Error ->
            EsperaRestaurada = queue:in_r(Oponente, Resto),
            NuevoEstado = Estado#{espera := EsperaRestaurada},
            {reply, {error, {no_se_pudo_iniciar_partida, Error}}, NuevoEstado}
    end.

notificar_jugadores(
    ClienteOponente,
    ClienteActual,
    PartidaPid,
    JugadorOponente,
    JugadorActual
) ->
    ClienteOponente !
        {partida_iniciada, PartidaPid, JugadorOponente, JugadorActual},
    ClienteActual !
        {partida_iniciada, PartidaPid, JugadorActual, JugadorOponente},
    ok.

ya_esta_en_espera(Jugador, JugadoresEnEspera) ->
    lists:any(
        fun(Entrada) ->
            maps:get(jugador, Entrada) =:= Jugador
        end,
        JugadoresEnEspera
    ).
