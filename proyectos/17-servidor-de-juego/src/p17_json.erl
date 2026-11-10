-module(p17_json).

-export([encode/1]).

encode(true) ->
    <<"true">>;
encode(false) ->
    <<"false">>;
encode(null) ->
    <<"null">>;
encode(undefined) ->
    <<"null">>;
encode(Valor) when is_binary(Valor) ->
    json_string(Valor);
encode(Valor) when is_integer(Valor) ->
    integer_to_binary(Valor);
encode(Valor) when is_float(Valor) ->
    float_to_binary(Valor, [short]);
encode(Valor) when is_atom(Valor) ->
    json_string(atom_to_binary(Valor, utf8));
encode(Valor) when is_list(Valor) ->
    Elementos = [encode(Elemento) || Elemento <- Valor],
    [<<"[">>, unir(Elementos), <<"]">>];
encode(Valor) when is_map(Valor) ->
    Pares = [
        [json_string(clave_binaria(Clave)), <<":">>, encode(Dato)]
        || {Clave, Dato} <- maps:to_list(Valor)
    ],
    [<<"{">>, unir(Pares), <<"}">>].

json_string(Texto) ->
    [<<"\"">>, escapar_json(Texto), <<"\"">>].

escapar_json(<<>>) ->
    [];
escapar_json(<<34, Resto/binary>>) ->
    [<<"\\\"">>, escapar_json(Resto)];
escapar_json(<<92, Resto/binary>>) ->
    [<<"\\\\">>, escapar_json(Resto)];
escapar_json(<<8, Resto/binary>>) ->
    [<<"\\b">>, escapar_json(Resto)];
escapar_json(<<9, Resto/binary>>) ->
    [<<"\\t">>, escapar_json(Resto)];
escapar_json(<<10, Resto/binary>>) ->
    [<<"\\n">>, escapar_json(Resto)];
escapar_json(<<12, Resto/binary>>) ->
    [<<"\\f">>, escapar_json(Resto)];
escapar_json(<<13, Resto/binary>>) ->
    [<<"\\r">>, escapar_json(Resto)];
escapar_json(<<Caracter, Resto/binary>>) when Caracter < 32 ->
    Hex1 = digito_hex(Caracter bsr 4),
    Hex2 = digito_hex(Caracter band 15),
    [[$\\, $u, $0, $0, Hex1, Hex2], escapar_json(Resto)];
escapar_json(<<Caracter, Resto/binary>>) ->
    [Caracter, escapar_json(Resto)].

digito_hex(Numero) when Numero < 10 ->
    $0 + Numero;
digito_hex(Numero) ->
    $A + Numero - 10.

clave_binaria(Clave) when is_atom(Clave) ->
    atom_to_binary(Clave, utf8);
clave_binaria(Clave) when is_binary(Clave) ->
    Clave;
clave_binaria(Clave) when is_integer(Clave) ->
    integer_to_binary(Clave).

unir([]) ->
    [];
unir([Elemento]) ->
    Elemento;
unir([Elemento | Resto]) ->
    [Elemento, <<",">>, unir(Resto)].
