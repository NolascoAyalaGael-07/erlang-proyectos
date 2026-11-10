-module(p17_servidor_de_juego_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    Hijos = [
        #{
            id => p17_eventos,
            start => {p17_eventos, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [p17_eventos]
        },
        #{
            id => p17_servidor_de_juego_server,
            start => {p17_servidor_de_juego_server, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [p17_servidor_de_juego_server]
        },
        #{
            id => p17_partidas_sup,
            start => {p17_partidas_sup, start_link, []},
            restart => permanent,
            shutdown => infinity,
            type => supervisor,
            modules => [p17_partidas_sup]
        },
        #{
            id => p17_matchmaking,
            start => {p17_matchmaking, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [p17_matchmaking]
        },
        #{
            id => p17_http_server,
            start => {p17_http_server, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [p17_http_server]
        }
    ],
    {ok, {#{strategy => one_for_one, intensity => 10, period => 60}, Hijos}}.
