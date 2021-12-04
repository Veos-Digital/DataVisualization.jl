struct Vertex
    name::Symbol
    inputs::Vector{Symbol}
    outputs::Vector{Symbol}
end

get_vertex_names(vetrices::AbstractArray{Vertex}) = map(vertex -> vertex.name, vetrices)

function simpledigraph(vertices::AbstractArray{Vertex})
    N = length(vertices)
    g = SimpleDiGraph(N)
    for i in 1:N, j in 1:N
        vi, vj = vertices[i], vertices[j]
        isdisjoint(vi.outputs, vj.inputs) || add_edge!(g, i, j)
    end
    return g
end

# nested case
function simpledigraph(nested_vertices::AbstractArray{<:AbstractArray{Vertex}})
    
    vertices = reduce(vcat, nested_vertices)
    groups = mapreduce(append!, enumerate(nested_vertices), init=Int[]) do (idx, vertices)
        return fill(idx, length(vertices))
    end

    N = length(vertices)
    g = SimpleDiGraph(N)
    for j in 1:N
        inputs = copy(vertices[j].inputs)
        ii = searchsortedlast(groups, groups[j])
        for i in ii:-1:1
            outputs = vertices[i].outputs
            isdisjoint(outputs, inputs) && continue
            i == j && continue # FIXME: is there a cleaner way to avoid self loops with filter?
            setdiff!(inputs, outputs)
            add_edge!(g, i, j)
        end
    end

    return g
end
