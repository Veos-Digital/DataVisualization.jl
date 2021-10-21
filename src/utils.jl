colnames(table) = collect(map(String, Tables.columnnames(table)))

vecmap(f, iter) = [f(el) for el in iter]

function data_options(session::Session, t::Observable; keywords=[""])
    return map(session, t; result=Observable{AutocompleteOptions}()) do table
        names = colnames(table)
        return [keyword => names for keyword in keywords]
    end
end

function to_littledict(data)
    cols = Tables.columns(data)
    names = collect(Symbol, Tables.columnnames(cols))
    columns = AbstractVector[Tables.getcolumn(cols, colname) for colname in names]
    return LittleDict{Symbol, AbstractVector}(names, columns)
end

iscontinuous(v::AbstractVector) = false
iscontinuous(v::AbstractVector{<:Number}) = true
iscontinuous(v::AbstractVector{<:Bool}) = false

function buttonclass(positive)
    class = "text-xl font-semibold rounded text-left py-2 px-4 bg-opacity-75"
    class *= positive ? " bg-blue-100 hover:bg-blue-200 text-blue-800 hover:text-blue-900 mr-8" :
        " bg-red-100 hover:bg-red-200 text-red-800 hover:text-red-900"
    return class
end

struct Call
    fs::Vector{String}
    positional::Vector{String}
    named::Vector{Pair{String, String}}
end

Call() = Call(String[], String[], Pair{String, String}[])

function compute_calls(str::AbstractString)
    calls, call = Call[], Call()
    for chunk in split(str, ' ')
        isempty(chunk) && continue
        s = split(chunk, ':')
        if length(s) == 1
            if only(s) == "+"
                push!(calls, call)
                call = Call()
            else
                push!(call.fs, only(s))
            end
        else
            pre, post = s
            positional, named = call.positional, call.named
            isempty(pre) ? push!(positional, post) : push!(named, pre => post)
        end
    end
    push!(calls, call)
    return calls
end

function tryon(f, session::Session, obs::Observable)
    error_msg = Observable("")
    onjs(session, error_msg, js"""
        function (value) {
            alert(value);
        }
    """)
    return on(session, obs) do val
        try
            f(val)
        catch err
            io = IOBuffer()
            print(io, "Could not complete command due to the following error.")
            print(io, "\n\n")
            print(io, err)
            error_msg[] = String(take!(io))
        end
    end
end

function with_tabular(widget, table)
    return DOM.div(
        class="grid grid-cols-3 gap-32 h-full",
        DOM.div(class="col-span-1", widget),
        DOM.div(class="col-span-2", DOM.div(Tabular(table)))
    )
end