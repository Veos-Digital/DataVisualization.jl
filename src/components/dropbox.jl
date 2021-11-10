struct Dropbox
    dropped::Observable{Bool}
end

Dropbox() = Dropbox(Observable(false))

function jsrender(session::Session, db::Dropbox)
    dragoverclass = "bg-gray-200"
    ondrop = js"event.preventDefault(); JSServe.update_obs($(db.dropped), true); this.classList.remove($(dragoverclass));"
    ondragover = js"event.preventDefault(); this.classList.add($(dragoverclass));"
    ondragleave = js"this.classList.remove($(dragoverclass));"
    ui = DOM.div(; class="py-6", ondragover, ondragleave, ondrop)
    return jsrender(session, ui)
end

struct DraggableList{T}
    steps::Observable{Vector{T}}
    list::Observable{Vector{Any}}
end

function DraggableList(steps::Observable{Vector{T}}) where {T}
    list = lift(steps) do steps
        elements = Any[]
        push!(elements, Dropbox())
        for step in steps
            push!(elements, step)
            push!(elements, Dropbox())
        end
        return elements
    end
    return DraggableList(steps, list)
end

function jsrender(session::Session, dl::DraggableList)
    return jsrender(session, dl.list)
end