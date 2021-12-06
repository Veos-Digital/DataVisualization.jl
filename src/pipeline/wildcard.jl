struct WildCard{T}
    table::Observable{T}
    code::Observable{String}
    value::Observable{T}
end

function WildCard(table::Observable{T}) where T
    code = Observable{String}("")
    private_module = Module()
    value = map(table, code) do table, code
        @eval private_module begin
            input = $table
            $(Meta.parse(code))
        end
        output::T = to_littledict(private_module.output)
        return output
    end
    return WildCard(table, code, value)
end