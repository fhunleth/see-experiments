BEAMS=Elixir.Hello.beam Elixir.See.beam lists.beam error_handler.beam

all: see.boot see $(BEAMS)

Elixir.Hello.beam: hello.ex
	elixirc $<
Elixir.See.beam: see.ex
	elixirc $<
lists.beam: lists.erl
	erlc $<
error_handler.beam: error_handler.ex
	elixirc $<

see.boot see: Elixir.See.beam
	erl -s Elixir.See make_scripts

clean:
	$(RM) $(BEAMS) see.boot

.PHONY: all clean
