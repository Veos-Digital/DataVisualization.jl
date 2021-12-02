struct SpreadSheet{T} <: AbstractVisualization{T}
    table::Observable{T}
end

function jsrender(session::Session, sh::SpreadSheet)
    ui = Tabular(sh.table)
    return jsrender(session, ui)
end