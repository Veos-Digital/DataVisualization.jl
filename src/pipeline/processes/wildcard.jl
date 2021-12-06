struct Wildcard{T} <: AbstractProcessingStep{T}
    table::Observable{T}
    card::ProcessingCard
end

function tryarguments(value::AbstractString)
    result = String[]
    try
        result = only(compute_calls(value)).positional
    catch e
    end
    return result
end

function Wildcard(table::Observable)
    inputs = RichTextField("Inputs", data_options(table, keywords=[""]), "")
    outputs = RichTextField("Outputs", data_options(table, keywords=[""], suffix="_new"), "")
    options = lift(inputs.widget.value, outputs.widget.value) do inputs, outputs
        input_options, output_options = tryarguments(inputs), tryarguments(outputs)
        return vcat(input_options, output_options)
    end
    wdgs = (;
        inputs,
        outputs,
        method=RichEditor("Method", "julia", "", options), # FIXME: pass correct list of options
    )
    card = ProcessingCard(:Wildcard; wdgs...)
    return Wildcard(table, card)
end

function (wc::Wildcard)(data)
    card = wc.card
    inputs_call = only(card.inputs.parsed)
    inputs = Symbol.(inputs_call.positional)
    outputs_call = only(card.outputs.parsed)
    outputs = Symbol.(outputs_call.positional)
    
    private_module = Module()
    for input in inputs
        @eval private_module $input = $(Tables.getcolumn(data, input))
    end
    value = wc.card.method.widget.value[]
    expr = Meta.parse("""
        begin
            $value
        end
    """)
    @eval private_module $expr
    return LittleDict(output => getproperty(private_module, output) for output in outputs)
end
