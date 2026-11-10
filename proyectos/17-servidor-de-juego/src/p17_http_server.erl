-module(p17_http_server).
-behaviour(gen_server).

-export([start_link/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init([]) ->
    Rutas = cowboy_router:compile([
        {'_', [
            {"/", p17_http_handler, inicio},
            {"/admin", p17_http_handler, admin_dashboard},
            {"/admin-stitch.js", p17_http_handler, admin_stitch_js},
            {"/api/admin", p17_http_handler, admin_api},
            {"/api/admin/eventos", p17_http_handler, admin_events_api},
            {"/metrics", p17_http_handler, metrics},
            {"/ws/juego", p17_ws_handler, #{}},
            {"/health", p17_http_handler, health},
            {"/api/partidas/:id/movimientos", p17_http_handler, movimiento},
            {"/api/partidas/:id", p17_http_handler, partida},
            {"/api/partidas", p17_http_handler, partidas}
        ]}
    ]),
    Opciones = #{env => #{dispatch => Rutas}},
    Puerto = application:get_env(p17_servidor_de_juego, http_port, 8080),
    case cowboy:start_clear(http_listener, [{port, Puerto}], Opciones) of
        {ok, _ListenerPid} ->
            {ok, #{}};
        {error, Razon} ->
            {stop, {no_se_pudo_iniciar_http, Razon}}
    end.

handle_call(_Solicitud, _Desde, Estado) ->
    {reply, {error, solicitud_no_soportada}, Estado}.

handle_cast(_Mensaje, Estado) ->
    {noreply, Estado}.

handle_info(_Mensaje, Estado) ->
    {noreply, Estado}.

terminate(_Razon, _Estado) ->
    _ = cowboy:stop_listener(http_listener),
    ok.