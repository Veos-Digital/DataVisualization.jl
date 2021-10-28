const available_processes = (
    Predict = LinearModel,
    Cluster = Cluster,
    Project = DimensionalityReduction,
)

struct Process{T} <: AbstractPipeline{T}
    table::Observable{T}
    cards::Observable{Vector{Any}}
    value::Observable{T}
end

function Process(table::Observable, components=(:Predict, :Cluster, :Project))
    cards = Any[]
    current = table
    for component in components
        card = getproperty(available_processes, component)(current)
        push!(cards, card)
        current = output(card)
    end
    return Process(table, Observable(cards), current)
end

function jsrender(session::Session, process::Process)
    ui = map(session, process.cards) do cards
        return DOM.div(
            cards;
            scrollablecomponent...
        )
    end
    return jsrender(session, with_tabular(ui, process.value, padwidgets=0))
end