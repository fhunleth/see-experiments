-module(hello).
-export([main/0]).

main() ->
    see:write("Hello, World!\n").
