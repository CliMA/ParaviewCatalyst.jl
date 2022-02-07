module ParaviewCatalyst

import Catalyst_jll

export catalyst_initialize,
       catalyst_about,
       catalyst_execute,
       catalyst_results,
       catalyst_replay,
       catalyst_finalize,
       catalyst_mesh # todo: remove

include("api.jl")
include("conduit.jl")

import .Conduit: Conduit, ConduitNode

struct CatalystError <: Exception
   msg::String
   status::API.catalyst_status
end

function error_status(status::API.catalyst_status)
    if status === API.catalyst_status_error_no_implementation
	throw(CatalystError("no catalyst implementation set", status))
    elseif status === API.catalyst_status_error_already_loaded
	throw(CatalystError("catalyst implementation already loaded", status))
    elseif status === API.catalyst_status_error_not_found
	throw(CatalystError("catalyst load implementation not found", status))
    elseif status === API.catalyst_status_error_not_catalyst
	throw(CatalystError("catalyst load implementation path not a catalyst implementation", status))
    elseif status === API.catalyst_status_error_incomplete
	throw(CatalystError("incomplete catalyst settings", status))
    elseif status === API.catalyst_status_error_unsupported_version
	throw(CatalystError("catalyst load implmentation unsupported version"))
    else
	throw(CatalystError("unknown catalyst error", status))
    end
end

baremodule Defaults

const PARAVIEW_CATALYST_PATHS = [
    "/home/jake/ParaView-5.10.0-MPI-Linux-Python3.9-x86_64/lib/catalyst",
]
end

function catalyst_initialize()
    ConduitNode() do node
	node["catalyst_load/implementation"] = "paraview"
	node["catalyst_load/search_paths/paraview"] = Defaults.PARAVIEW_CATALYST_PATHS[1]
	node["catalyst/scripts/catalyst_pipeline/filename"] = joinpath(@__DIR__, "catalyst_pipeline.py")
	#node["catalyst/pipelines/output/type"] = "io"
	#node["catalyst/pipelines/output/filename"] = "ele_example{timestep}.json"
	#node["catalyst/pipelines/output/channel"] = "grid"

	status = API.catalyst_initialize(node)
	if status != API.catalyst_status_ok
	    error_status(status)
	end
    end
    return
end

function catalyst_about()
    ConduitNode() do node
    	status = API.catalyst_about(node)
	if status != API.catalyst_status_ok
	    error_status(status)
	end
	Conduit.print_node(node, detailed=false)
    end
    return
end

function catalyst_mesh()
    mesh = ConduitNode()

    # create the coordinate set
    mesh["coordsets/coords/type"] = "uniform";
    mesh["coordsets/coords/dims/i"] = 3;
    mesh["coordsets/coords/dims/j"] = 3;

    # add origin and spacing to the coordset (optional)
    mesh["coordsets/coords/origin/x"] = -10.0;
    mesh["coordsets/coords/origin/y"] = -10.0;
    mesh["coordsets/coords/spacing/dx"] = 10.0;
    mesh["coordsets/coords/spacing/dy"] = 10.0;

    # add the topology
    # this case is simple b/c it's implicitly derived from the coordinate set
    mesh["topologies/mesh/type"] = "uniform";
    
    # reference the coordinate set by name
    mesh["topologies/mesh/coordset"] = "coords";

    # add a simple element-associated field 
    mesh["fields/ele_example/association"] =  "element";
    # reference the topology this field is defined on by name
    mesh["fields/ele_example/topology"] =  "mesh";
    # set the field values, for this case we have 4 elements
    mesh["fields/ele_example/values"] = [1.0, 2.0, 3.0, 4.0]
    return mesh
end

function catalyst_execute()
    ConduitNode() do node
	node["catalyst/state/timestep"] = 0
	node["catalyst/state/time"] = 0.0

	node["catalyst/channels/input/type"] = "mesh"
	mesh_node = Conduit.test_braid_mesh()
	GC.@preserve mesh_node begin
	    node["catalyst/channels/input/data"] = mesh_node
	end
	Conduit.destroy(mesh_node)

	Conduit.print_node(node)
	status = API.catalyst_execute(node)
        if status != API.catalyst_status_ok
	    error_status(status)
	end
    end
end

function catalyst_results()
    ConduitNode() do node
	status = API.catalyst_status_ok
	if status != API.catalyst_status_ok
	    error_status(status)
	end
        Conduit.print_node(node, detailed=false)
    end
end

function catalyst_replay()
end

function catalyst_finalize()
    ConduitNode() do node
	status = API.catalyst_status_ok
        if status != API.catalyst_status_ok
	    error_status(status)
	end
    end
    return
end

end # module
