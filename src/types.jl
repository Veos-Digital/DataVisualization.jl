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

to_dict(s) = SimpleTable(s).data
to_dict(s::AbstractDict) = s

function mergecolswith!(f, s::SimpleTable, others...)
    mapfoldl(to_dict, mergewith!(f), others, init=s.data)
    return s
end

function mergedisjointcols!(s::SimpleTable, others...)
    return mergecolswith!(s, others...) do _, _
        throw(ArgumentError("Overwriting table is not allowed"))
    end
end

Tables.istable(::SimpleTable) = true
Tables.schema(s::SimpleTable) = Tables.schema(s.data)

Tables.columnaccess(::SimpleTable) = true
Tables.columns(s::SimpleTable) = s

Tables.columnnames(s::SimpleTable) = collect(Symbol, keys(s.data))

# Port `DataFrame` behavior of suggesting alternative column names
function Tables.getcolumn(s::SimpleTable, name::Symbol)
    return get(s.data, name) do
        options = Tables.columnnames(s)
        distances = stringdistance.(name, options)
        min_distance = minimum(distances)
        suggestions = options[findall(==(min_distance), distances)]
        nearestnames = join(suggestions, ", ")
        msg = "There isn't a variable called '$name' in your data; the nearest names appear to be: $nearestnames"
        throw(ArgumentError(msg))
    end
end
