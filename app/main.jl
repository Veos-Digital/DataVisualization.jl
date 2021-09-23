using Observables, JSServe, Makie, AlgebraOfGraphics
using DataVisualization
set_aog_theme!()
update_theme!(fontsize=28)

ENV["DATADEPS_ALWAYS_ACCEPT"] = true

using PalmerPenguins, DataFrames
penguins = dropmissing(DataFrame(PalmerPenguins.load()))

app = App() do
    return DOM.div(DataVisualization.AllCSS..., UI(penguins))
end

(@isdefined server) && close(server)
server = JSServe.Server(app, "0.0.0.0", 9000)