struct AddNewCard
    value::Observable{String}
    list::List
end

function AddNewCard(keys::Observable{Vector{String}}, value=Observable(""), list::List=List(keys, value))
    return AddNewCard(value, list)
end

function jsrender(session::Session, add::AddNewCard)
    list = JSServe.jsrender(session, add.list)
    hidden, keydown = add.list.hidden, add.list.keydown
    onfocus = js"JSServe.update_obs($(hidden), false);"
    onblur=js"""
        const tgt = event.relatedTarget;
        tgt && $(list).contains(tgt) || JSServe.update_obs($(hidden), true);
    """
    onkeydown = js"event.key == 'Escape' ? this.blur() : JSServe.update_obs($(keydown), event.key)"
    box = DOM.button(
        "+";
        class="w-full p-8 cursor-pointer text-left text-blue-800 text-2xl hover:bg-gray-200 hover:text-blue-900",
        onfocus,
        onblur,
        onkeydown
    )
    onjs(session, add.value, js"function (value) {JSServe.update_obs($(hidden), true);}")
    ui = DOM.div(
        box,
        list,
        dataType="add",
        dataId=string(objectid(add)),
        dataSelected="false",
    )
    return jsrender(session, ui)
end

struct MoveSelected end

struct EditableList
    options::Observable{SimpleList}
    steps::Observable{SimpleList}
    selected::Observable{Vector{String}}
    list::Observable{SimpleList}
end

function get_step_indices(steps::Vector, selected::Vector{String})
    ids = @. string(objectid(getproperty(steps, :card)))
    return filter(!isnothing, indexin(selected, ids))
end

updatecards(el::EditableList, idx, card) = insert_item(el.steps[], idx, card)

function updatecards(el::EditableList, idx, ::MoveSelected)
    _steps, _selected = el.steps[], el.selected[]
    selected_idx = @maybereturn findfirst(_steps) do step
        return string(objectid(step.card)) in _selected
    end
    return move_item(_steps, selected_idx => idx - (idx > selected_idx))
end

function AddNewCard(keys::Observable{Vector{String}}, el::EditableList)
    add = AddNewCard(keys)
    on(add.value) do key
        thunk = @maybereturn getatkey(el.options[], key)
        idx = @maybereturn indexoftype(AddNewCard, el.list[], add) 
        steps = @maybereturn updatecards(el, idx, thunk())
        el.steps[] = steps
    end
    return add
end

function EditableList(options::Observable, steps::Observable)
    selected = Observable(String[])
    keys = @lift getkey.($options)
    list = Observable{SimpleList}()
    el = EditableList(options, steps, selected, list)
    map!(list, steps) do steps
        elements = Any[]
        push!(elements, AddNewCard(keys, el))
        for step in steps
            push!(elements, step)
            push!(elements, AddNewCard(keys, el))
        end
        push!(elements, DOM.div(class="h-64"))
        return elements
    end
    return el
end

function jsrender(session::Session, el::EditableList)
    ui = map(DOM.div, session, el.list)
    return jsrender(session, ui)
end
