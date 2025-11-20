# Simple Execution Environment (SEE) experiments

This repository has a simple test application from [Joe Armstrong's Programming
Erlang 2nd Edition](http://pragprog.com/book/jaerlang2/programming-erlang).

Unlike every other use of Erlang and Elixir, SEE doesn't load OTP. As a result,
it is about the smallest and fastest loading Erlang app possible.

To try it out, install `erlang` and run:

```sh
$ cd erlang
$ make
$ ./see hello
Hello, World!
```

Or try it in Elixir with:

```sh
$ cd elixir
$ make
$ ./see Elixir.Hello
Hello, World!
```

## Example benchmark run

**These results are dated now. Rerun before making conclusions**

Install [hyperfine](https://github.com/sharkdp/hyperfine) first and then:

```sh
$ make bench
hyperfine "/home/fhunleth/.asdf/installs/erlang/25.2/bin/erl -eval 'halt()'" "/home/fhunleth/.asdf/installs/erlang/25.2/bin/erl -boot ./see -environment '' -load hello" "python3 -c 'exit()'" "/usr/bin/ruby -e 'exit'" --warmup 20
Benchmark 1: /home/fhunleth/.asdf/installs/erlang/25.2/bin/erl -eval 'halt()'
  Time (mean ± σ):     265.8 ms ±  16.5 ms    [User: 175.5 ms, System: 83.5 ms]
  Range (min … max):   245.0 ms … 299.3 ms    11 runs

Benchmark 2: /home/fhunleth/.asdf/installs/erlang/25.2/bin/erl -boot ./see -environment '' -load hello
  Time (mean ± σ):      52.1 ms ±  10.3 ms    [User: 39.0 ms, System: 38.1 ms]
  Range (min … max):    43.7 ms …  73.1 ms    65 runs

  Warning: Statistical outliers were detected. Consider re-running this benchmark on a quiet PC without any interferences from other programs. It might help to use the '--warmup' or '--prepare' options.

Benchmark 3: python3 -c 'exit()'
  Time (mean ± σ):      24.3 ms ±   2.4 ms    [User: 19.7 ms, System: 4.6 ms]
  Range (min … max):    12.9 ms …  28.2 ms    212 runs

  Warning: Statistical outliers were detected. Consider re-running this benchmark on a quiet PC without any interferences from other programs. It might help to use the '--warmup' or '--prepare' options.

Benchmark 4: /usr/bin/ruby -e 'exit'
  Time (mean ± σ):      48.6 ms ±   7.2 ms    [User: 39.4 ms, System: 9.2 ms]
  Range (min … max):    45.7 ms …  71.8 ms    63 runs

  Warning: Statistical outliers were detected. Consider re-running this benchmark on a quiet PC without any interferences from other programs. It might help to use the '--warmup' or '--prepare' options.

Summary
  'python3 -c 'exit()'' ran
    2.00 ± 0.36 times faster than '/usr/bin/ruby -e 'exit''
    2.14 ± 0.47 times faster than '/home/fhunleth/.asdf/installs/erlang/25.2/bin/erl -boot ./see -environment '' -load hello'
   10.93 ± 1.29 times faster than '/home/fhunleth/.asdf/installs/erlang/25.2/bin/erl -eval 'halt()''
```

