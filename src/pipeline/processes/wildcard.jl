struct Wildcard <: AbstractProcessingStep
    table::Observable{SimpleTable}
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

const WILDCARD_MODULES = (Base, Statistics, StatsBase) # TODO: consider adding more modules

function Wildcard(table::Observable{SimpleTable})
    inputs = RichTextField("Inputs", data_options(table, keywords=[""]), "")
    outputs = RichTextField("Outputs", data_options(table, keywords=[""], suffix="_new"), "")
    input_suggestions = lift(tryarguments, inputs.widget.value)
    output_suggestions = lift(tryarguments, outputs.widget.value)
    suggestions = Observable(
        [string(name) for m in WILDCARD_MODULES for name in names(m) if getproperty(m, name) isa Function]
    )
    # TODO: decide scores
    autocompleteoptions = Any[
        SimpleDict("meta" => "input", "words" => input_suggestions, "score" => 2),
        SimpleDict("meta" => "output", "words" => output_suggestions, "score" => 1),
        SimpleDict("meta" => "", "words" => suggestions, "score" => -1),
    ]
    wdgs = (;
        inputs,
        outputs,
        method=RichEditor("Method", "julia", "", autocompleteoptions),
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
    for m in map(Symbol, WILDCARD_MODULES)
        @eval private_module using DataVisualization.($m)
    end
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
    return LittleDict{Symbol, AbstractVector}(output => getproperty(private_module, output) for output in outputs)
end
