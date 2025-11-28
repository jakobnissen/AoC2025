# AoC2025
Solve [Advent of Code 2025](https://adventofcode.com/2025) with a single, trimmed Julia binary app.

> [!WARNING]
> Please note that trimming as of the time of writing is experimental in Julia, and hence this application is
> fairly primitive and feature-anemic compared to a binary from a proper static language like Rust.

## Installation
* [Install Julia](https://julialang.org/downloads/) if you haven't already 
* Install the JuliaC compiler app with this shell command: `julia --startup=no -e 'using Pkg; Pkg.Apps.add("JuliaC")'`
* Verify JuliaC by trying out `juliac -h`, else check your PATH environmental variable.
* Clone this repository and navitage to it
* Compile the binary with `juliac --output-exe aoc2025 --bundle build --trim=safe --experimental .`

## Usage
* Download your input files to a directory, and save the files with the names `dayDD.txt`, where `DD` signifies the zero-padded day number. Example: `day03.txt`, `day11.txt`.
* Run the binary with `./build/bin/aoc2025 <DATADIR> [DAYS]...`

## Example
```
$ ./build/bin/aoc2025 data # all implemented days
Day  1 [289 μs]:
  Part 1: 3574690
  Part 2: 22565391

Day  2 [210 µs]:
  Part 1: 279
  Part 2: 343

$ ./build/bin/aoc2025 data 2 # one or more selected days
Day  2 [209 µs]:
  Part 1: 279
  Part 2: 343

$ ./build/bin/aoc2025 --help
Solve Advent of Code 2025 in trimmed Julia

Usage: aoc2025 <DATA_DIR> [DAYS]...

Arguments:
  <DATA_DIR>  Directory with input data. Each file must be named e.g. "day01.txt"
  [DAYS]...   List of days to solve. If not passed, solve all implemented days.

Options:
  -h, --help  Print help
```