-module(p17_ws_handler).
-behaviour(cowboy_websocket).

-export([init/2, websocket_init/1, websocket_handle/2, websocket_info/2]).

init(Req, _Opciones) ->
    {cowboy_websocket, Req, #{}}.

websocket_init(Estado) ->
    ok = p17_eventos:suscribir(),
    {ok, Estado}.

websocket_handle(_Frame, Estado) ->
    {ok, Estado}.

websocket_info({p17_eventos, Evento}, Estado) ->
    Mensaje = iolist_to_binary(p17_json:encode(Evento)),
    {reply, {text, Mensaje}, Estado};
websocket_info(_Mensaje, Estado) ->
    {ok, Estado}.
