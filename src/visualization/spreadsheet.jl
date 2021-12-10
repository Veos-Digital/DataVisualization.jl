struct Spreadsheet <: AbstractVisualization
    table::Observable{SimpleTable}
end

Spreadsheet(pipelines::AbstractVector) = Spreadsheet(output(last(pipelines)))

function jsrender(session::Session, sh::Spreadsheet)
    ui = Tabular(sh.table)
    return jsrender(session, ui)
end