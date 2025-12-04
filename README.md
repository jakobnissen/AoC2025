# AoC2025
Solve [Advent of Code 2025](https://adventofcode.com/2025) with a single, trimmed Julia binary app.

> [!WARNING]
> Please note that trimming as of the time of writing is experimental in Julia, and hence this application is
> fairly primitive and feature-anemic compared to a binary from a proper static language like Rust.

## Installation
* [Install Julia](https://julialang.org/downloads/) if you haven't already 
* Install the JuliaC compiler app with this shell command: `julia --startup=no -e 'using Pkg; Pkg.Apps.add("JuliaC")'`
* Verify JuliaC is installed by trying out `juliac -h` in your shell. If it fails, check your PATH environmental variable contains `$HOME/.julia/bin`.
* Clone this repository and navitage to it
* Compile the binary with `juliac --output-exe aoc2025 --bundle build --trim=safe --experimental .`
* The binary is now in `build/bin/aoc2025`. Note that the binary relies on loading the libraries in `build/lib` using a relative path from the binary, and as such, the whole `build` directory must be moved in order to move the binary. 

## Usage
* Download your input files to a directory, and save the files with the names `dayDD.txt`, where `DD` signifies the zero-padded day number. Example: `day03.txt`, `day11.txt`.
* Run the binary with `./build/bin/aoc2025 <DATADIR> [DAYS]...`

## Example
```
$ ./build/bin/aoc2025 data # all implemented days
Day  1 [188 μs]:
  Part 1: 1158
  Part 2: 6860

Day  2 [36 μs]:
  Part 1: 20052980082
  Part 2: 20077272987

$ ./build/bin/aoc2025 data 2 # one or more selected days
Day  2 [38.1 μs]:
  Part 1: 20052980082
  Part 2: 20077272987

$ ./build/bin/aoc2025 --help
Solve Advent of Code 2025 in trimmed Julia

Usage: aoc2025 <DATA_DIR> [DAYS]...

Arguments:
  <DATA_DIR>  Directory with input data. Each file must be named e.g. "day01.txt"
  [DAYS]...   List of days to solve. If not passed, solve all implemented days.

Options:
  -h, --help  Print help
```
