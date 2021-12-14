const SimpleList = Vector{Any}
const SimpleDict = Dict{String, Any}

function getatkey(options::SimpleList, key)
    idx = findfirst(isequal(key)∘getkey, options)
    return isnothing(idx) ? nothing : getvalue(options[idx])
end

getkey(s::SimpleDict) = s["key"]
getvalue(s::SimpleDict) = s["value"]

# This simple table type is the preferred way to store tables
struct SimpleTable
    names::Vector{Symbol}
    columns::Vector{AbstractVector}
end

function SimpleTable(data)
    cols = Tables.columns(data)
    names = collect(Symbol, Tables.columnnames(cols))
    columns = AbstractVector[Tables.getcolumn(cols, name) for name in names]
    return SimpleTable(names, columns)
end

function SimpleTable(ps::Pair...)
    names = Symbol[first(p) for p in ps]
    columns = AbstractVector[last(p) for p in ps]
    return SimpleTable(names, columns)
end

Base.copy(s::SimpleTable) = SimpleTable(copy(s.names), copy(s.columns))

function mapcols!(f, s::SimpleTable)
    map!(f, s.columns, s.columns)
    return s
end

function mergedisjointcols!(s::SimpleTable, t::SimpleTable)
    sharedkeys = intersect(s.names, t.names)
    if isempty(sharedkeys)
        append!(s.names, t.names)
        append!(s.columns, t.columns)
        return s
    else
        msg = "Overwriting table is not allowed, " *
            "the following column names are repeated: " *
            join(sharedkeys, ", ")
        throw(ArgumentError(msg))
    end
end

Tables.istable(::SimpleTable) = true
Tables.schema(s::SimpleTable) = Tables.Schema(copy(s.names), eltype.(s.columns))

Tables.columnaccess(::SimpleTable) = true
Tables.columns(s::SimpleTable) = s

Tables.columnnames(s::SimpleTable) = copy(s.names)

function suggestnames(s::SimpleTable, name::Symbol)
    options = fuzzymatch(s.names, name)
    nearestnames = join(options, ", ")
    msg = "There isn't a variable called '$name' in your data; the nearest names appear to be: $nearestnames"
    throw(ArgumentError(msg))
end

# Port `DataFrame` behavior of suggesting alternative column names
function Tables.getcolumn(s::SimpleTable, name::Symbol)
    idx = findfirst(==(name), s.names)
    # Give descriptive error if the name is not found
    return isnothing(idx) ? suggestnames(s, name) : s.columns[idx]
end
