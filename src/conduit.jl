module Conduit

import JSON3

import ..API

struct ConduitNode
    ptr::Ptr{API.conduit_node}

    function ConduitNode()
	    nptr = API.conduit_node_create()
	    return new(nptr)
    end
end
Base.unsafe_convert(::Type{Ptr{API.conduit_node}}, node::ConduitNode) = node.ptr

function ConduitNode(f::Function)
    node = ConduitNode()
    try
	    f(node)
    finally
	    node_destroy(node)
    end
    return nothing
end

#=
for num_type in (:UInt8, :Int8, :UInt16, :Int16, :UInt32, :Int32, :UInt64, :Int64, :Float32, :Float64)
    conduit_num = symbol(lower("$numtype"))
end
=#

function Base.setindex!(node::ConduitNode, val::Int64, path::String)
    API.conduit_node_set_path_int64(node, path, val)
    return node
end

function Base.setindex!(node::ConduitNode, val::Float64, path::String)
    API.conduit_node_set_path_double(node, path, val)
    return node
end

function Base.setindex!(node::ConduitNode, val::String, path::String)
    API.conduit_node_set_path_char8_str(node, path, val)
    return node
end

function Base.setindex!(node::ConduitNode, val::Array{Float64}, path::String)
    API.conduit_node_set_path_float64_ptr(node, path, pointer(val), length(val))
    return node
end

function Base.setindex!(node::ConduitNode, val::ConduitNode, path::String)
    API.conduit_node_set_path_node(node, path, val)
    return node
end

function node_has_path(node::ConduitNode, path::String)
    return Bool(API.conduit_node_has_path(node, path))
end

function node_path(node::ConduitNode)
    return unsafe_string(API.conduit_node_path(node))
end

function node_dtype(node::ConduitNode)
    return API.conduit_node_dtype(node)
end

function node_remove_path!(node::ConduitNode, path::String)
    API.conduit_node_remove_path(node, path)
    return node
end

function node_update!(dest_node::ConduitNode, src_node::ConduitNode)
    API.conduit_node_update(dest_node, src_node)
    return dest_node
end

function node_update_compatible!(dest_node::ConduitNode, src_node::ConduitNode)
    API.conduit_node_update_compatible(dest_node, src_node)
    return dest_node
end

function node_update_external!(dest_node::ConduitNode, src_node::ConduitNode)
    API.conduit_node_update_external(dest_node, src_node)
    return dest_node
end

function node_destroy(node::ConduitNode)
    API.conduit_node_destroy(node)
    return nothing
end

function node_print(node::ConduitNode; detailed = false)
    if detailed
	    API.conduit_node_print_detailed(node)
    else
	    API.conduit_node_print(node)
    end
    return
end

function about()
    ConduitNode() do node
        API.conduit_about(node)
	    node_print(node)
    end
end

function example_basic_mesh(;mesh = "hexs", nx = 10, ny = 10, nz = 10)
    node = ConduitNode()
    GC.@preserve node begin
        API.conduit_blueprint_mesh_examples_basic(mesh, nx, ny, nz, node)
    end
    return node
end

function example_braid_mesh(;mesh = "hexs", nx = 50, ny = 50, nz = 50)
    node = ConduitNode()
    GC.@preserve node begin
        API.conduit_blueprint_mesh_examples_braid(mesh, nx, ny, nz, node)
    end
    return node
end

end
