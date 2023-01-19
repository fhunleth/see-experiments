BEAMS=see.beam hello.beam lists.beam error_handler.beam

ERL=$(shell asdf which erl)
RUBY=$(shell asdf which ruby)

all: see.boot see $(BEAMS)

%.beam: %.erl
	erlc $<

see.boot see: see.beam
	erl -s see make_scripts

bench: see.boot $(BEAMS)
	hyperfine "$(ERL) -eval 'halt()'" "$(ERL) -boot ./see -environment '' -load hello" "python3 -c 'exit()'" "$(RUBY) -e 'exit'" --warmup 20

clean:
	$(RM) $(BEAMS) see.boot

.PHONY: all clean
