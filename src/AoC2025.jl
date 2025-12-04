module AoC2025

using Printf: @sprintf
using StringViews: StringView
using MemoryViews: ImmutableMemoryView, MemoryView, split_at

struct Day
    # Values are between 1:12
    x::UInt8

    global unsafe_day(x::UInt8) = new(x)
end

"""
    @nota T expr

Expands to `return expr` if `expr isa T`, else `expr`.
Useful for early return of error values.
"""
macro nota(T, expr)
    return quote
        local res = $(esc(expr))
        isa(res, $(T)) ? (return res) : res
    end
end

Base.isless(x::Day, y::Day) = isless(x.x, y.x)
Base.print(io::IO, x::Day) = print(io, "day ", x.x)
padded(x::Day) = "Day " * (x.x < 10 ? " " : "") * string(x.x)

function Base.tryparse(::Type{Day}, s::AbstractString)
    u = @something tryparse(UInt8, s) return nothing
    u in 1:12 || return nothing
    return unsafe_day(u)
end

struct InputError
    # Line number, if the error happens at a specific line
    line::Union{Int, Nothing}
end

function show_and_exit(day::Day, err::InputError)::Union{}
    s = "Error when parsing input for " * string(day)
    lineno = err.line
    if lineno !== nothing
        s *= " on line " * string(lineno)
    end
    return exit_with(s)
end

include("utils.jl")
include("day1.jl")
include("day2.jl")
include("day3.jl")
include("day4.jl")

struct Solution
    # We store the solutions as strings, since we just need to print them,
    # and since Julia doesn't yet allow having boxed "printeable" objects
    # in trimmed code
    p1::String
    p2::String
    time::Float64
end

# A better solution here would be to store a map from the day to the related solver.
# However, this is not possible in trimmed Julia, because that makes the function call
# non-static.
const SOLVED_DAYS = [unsafe_day(i) for i in 0x01:0x04]

struct Unimplemented end

function solve(day::Day, data::ImmutableMemoryView{UInt8})::Union{Unimplemented, Solution, InputError}
    start = time()
    x = day.x
    ps = if x == 1
        Day1.solve(data)
    elseif x == 2
        Day2.solve(data)
    elseif x == 3
        Day3.solve(data)
    elseif x == 4
        Day4.solve(data)
    else
        return Unimplemented()
    end
    return if ps isa InputError
        ps
    else
        delta = time() - start
        Solution(ps[1], ps[2], delta)
    end
end

function time_string(delta::Float64)::String
    (prefix, number) = if delta < 0.001
        ("μ", delta * 1_000_000)
    elseif delta < 1
        ("m", delta * 1_000)
    else
        ("", delta)
    end
    s = @sprintf "%.3g" number
    return s * ' ' * prefix * 's'
end

function exit_with(s::String, errorcode::Int = 1)::Union{}
    #throw(s)
    println(Core.stderr, s)
    return exit(errorcode)
end

function load_day_data(data_dir::String, days::Vector{Day})::Vector{@NamedTuple{day::Day, data::Union{Nothing, Vector{UInt8}}}}
    T = @NamedTuple{day::Day, data::Union{Nothing, Vector{UInt8}}}
    return map(days) do day
        day ∈ SOLVED_DAYS || return T((day, nothing))
        filename = let
            day_string = string(day.x)
            day_string = ncodeunits(day_string) < 2 ? '0' * day_string : day_string
            "day" * day_string * ".txt"
        end
        filepath = joinpath(data_dir, filename)
        isfile(filepath) || exit_with("No data file at expected path: \"" * filepath * '"')
        T((day, read(filepath)))
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

struct CLArgs
    data_dir::String
    days::Vector{Day}
end

function parse_args(args::Vector{String})::CLArgs
    check_for_help(args)
    days = parse_days(args[2:end])
    data_dir = args[1]
    if !isdir(data_dir)
        exit_with("Data directory is not an existing directory: \"" * data_dir * '"')
    end
    return CLArgs(data_dir, days)
end

function check_for_help(args::Vector{String})
    return if isempty(args) || any(i -> (i == "--help" || i == "-h"), args)
        exit_with(USAGE, 0)
    end
end

function parse_days(rest_args::Vector{String})::Vector{Day}
    isempty(rest_args) && return SOLVED_DAYS
    days = map(rest_args) do s
        @something tryparse(Day, s) exit_with("Cannot parse as day: \"" * s * "\", must be in 1-12")
    end
    return unique!(sort!(days))
end

function (@main)(ARGS::Vector{String})
    args = parse_args(ARGS)
    data = load_day_data(args.data_dir, args.days)
    solutions = map(data) do day_data
        maybe_data = day_data.data
        solution = if isnothing(maybe_data)
            Unimplemented()
        else
            solution = solve(day_data.day, ImmutableMemoryView(maybe_data))
            solution isa InputError ? show_and_exit(day_data.day, solution) : solution
        end
        @NamedTuple{day::Day, solution::Union{Unimplemented, Solution}}((day_data.day, solution))
    end
    for (; day, solution) in solutions
        if solution === Unimplemented()
            println(Core.stdout, padded(day), ": Not yet implemented!")
        else
            println(Core.stdout, padded(day), " [", time_string(solution.time), "]:")
            println(Core.stdout, "  Part 1: ", solution.p1)
            println(Core.stdout, "  Part 2: ", solution.p2)
        end
        println(Core.stdout)
    end
    return 0
end

end # module AoC2025
