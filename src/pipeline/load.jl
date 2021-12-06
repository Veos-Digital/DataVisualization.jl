struct Load{T} <: AbstractPipeline{T}
    table::Observable{T}
    files::Observable{Union{Nothing, Dict}}
    value::Observable{T}
end

function get_vertices(l::Load)
    names = collect(Tables.columnnames(l.table[]))
    return [Vertex(:Load, Symbol[], names)]
end

get_vertex_names(l::Load) = [:Load]

function Load(table::Observable{T}) where {T}
    files = Observable{Union{Nothing, Dict}}(nothing)
    value = Observable{T}(table[])
    return Load{T}(table, files, value)
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