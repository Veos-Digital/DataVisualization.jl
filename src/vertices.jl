struct Vertex
    name::Symbol
    inputs::Vector{Symbol}
    outputs::Vector{Symbol}
end

function simpledigraph(vertices::AbstractArray{<:Vertex})
    N = length(vertices)
    g = SimpleDiGraph(N)
    for i in 1:N, j in 1:N
        vi, vj = vertices[i], vertices[j]
        isdisjoint(vi.outputs, vj.inputs) || add_edge!(g, i, j)
    end
    return g
end
