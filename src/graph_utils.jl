function update!(g::SimpleDiGraph, input::T, outputs::Vector{T}, functions::Vector{<:Function}, i::Int) where T
    return update!(g, input, outputs, functions, i:i)
end

function update!(g::SimpleDiGraph, input::T, outputs::Vector{T}, functions::Vector{<:Function}, idxs::AbstractVector{Int}=eachindex(outputs)) where T
    needs_updating = fill(false, length(outputs))
    needs_updating[idxs] .= true
    sorted = topological_sort_by_dfs(g)
    current = input
    for node in sorted
        for neighbor in inneighbors(g, node)
            needs_updating[node] |= needs_updating[neighbor]
        end
        if needs_updating[node]
            outputs[node] = functions[node](current)
            current = outputs[node]
        end
    end
    return current
end
