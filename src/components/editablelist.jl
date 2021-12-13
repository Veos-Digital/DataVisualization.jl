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
const moveselected = MoveSelected()

struct EditableList
    options::Observable{SimpleList}
    steps::Observable{SimpleList}
    selected::Observable{Vector{String}}
    list::Observable{SimpleList}
end

function get_addnewcard_index(list::Vector, add::AddNewCard)
    idx = findfirst(==(add), list)
    return count(x -> x isa AddNewCard, view(list, 1:idx))
end

function get_step_indices(steps::Vector, selected::Vector{String})
    ids = @. string(objectid(getproperty(steps, :card)))
    return filter(!isnothing, indexin(selected, ids))
end

function AddNewCard(keys::Observable{Vector{String}}, el::EditableList)
    add = AddNewCard(keys)
    on(add.value) do val
        isempty(val) && return
        addnewcard_index = get_addnewcard_index(el.list[], add)
        _steps = el.steps[]
        step_indices = get_step_indices(_steps, el.selected[])
        if val == "Move Selected"
            isempty(step_indices) && return
            step_index = first(step_indices)
            el.steps[] = move_item(_steps, step_index => addnewcard_index - (addnewcard_index > step_index))
        else
            options = el.options[]
            idx = findfirst(==(val)∘getkey, options)
            isnothing(idx) && return
            thunk = getvalue(option[idx])
            el.steps[] = insert_item(_steps, addnewcard_index, thunk())
        end
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
