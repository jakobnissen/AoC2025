module AoC2025

using Printf: @sprintf

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

function Base.tryparse(::Type{Day}, s::AbstractString)::Union{Day, Nothing}
    u = @something tryparse(UInt8, s) return nothing
    u in 1:12 || return nothing
    return unsafe_day(u)
end

function parse_or_exit(::Type{Day}, s::AbstractString)::Day
    @something tryparse(Day, s) exit_with("Cannot parse as Day: '" * s * ''')
end

struct Solution
    p1::String
    p2::String
    time::Float64
end

function solve(day::Day, data::String)::Union{Nothing, Solution}
    start = time()
    x = day.x
    ps = if x == 1
        Day1.solve(data)
    else
        nothing
    end
    if ps === nothing
        nothing
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
    if isempty(rest_args)
        return map(unsafe_day, 0x01:UInt8(1))
    else
        v = map(rest_args) do daystring
            parse_or_exit(Day, daystring)
        end
        sort!(v; by=i -> i.x)
        unique!(v)
    end
end

function load_days(data_dir::String, days::Vector{Day})
    map(days) do day
        filename = let
            day_string = string(day.x)
            day_string = ncodeunits(day_string) < 2 ? '0' * day_string : day_string
            "day" * day_string * ".txt"
        end
        filepath = joinpath(data_dir, filename)
        isfile(filepath) || exit_with("Could not find day path: '" * filepath * ''')
        read(filepath, String)
    end
end

function @main(ARGS)
    if length(ARGS) < 1
        exit_with("Usage: aoc2025 DATADIR [DAYS...]")
    end
    days = parse_days(ARGS[2:end])
    if !isdir(ARGS[1])
        exit_with("Data directory is not an existing dir: " * ARGS[1])
    end
    data = load_days(ARGS[1], days)
    for i in eachindex(days, data)
        day = days[i]
        solution = something(solve(day, data[i]))
        println(Core.stdout, day, ": ", time_string(solution.time))
        println(Core.stdout, "  p1: ", solution.p1)
        println(Core.stdout, "  p2: ", solution.p2)
    end
    return 0
end

end # module AoC2025
