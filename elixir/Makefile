BEAMS=see.beam hello.beam lists.beam error_handler.beam

all: see.boot see $(BEAMS)

%.beam: %.ex
	elixirc $<

see.boot see: see.beam
	erl -s see make_scripts

clean:
	$(RM) $(BEAMS) see.boot

.PHONY: all clean
