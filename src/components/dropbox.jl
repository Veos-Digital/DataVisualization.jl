struct Dropbox
    dropped::Observable{String}
end

Dropbox() = Dropbox(Observable(""))

function jsrender(session::Session, db::Dropbox)
    dragoverclasses = ["bg-gray-200", "text-blue-900"]
    ondrop = js"JSServe.update_obs($(db.dropped), event.dataTransfer.getData('text')); this.classList.remove(...$(dragoverclasses));"
    ondragover = js"event.preventDefault();"
    ondragenter = js"event.preventDefault(); this.classList.add(...$(dragoverclasses));"
    ondragleave = js"event.preventDefault(); this.classList.remove(...$(dragoverclasses));"
    ui = DOM.p("+"; class="p-8 cursor-pointer text-blue-800 text-2xl hover:bg-gray-200 hover:text-blue-900", ondragenter, ondragleave, ondragover, ondrop)
    return jsrender(session, ui)
end

struct DraggableList{T}
    steps::Observable{Vector{T}}
    list::Observable{Vector{Any}}
    selected::Observable{Int}
end

function add_callbacks!(dropbox::Dropbox, dl::DraggableList)
    on(dropbox.dropped) do hash
        list = dl.list[]
        id = objectid(dropbox)
        idx = findfirst(==(id)∘objectid, list)
        _selected = count(x -> x isa Dropbox, view(list, 1:idx))
        dl.selected[] = _selected
        _steps = dl.steps[]
        for (idx, step) in enumerate(_steps)
            if string(objectid(step.card)) == hash
                old = idx
                new = _selected - (_selected > old)
                dl.steps[] = move_item(_steps, old => new)
            end
        end
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
