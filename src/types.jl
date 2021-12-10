const SimpleList = Vector{Any}
const SimpleDict = Dict{String, Any}
const SimpleLittleDict{K, V} = LittleDict{K, V, Vector{K}, Vector{V}}

struct SimpleTable
    data::SimpleLittleDict{Symbol, AbstractVector}
    SimpleTable(data::SimpleLittleDict{Symbol, AbstractVector}) = new(data)
end

# This simple untyped dictionary is the preferred way to store tables
function SimpleTable(data)
    cols = Tables.columns(data)
    names = collect(Symbol, Tables.columnnames(cols))
    columns = AbstractVector[Tables.getcolumn(cols, colname) for colname in names]
    dict = LittleDict{Symbol, AbstractVector}(names, columns)
    return SimpleTable(dict)
end

Base.copy(s::SimpleTable) = SimpleTable(copy(s.data))
SimpleTable(s::SimpleTable) = copy(s)

function mapcols!(f, s::SimpleTable)
    map!(f, values(s.data))
    return s
end

function mergecolswith!(f, s::SimpleTable, others...)
    mapfoldl(t -> SimpleTable(t).data, mergewith!(f), others, init=s.data)
    return s
end

Tables.istable(::SimpleTable) = true
Tables.schema(s::SimpleTable) = Tables.schema(s.data)

Tables.columnaccess(::SimpleTable) = true
Tables.columns(s::SimpleTable) = s

Tables.columnnames(s::SimpleTable) = collect(Symbol, keys(s.data))

function Tables.getcolumn(s::SimpleTable, key::Symbol)
    return get(s.data, key) do
        options = Tables.columnnames(s)
        distances = stringdistance.(key, options)
        min_distance = minimum(distances)
        suggestions = options[findall(==(min_distance), distances)]
        msg = "Column $(key) not found, closest alternatives are: " * join(suggestions, ", ")
        throw(ArgumentError(msg))
    end
end
