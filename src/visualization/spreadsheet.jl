struct Spreadsheet{T} <: AbstractVisualization{T}
    table::Observable{T}
end

Spreadsheet(pipelines::AbstractVector) = Spreadsheet(output(last(pipelines)))

function jsrender(session::Session, sh::Spreadsheet)
    ui = Tabular(sh.table)
    return jsrender(session, ui)
end