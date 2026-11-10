#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

printf '\033[2J\033[H'
printf 'P17 — Servidor de juego Erlang/OTP\nDemostracion de codigo y pruebas\n'
sleep 3

printf '\n== Entorno de ejecucion ==\n'
sed -n '1,2p' /etc/os-release
uname -r

printf '\n== Entorno Erlang/OTP ==\n'
erl -noshell -eval 'io:format("OTP ~s~n", [erlang:system_info(otp_release)]), halt().'
rebar3 --version

printf '\033[2J\033[H'
printf '== Estado de una partida: gen_statem ==\n'
sed -n '18,37p' src/p17_partida.erl
sleep 8

printf '\033[2J\033[H'
printf '== Validacion de turno y posicion ==\n'
sed -n '43,70p' src/p17_partida.erl
sleep 8

printf '\033[2J\033[H'
printf '== Supervisor raiz: aislamiento one_for_one ==\n'
sed -n '9,55p' src/p17_servidor_de_juego_sup.erl
sleep 8

printf '\033[2J\033[H'
printf '== Partidas dinamicas con reinicio temporary ==\n'
sed -n '22,39p' src/p17_partidas_sup.erl
sleep 8

printf '\033[2J\033[H'
printf '== Rutas HTTP, metricas y WebSocket ==\n'
sed -n '10,24p' src/p17_http_server.erl
sleep 6

printf '\033[2J\033[H'
printf '\n== Pruebas automatizadas ==\n'
rebar3 eunit
sleep 5

printf '\033[2J\033[H'
printf '\n== Salud HTTP ==\n'
curl --fail --silent --show-error http://127.0.0.1:8080/health | python3 -m json.tool

printf '\n== Metricas HTTP ==\n'
curl --fail --silent --show-error http://127.0.0.1:8080/metrics | python3 -m json.tool
