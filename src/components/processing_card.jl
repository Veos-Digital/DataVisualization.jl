abstract type AbstractProcessingStep{T} end

jsrender(session::Session, step::AbstractProcessingStep) = jsrender(session, step.card)

columns_in(step::AbstractProcessingStep) = columns_in(step.card)
columns_out(step::AbstractProcessingStep) = columns_out(step.card)

@enum State inactive scheduled computing done errored

shouldrun(state::State) = state ∉ (inactive, done)

struct StateTracker
    state::Observable{State}
    edited::Observable{Bool}
end

function jsrender(session::Session, tracker::StateTracker)
    class = map(session, tracker.state, tracker.edited, result=Observable{String}()) do state, edited
        baseclass = "float-right text-2xl pr-4 inline-block"
        edited && return "$(baseclass) text-yellow-600"
        state == inactive && return "$(baseclass) text-transparent"
        state in (scheduled, computing) && return "$(baseclass) text-blue-600 animate-pulse"
        state == done && return "$(baseclass) text-blue-800"
        state == errored && return "$(baseclass) text-red-800"
        throw(ArgumentError("Invalid state $state"))
    end
    ui = DOM.span("⬤", class=class[])
    onjs(session, class, js"""
        function (className) {
            $(ui).className = className;
        }
    """)
    return jsrender(session, ui)
end

struct ErrorContainer
    hidden::Observable{Bool}
    error::Observable{String}
end

function jsrender(session::Session, ec::ErrorContainer)
    p = DOM.p(ec.error[])
    ui = DOM.div(p; ec.hidden, class="p-8 bg-white border-2 border-red-800")
    onjs(session, ec.error, js"""
        function (value) {
            $(p).innerText = value;
        }
    """)
    return jsrender(session, ui)
end

struct ProcessingCard
    name::Symbol
    inputs::RichTextField
    output::Union{RichTextField, Nothing}
    method::RichTextField
    rename::RichTextField
    process_button::Button
    clear_button::Button
    state::Observable{State}
    edited::Observable{Bool}
    error::Observable{String}
    run::Observable{Bool}
    destroy::Observable{Bool}
end

function autocompletes(card::ProcessingCard)
    return filter_namedtuple(!isnothing, (; card.inputs, card.output, card.method, card.rename))
end

function process!(card::ProcessingCard)
    foreach(parse!, autocompletes(card))
    card.state[] = scheduled
    card.run[] = true
end

function clear!(card::ProcessingCard)
    foreach(reset!, autocompletes(card))
    card.state[] = scheduled
    card.run[] = true
end

function ProcessingCard(name;
                        inputs,
                        output=nothing,
                        method,
                        rename,
                        process_button=Button("Process", class=buttonclass(true)),
                        clear_button=Button("Clear", class=buttonclass(false)),
                        state=Observable(inactive),
                        edited=Observable(false),
                        error=Observable(""),
                        run=Observable(false),
                        destroy = Observable(false))

    card = ProcessingCard(
        name,
        inputs,
        output,
        method,
        rename,
        process_button,
        clear_button,
        state,
        edited,
        error,
        run,
        destroy
    )

    on(_ ->  process!(card), process_button.value)
    on(_ ->  clear!(card), clear_button.value)
    confirmed = map(autocompletes(card)) do textfield
        return lift(==, textfield.widget.value, textfield.confirmedvalue)
    end
    map!(!all∘tuple, card.edited, confirmed...)

    return card
end

function used_columns(args::AbstractVector{Call}...)
    colnames = Symbol[]
    for calls in args
        for call in calls
            append!(colnames, Symbol.(call.positional), Symbol.(last.(call.named)))
        end
    end
    return colnames
end

function columns_in(card::ProcessingCard)
    args = [t.parsed for t in [card.inputs, card.output] if !isnothing(t)]
    return used_columns(args...)
end

function columns_out(card::ProcessingCard)
    return isempty(columns_in(card)) ? Symbol[] : used_columns(card.rename.parsed)
end

function jsrender(session::Session, card::ProcessingCard)
    statetracker = StateTracker(card.state, card.edited)
    hide_error = map(!=(errored), session, card.state, result=Observable{Bool}())
    errorcontainer = ErrorContainer(hide_error, card.error)

    card_ui = DOM.div(
        DOM.span(string(card.name), class="text-blue-800 text-2xl font-semibold"),
        DOM.span(
            "✕",
            class="text-red-800 hover:text-red-900 text-2xl font-semibold float-right cursor-pointer",
            onclick=js"JSServe.update_obs($(card.destroy), true)"
        ),
        statetracker,
        autocompletes(card)...,
        DOM.div(class="mt-12", card.process_button, card.clear_button),
        class="select-none p-8 shadow bg-white border-2 border-transparent",
        dataId=string(objectid(card)),
        dataType="card",
        dataSelected="false",
    )
    ui = DOM.div(
        card_ui,
        errorcontainer
    )

    return jsrender(session, ui)
end
