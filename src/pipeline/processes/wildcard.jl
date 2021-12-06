struct Wildcard{T} <: AbstractProcessingStep{T}
    table::Observable{T}
    card::ProcessingCard
end

function Wildcard(table::Observable)
    wdgs = (
        inputs=RichTextField("Inputs", data_options(table, keywords=[""]), ""),
        outputs=RichTextField("Outputs", data_options(table, keywords=[""]), ""),
        method=RichEditor("Method", "julia", ""), # FIXME: pass correct list of options
    )
    card = ProcessingCard(:Wildcard; wdgs...)
    return Wildcard(table, card)
end

function (wc::Wildcard)(data)
    inputs_call = only(card.inputs.parsed)
    inputs = Symbol.(inputs_call.positional)
    outputs_call = only(card.inputs.parsed)
    outputs = Symbol.(outputs_call.positional)
    
    private_module = Module()
    for input in inputs
        @eval private_module $input = $(Tables.getcolumn(data, input))
    end
    @eval private_module $(Meta.parse(wc.card.method.widget.value[]))
    return LittleDict(output => getproperty(private_module, output) for output in outputs)
end
