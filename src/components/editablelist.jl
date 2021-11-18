struct AddNewCard
    value::Observable{String}
    isblur::Observable{Bool}
    list::List
    input_id::Observable{String}
end

function AddNewCard(keys::Observable{Vector{String}}, value=Observable(""), list::List=List(keys, value))
    return AddNewCard(value, Observable(true), list, Observable(""))
end

function jsrender(session::Session, add::AddNewCard)
    list = JSServe.jsrender(session, add.list)
    isblur, input_id = add.isblur, add.input_id
    onfocusin = js"""
        JSServe.update_obs($(isblur), false);
        const tgt = event.relatedTarget;
        const dataset = (tgt || {}).dataset;
        const input_id = (dataset || {}).id;
        input_id && JSServe.update_obs($(input_id), input_id);
    """
    onfocusout=js"""
        const tgt = event.relatedTarget;
        tgt && $(list).contains(tgt) || JSServe.update_obs($(isblur), true);
    """
    box = DOM.button(
        "+";
        class="w-full p-8 cursor-pointer text-left text-blue-800 text-2xl hover:bg-gray-200 hover:text-blue-900",
        onfocusin,
        onfocusout,
    )
    onjs(session, add.value, js"function (value) {JSServe.update_obs($(isblur), true);}")
    ui = DOM.div(
        box,
        DOM.div(list, style="position: relative; z-index: 1;", hidden=isblur),
        dataType="add",
        dataId=string(objectid(add)),
        dataSelected="false",
    )
    return jsrender(session, ui)
end

const StringLittleDict{T} = LittleDict{String, T, Vector{String}, Vector{T}}

function to_stringdict(p)
    k = String[string(key) for key in keys(p)]
    v = Any[v for v in values(p)]
    return LittleDict(k, v)
end

struct EditableList
    keys::Observable{Vector{String}}
    options::Observable{StringLittleDict{Any}}
    steps::Observable{Vector{Any}}
    list::Observable{Vector{Any}}
end

function AddNewCard(keys::Observable{Vector{String}}, el::EditableList)
    add = AddNewCard(keys)
    on(add.value) do val
        isempty(val) && return
        list = el.list[]
        id = objectid(add)
        idx = findfirst(==(id)∘objectid, list)
        _selected = count(x -> x isa AddNewCard, view(list, 1:idx))
        _steps = el.steps[]
        if val == "Move Selected"
            for (idx, step) in enumerate(_steps)
                if string(objectid(step.card)) == add.input_id[]
                    old = idx
                    new = _selected - (_selected > old)
                    el.steps[] = move_item(_steps, old => new)
                end
            end
        else
            thunk = get(el.options[], val, nothing)
            isnothing(thunk) && return
            el.steps[] = insert_item(_steps, _selected, thunk())
            # TODO: add callbacks to card and make insertion smoother
        end
    end
    return add
end

function EditableList(options::Observable, steps::Observable)
    keys = lift(options) do options
        acc = ["Move Selected"]
        for key in Base.keys(options)
            push!(acc, key)
        end
        return acc
    end
    list = Observable{Vector{Any}}()
    el = EditableList(keys, options, steps, list)
    map!(list, steps) do steps
        elements = Any[]
        push!(elements, AddNewCard(keys, el))
        for step in steps
            push!(elements, step)
            push!(elements, AddNewCard(keys, el))
        end
        return elements
    end
    return el
end

function jsrender(session::Session, el::EditableList)
    ui = map(DOM.div, session, el.list)
    return jsrender(session, ui)
end
