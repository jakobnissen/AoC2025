module Day10

using MemoryViews: ImmutableMemoryView, split_each
using BufferIO: line_views
using StringViews: StringView

import ..@nota, ..InputError, ..Unimplemented

function solve(mem::ImmutableMemoryView{UInt8})
    problems = parse(mem)
    p1 = 0
    for problem in problems
        p1 += solve_p1(problem)
    end
    return (p1, Unimplemented())
end

struct Problem
    # Number of lights in indicator
    n_lights::UInt32
    # Bits from bottom to top indicates whether the lights from left to right
    # should be switched on to start the machine
    configuration::UInt32
    # Each button is a bitmask, where a bit shows which light is toggled.
    # Order is the same as in the configuration, so pushing the button is computed
    # by xor'ing the button with the current light state.
    buttons::Vector{UInt32}
    # Target joltages, where first index indicates the joltage of the light in the lowest
    # bit in `configuration`.
    joltages::Vector{UInt32}
end

function solve_p1(problem::Problem)
    # We can push each button at most one, because pushing it twice will be the same
    # as not pushing it.
    # Hence, all possible button press sequences can be encoded as a bitvector.
    # Here, I encoded it as a bitfield in a number with a 1 at position N
    # from lowest to highest bit indicating a push of the Nth button.
    smallest_pushes = length(problem.buttons)
    for sequence in 0:((1 << length(problem.buttons)) - 1)
        pushes = count_ones(sequence)
        # No need to check solutions worse than what we already have
        pushes ≥ smallest_pushes && continue
        state = problem.configuration
        # Loop over all digits in sequence by clearing bits right to left
        while !iszero(sequence)
            state ⊻= @inbounds problem.buttons[trailing_zeros(sequence) + 1]
            # This bit-trick clears least significant bit
            sequence &= sequence - one(sequence)
        end
        if iszero(state)
            smallest_pushes = pushes
        end
    end
    return smallest_pushes
end

function parse(mem::ImmutableMemoryView{UInt8})
    result = Problem[]
    # One problem per line
    for (line_number, line) in enumerate(line_views(mem))
        # We handle trailing or leading whitespace
        line = codeunits(strip(StringView(line)))

        # Find first and last space, which separates indicator lights, buttons and joltages
        p1 = findfirst(==(UInt8(' ')), line)
        isnothing(p1) && return InputError(line_number, "No space in line")
        p2 = something(findlast(==(UInt8(' ')), line))
        p1 < p2 || return InputError(line_number, "Not >2 space-separated blocks")

        # Parse indicator lights, buttons and joltages one by one.
        (configuration, n_lights) = @nota InputError parse_indicator_lights(@inbounds(line[1:(p1 - 1)]), line_number)
        buttons = @nota InputError parse_buttons(@inbounds(line[(p1 + 1):(p2 - 1)]), line_number, Int(n_lights))
        joltages = @nota InputError parse_joltages(@inbounds(line[(p2 + 1):end]), line_number, Int(n_lights))
        push!(result, Problem(n_lights, configuration, buttons, joltages))
    end
    return result
end

# Example: "[..###.#]"
function parse_indicator_lights(mem::ImmutableMemoryView{UInt8}, line_num::Int)
    length(mem) < 3 && return InputError(line_num, "Indicator must be > 2 characters")
    length(mem) > 34 && return InputError(line_num, "Indicator must be at most 32 lights")
    if @inbounds(first(mem)) != UInt8('[') || @inbounds(last(mem)) != UInt8(']')
        return InputError(line_num, "Indicator lights must be in square brackets ([])")
    end
    # Strip brackets
    mem = @inbounds mem[2:(end - 1)]

    # Each ASCII char (byte) indicates an indicator light state (true or false)
    n_lights = length(mem) % UInt32
    configuration = UInt32(0)
    for i in eachindex(mem)
        byte = @inbounds mem[i]
        val = if byte == UInt8('#')
            UInt32(1)
        elseif byte == UInt8('.')
            UInt32(0)
        else
            return InputError(line_num, "Invalid character in indicator lights, must be '.' or '#'")
        end
        configuration |= (val << ((i - 1) & 31))
    end
    return (configuration, n_lights)
end

# Example: "(1,3,0) (1,5,2)"
function parse_buttons(mem::ImmutableMemoryView{UInt8}, line_num::Int, n_lights::Int)
    buttons = UInt32[]
    # Buttons are separated by space
    for tuple_mem in split_each(mem, UInt8(' '))
        isempty(tuple_mem) && continue
        # Must be at least "(1)", so 3 bytes
        length(tuple_mem) < 3 && return InputError(line_num, "Button is malformed or activates no lights")
        if @inbounds(first(tuple_mem)) != UInt8('(') || @inbounds(last(tuple_mem)) != UInt8(')')
            return InputError(line_num, "Button must be in parentheses")
        end
        button = UInt32(0)
        # Strip parenthesis, then split by , to get each integer
        for number_mem in split_each(@inbounds(tuple_mem[2:(end - 1)]), UInt8(','))
            n = tryparse(UInt32, StringView(number_mem))
            if isnothing(n) || n ≥ n_lights
                return InputError(line_num, "Button is not a parseable int in 0:<n indicator lights>")
            end
            set_bit = UInt32(1) << (n & 31)
            iszero(button & set_bit) || return InputError(line_num, "Button activates same light more than once")
            button |= set_bit
        end
        push!(buttons, button)
    end
    isempty(length(buttons)) && return InputError(line_num, "Must have at least one button")
    return buttons
end

# Example: "{12,6,12}"
function parse_joltages(mem::ImmutableMemoryView{UInt8}, line_num::Int, n_lights::Int)
    # Each indicator light must have exactly one joltage.
    joltages = Vector{UInt32}(undef, n_lights)
    # Minimum: "{1}", so 3 bytes
    length(mem) < 3 && return InputError(line_num, "Joltage list must have at least one element")
    if @inbounds(first(mem)) != UInt8('{') || @inbounds(last(mem)) != UInt8('}')
        return InputError(line_num, "Joltages must be in curly brackets")
    end
    n_joltages = 0
    # Strip curly brackets from start and end, then split by , to parse each integer
    for joltage_mem in split_each(@inbounds(mem[2:(end - 1)]), UInt8(','))
        n_joltages += 1
        n_joltages > n_lights && @goto bad_num_joltages
        n = tryparse(UInt32, StringView(joltage_mem))
        isnothing(n) && return InputError(line_num, "Joltage not parseable as UInt32")
        @inbounds joltages[n_joltages] = n
    end
    n_joltages == n_lights || @goto bad_num_joltages
    return joltages
    @label bad_num_joltages
    return InputError(line_num, "Joltage list must have one joltage per indicator light")
end

end # module Day10
