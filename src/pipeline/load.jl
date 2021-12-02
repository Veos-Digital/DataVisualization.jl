struct Load{T} <: AbstractPipeline{T}
    table::Observable{T}
    files::Observable{Union{Nothing, Dict}}
    value::Observable{T}
end

function Load(table::Observable{T}) where {T}
    files = Observable{Union{Nothing, Dict}}(nothing)
    value = Observable{T}(table[])
    return Load{T}(table, files, value)
end

function jsrender(session::Session, l::Load)

    ui = FilePicker(l.files)

    tryon(session, l.files) do files
        !isempty(files) && (l.table[] = readfiles(files))
    end

    tryon(session, l.table) do table
        l.value[] = table
    end

    return jsrender(session, ui)
end