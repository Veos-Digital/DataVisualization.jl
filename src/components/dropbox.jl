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
    selected::Observable{Int}
end

function add_callbacks!(dropbox::Dropbox, dl::DraggableList)
    on(dropbox.dropped) do _
        list = dl.list[]
        id = objectid(dropbox)
        idx = findfirst(==(id)∘objectid, list)
        dl.selected[] = count(x -> x isa Dropbox, view(list, 1:idx))
    end
    return dropbox
end

function DraggableList(steps::Observable{Vector{T}}) where {T}
    selected = Observable(0)
    list = Observable{Vector{Any}}()
    dl = DraggableList(steps, list, selected)
    map!(list, steps) do steps
        elements = Any[]
        push!(elements, add_callbacks!(Dropbox(), dl))
        for step in steps
            push!(elements, step)
            push!(elements, add_callbacks!(Dropbox(), dl))
        end
        return elements
    end
    return DraggableList(steps, list, selected)
end

function jsrender(session::Session, dl::DraggableList)
    ui = map(DOM.div, session, dl.list)
    return jsrender(session, ui)
end
