ERL=$(shell asdf which erl)

all:
	$(MAKE) -C erlang all
	$(MAKE) -C c all

bench: all
	hyperfine "$(ERL) -eval 'halt()'" "$(ERL) -boot ./erlang/see -environment '' -load hello" "python3 -c 'exit()'" "./c/minimal_c" --warmup 20

clean:
	$(MAKE) -C erlang clean

.PHONY: all bench clean
