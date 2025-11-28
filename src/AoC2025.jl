module AoC2025

using Printf: @sprintf
using StringViews: StringView
using MemoryViews: ImmutableMemoryView, MemoryView

include("util.jl")
include("day1.jl")

struct Day
    # Values is between 1:12
    x::UInt8

    global function unsafe_day(x::UInt8)
        new(x)
    end 
end

Base.isless(x::Day, y::Day) = isless(x.x, y.x)
Base.print(io::IO, x::Day) = print(io, "Day ", x.x)

function printed(x::Day)
    s = string(x.x)
    s = x.x < 0x0a ? ' ' * s : s
    return "Day " * s
end

function Base.tryparse(::Type{Day}, s::AbstractString)::Union{Day, Nothing}
    u = @something tryparse(UInt8, s) return nothing
    u in 1:12 || return nothing
    return unsafe_day(u)
end

function parse_or_exit(::Type{Day}, s::AbstractString)::Day
    @something tryparse(Day, s) exit_with("Cannot parse as Day: '" * s * ''')
end

struct InputError
    line::Union{Int, Nothing}
end

function show_and_exit(day::Day, err::InputError)::Union{}
    s = "Error: Input when parsing data for ", string(day)
    lineno = err.line
    if lineno !== nothing
        s *= " on line " * string(lineno)
    end
    println(Core.stderr, s)
    exit(1)
end

struct Solution
    p1::String
    p2::String
    time::Float64
end

const SOLVED_DAYS = [unsafe_day(i) for i in 0x01:0x01]

function solve(day::Day, data::ImmutableMemoryView{UInt8})::Union{Nothing, Solution, InputError}
    start = time()
    x = day.x
    ps = if x == 1
        Day1.solve(data)
    else
        nothing
    end
    if ps === nothing
        nothing
    elseif ps isa InputError
        return ps
    else
        delta = time() - start
        Solution(ps[1], ps[2], delta)
    end
end

function time_string(delta::Float64)::String
    (prefix, base) = if delta < 0.001
        ("μ", delta * 1_000_000)
    elseif delta < 1
        ("m", delta * 1_000)
    else
        ("", delta)
    end
    s = @sprintf "%.3g" base
    return s * ' ' * prefix * 's'
end

function exit_with(s::String)
    println(Core.stderr, s)
    exit(1)
end

function parse_days(rest_args::Vector{String})::Vector{Day}
    isempty(rest_args) && return SOLVED_DAYS
    unique!(sort!(map(s -> parse_or_exit(Day, s), rest_args)))
end

function load_days(data_dir::String, days::Vector{Day})::Vector{Union{Nothing, Vector{UInt8}}}
    map(days) do day
        day ∈ SOLVED_DAYS || return nothing
        filename = let
            day_string = string(day.x)
            day_string = ncodeunits(day_string) < 2 ? '0' * day_string : day_string
            "day" * day_string * ".txt"
        end
        filepath = joinpath(data_dir, filename)
        isfile(filepath) || exit_with("Could not find day path: '" * filepath * ''')
        read(filepath)
    end
end

const USAGE = """
Solve Advent of Code 2025 in trimmed Julia

Usage: aoc2025 <DATA_DIR> [DAYS]...

Arguments:
  <DATA_DIR>  Directory with input data. Each file must be named e.g. "day01.txt"
  [DAYS]...   List of days to solve. If not passed, solve all implemented days.

Options:
  -h, --help  Print help
"""

function check_for_help(args::Vector{String})
    if isempty(args) || any(i -> (i == "--help" || i == "-h"), args)
        print(Core.stderr, USAGE)
        exit(0)
    end
end

function @main(ARGS::Vector{String})
    check_for_help(ARGS)
    days = parse_days(ARGS[2:end])
    if !isdir(ARGS[1])
        exit_with("Data directory is not an existing directory: \"" * ARGS[1] * '"')
    end
    data = load_days(ARGS[1], days)
    @assert length(data) == length(days)
    solutions = map(zip(days, data)) do ((day, day_data))
        solution = if isnothing(day_data)
            nothing
        else
            solution = solve(day, ImmutableMemoryView(day_data))
            solution isa InputError ? show_and_exit(day, solution) : solution
        end
        @NamedTuple{day::Day, solution::Union{Nothing, Solution}}((day, solution))
    end
    for (;day, solution) in solutions
        if isnothing(solution)
            println(Core.stdout, printed(day), ": Not yet implemented!")
        else
            println(Core.stdout, printed(day), " [", time_string(solution.time), "]:")
            println(Core.stdout, "  Part 1: ", solution.p1)
            println(Core.stdout, "  Part 2: ", solution.p2)
        end
        println(Core.stdout)
    end
    return 0
end

end # module AoC2025
