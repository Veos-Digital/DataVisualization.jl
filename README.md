# DataVisualization

[![CI](https://github.com/Veos-Digital/DataVisualization.jl/workflows/CI/badge.svg?branch=main)](https://github.com/Veos-Digital/DataVisualization.jl/actions?query=workflow%3ACI+branch%3Amain)
[![codecov.io](http://codecov.io/github/Veos-Digital/DataVisualization.jl/coverage.svg?branch=main)](http://codecov.io/github/Veos-Digital/DataVisualization.jl?branch=main)
[![](https://img.shields.io/badge/docs-stable-blue.svg)](https://veos-digital.github.io/DataVisualization.jl/stable)
[![](https://img.shields.io/badge/docs-dev-blue.svg)](https://veos-digital.github.io/DataVisualization.jl/dev)

Start julia with `julia --project=app` and include `app/main.jl` to start the interface on `127.0.0.1:9000/`.

:warning: The settings in the `app/main.jl` file demo include a wild card, which is insecure on a server, as it can run arbitrary code.
If you are serving the app publicly, do not include `:Wildcard` among the options.

## Compilation

DataVisualization.jl can be compiled to a stand-alone app as follows:

```julia
using PackageCompiler
create_app("path/to/DataVisualization", "path/to/new/app/folder",
    include_transitive_dependencies=false)
```

:warning: To work this requires the versions currently listed in the Manifest.toml file.

For instance, provided PackageCompiler is installed in the global environment, one can navigate to the root folder of this repository and run

```
julia -q --project

julia> using Pkg, PackageCompiler

julia> Pkg.instantiate()

julia> create_app(".", "AppFolder", include_transitive_dependencies=false)
```