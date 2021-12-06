using PalmerPenguins, DataFrames
ENV["DATADEPS_ALWAYS_ACCEPT"] = true
penguins = dropmissing(DataFrame(PalmerPenguins.load()))

using DataVisualization
set_aog_theme!()
# TODO: should the font size depend on pixel ratio?
update_theme!(fontsize=24)

(@isdefined server) && close(server)
server = DataVisualization.serve(penguins, url="0.0.0.0", port=9000)
nothing