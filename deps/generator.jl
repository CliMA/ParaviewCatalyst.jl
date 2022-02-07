using Clang.Generators
using Catalyst_jll

cd(@__DIR__) do
    include_dir = joinpath(Catalyst_jll.artifact_dir, "include", "catalyst-2.0") |> normpath
    catalyst_h = joinpath(include_dir, "catalyst_api.h") |> normpath
    @assert isfile(catalyst_h)
    blueprint_mesh_h = joinpath(include_dir, "conduit_blueprint.h") |> normpath
    @assert isfile(blueprint_mesh_h)
 
    options = load_options(joinpath(@__DIR__, "generator.toml"))
    args = push!(get_default_args(), "-I$include_dir")
    ctx = create_context([catalyst_h, blueprint_mesh_h], args, options)
    build!(ctx)
end
