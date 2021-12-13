struct Load <: AbstractPipeline
    table::Observable{SimpleTable}
    files::Observable{Union{Nothing, Dict}}
    value::Observable{SimpleTable}
end

function get_vertices(l::Load)
    names = collect(Tables.columnnames(l.table[]))
    return [Vertex(:Load, Symbol[], names)]
end

get_vertex_names(::Load) = [:Load]

function Load(table::Observable{SimpleTable})
    files = Observable{Union{Nothing, Dict}}(nothing)
    value = Observable(table[])
    return Load(table, files, value)
end

function jsrender(session::Session, l::Load)

    ui = scrollable_component(FilePicker(l.files))

    tryon(session, l.files) do files
        !isempty(files) && (l.table[] = readfiles(files))
    end

    tryon(session, l.table) do table
        l.value[] = table
    end

    return jsrender(session, ui)
end