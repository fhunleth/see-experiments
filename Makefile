ERL=$(shell asdf which erl)

all:
	$(MAKE) -C elixir all
	$(MAKE) -C erlang all
	$(MAKE) -C c all

# Don't bother benchmarking C since it's too fast.
#   "./c/minimal_c"

bench: all
	hyperfine "$(ERL) -eval 'halt()'" \
			  "$(ERL) -boot ./erlang/see -environment '' -load hello" \
			  "$(ERL) -boot ./elixir2/see -environment '' -load Elixir.Hello" \
			  "python3 -c 'exit()'" \
			  --warmup 20

clean:
	$(MAKE) -C erlang clean

.PHONY: all bench clean
