abstract type AbstractProcessingStep{T} end

jsrender(session::Session, step::AbstractProcessingStep) = jsrender(session, step.card)

struct ProcessingCard
    name::Symbol
    inputs::RichTextField
    output::Union{RichTextField, Nothing}
    method::RichTextField
    rename::RichTextField
    process_button::Button
    clear_button::Button
end

function autocompletes(card::ProcessingCard)
    return filter_namedtuple(!isnothing, (; card.inputs, card.output, card.method, card.rename))
end

function ProcessingCard(name;
    inputs, output=nothing, method, rename,
    process_button=Button("Process", class=buttonclass(true)),
    clear_button=Button("Clear", class=buttonclass(false)))

    card = ProcessingCard(name, inputs, output, method, rename, process_button, clear_button)
    on(clear_button.value) do _
        foreach(reset!, autocompletes(card))
    end
    on(process_button.value) do _
        foreach(parse!, autocompletes(card))
    end
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
    return used_columns(card.rename.parsed)
end

function jsrender(session::Session, card::ProcessingCard)
    ui = DOM.div(autocompletes(card)..., DOM.div(class="mt-12 mb-16 pl-4", card.process_button, card.clear_button))
    return jsrender(session, ui)
end