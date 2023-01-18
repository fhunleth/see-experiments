# Simple Execution Environment (SEE) experiments

This repository has a simple test application from [Joe Armstrong's Programming
Erlang 2nd Edition](http://pragprog.com/book/jaerlang2/programming-erlang).

Unlike every other use of Erlang and Elixir, SEE doesn't load OTP. As a result,
it is about the smallest and fastest loading Erlang app possible.

To try it out, install `erlang` and run:

```sh
$ make
$ ./see hello
Hello, World!
```

## Example benchmark run

Install [hyperfine](https://github.com/sharkdp/hyperfine) first and then:

```sh
$ make bench
hyperfine "erl -eval 'halt()'" "erl -boot ./see -environment '' -load hello" "python3 -c 'exit()'" "ruby -e 'exit'" --warmup 10
Benchmark 1: erl -eval 'halt()'
  Time (mean ± σ):     339.6 ms ±  14.5 ms    [User: 253.5 ms, System: 97.8 ms]
  Range (min … max):   316.3 ms … 366.0 ms    10 runs

Benchmark 2: erl -boot ./see -environment '' -load hello
  Time (mean ± σ):     132.6 ms ±  12.7 ms    [User: 114.4 ms, System: 67.1 ms]
  Range (min … max):   115.3 ms … 153.6 ms    21 runs

Benchmark 3: python3 -c 'exit()'
  Time (mean ± σ):      23.0 ms ±   4.4 ms    [User: 17.9 ms, System: 5.1 ms]
  Range (min … max):    13.0 ms …  31.2 ms    212 runs

Benchmark 4: ruby -e 'exit'
  Time (mean ± σ):     147.3 ms ±  14.5 ms    [User: 137.8 ms, System: 33.3 ms]
  Range (min … max):   108.1 ms … 160.4 ms    18 runs

Summary
  'python3 -c 'exit()'' ran
    5.76 ± 1.23 times faster than 'erl -boot ./see -environment '' -load hello'
    6.39 ± 1.38 times faster than 'ruby -e 'exit''
   14.74 ± 2.89 times faster than 'erl -eval 'halt()''
```

