using PalmerPenguins, DataFrames
ENV["DATADEPS_ALWAYS_ACCEPT"] = true
penguins = dropmissing(DataFrame(PalmerPenguins.load()))

using DataVisualization, Sockets
set_aog_theme!()
# TODO: should the font size depend on pixel ratio?
update_theme!(fontsize=24)

(@isdefined server) && close(server)

pipelinetabs = (
    :Load,
    :Filter,
    :Process => (options=[:Predict, :Cluster, :Project, :Wildcard],),
)

visualizationtabs = (:Spreadsheet, :Chart, :Pipelines)

server = DataVisualization.serve(penguins; pipelinetabs, visualizationtabs,
    url=Sockets.localhost, port=9000, verbose=true)

nothing