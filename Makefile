BEAMS=see.beam hello.beam lists.beam error_handler.beam

all: see.boot see $(BEAMS)

%.beam: %.erl
	erlc $<

see.boot see: see.beam
	erl -s see make_scripts

bench: see.boot $(BEAMS)
	hyperfine "erl -eval 'halt()'" "erl -boot ./see -environment '' -load hello" "python3 -c 'exit()'" "ruby -e 'exit'" --warmup 10

clean:
	$(RM) $(BEAMS) see.boot

.PHONY: all clean
