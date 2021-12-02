colnames(table) = collect(map(String, Tables.columnnames(table)))

vecmap(f, iter) = [f(el) for el in iter]

function data_options(t::Observable; keywords=[""])
    return lift(t) do table
        names = colnames(table)
        return [keyword => names for keyword in keywords]
    end
end

# This simple untyped dictionary is the preferred way to store tables
function to_littledict(data)
    cols = Tables.columns(data)
    names = collect(Symbol, Tables.columnnames(cols))
    columns = AbstractVector[Tables.getcolumn(cols, colname) for colname in names]
    return LittleDict{Symbol, AbstractVector}(names, columns)
end

iscontinuous(v::AbstractVector) = false
iscontinuous(v::AbstractVector{<:Number}) = true
iscontinuous(v::AbstractVector{<:Bool}) = false

# convert to dict with fields `"keys"` and `"values"`, as it is the simplest way to share
# ordered associative containers with JavaScript
to_stringdict(p) = Dict("keys" => [string(key) for key in keys(p)], "values" => collect(values(p)))

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

for sym in (:on, :onany)
    trysim = Symbol(:try, sym)
    @eval function $trysim(f, session::Session, obs::Observable...)
        error_msg = Observable("")
        onjs(session, error_msg, js"""
            function (value) {
                alert(value);
            }
        """)
        return $sym(session, obs...) do args...
            try
                f(args...)
            catch err
                io = IOBuffer()
                print(io, "Could not complete command due to the following error.")
                print(io, "\n\n")
                print(io, err)
                error_msg[] = String(take!(io))
            end
        end
    end
end

function filter_namedtuple(f, nt)
    names = filter(key -> f(nt[key]), keys(nt))
    return NamedTuple{names}(nt)
end

function move_item(v, (old, new))
    return map(1:length(v)) do i
        i == new && return v[old]
        old ≤ i ≤ new && return v[i+1]
        old ≥ i ≥ new && return v[i-1]
        return v[i]
    end
end

function remove_item(v, idx)
    return map(1:length(v)-1) do i
        return i < idx ? v[i] : v[i+1]
    end
end

function insert_item(v, idx, value)
    return map(1:length(v)+1) do i
        i < idx && return v[i]
        i > idx && return v[i-1]
        return value
    end
end

function scrollable_component(args...; kwargs...)
    return DOM.div(
        DOM.div(args...; class="absolute left-0 right-8");
        class="overflow-y-scroll h-full w-full relative",
        kwargs...
    )
end
