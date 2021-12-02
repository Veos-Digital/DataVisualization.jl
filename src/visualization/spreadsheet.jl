struct SpreadSheet{T} <: AbstractVisualization{T}
    table::Observable{T}
end

function jsrender(session::Session, sh::SpreadSheet)
    return jsrender(session, Tabular(sh.table))
end