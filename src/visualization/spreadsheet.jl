struct Spreadsheet{T} <: AbstractVisualization{T}
    table::Observable{T}
end

function jsrender(session::Session, sh::Spreadsheet)
    ui = Tabular(sh.table)
    return jsrender(session, ui)
end