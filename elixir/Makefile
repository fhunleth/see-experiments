BEAMS=see.beam hello.beam lists.beam error_handler.beam

all: see.boot see $(BEAMS)

%.beam: %.ex
	elixirc $<

%.beam: %.erl
	erlc $<

see.boot see: Elixir.See.beam
	erl -s Elixir.See make_scripts

clean:
	$(RM) $(BEAMS) see.boot

.PHONY: all clean
