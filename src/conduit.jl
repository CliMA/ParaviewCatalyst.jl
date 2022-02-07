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

function Base.setindex!(node::ConduitNode, val::Vector{Float64}, path::String)
    GC.@preserve val begin
	API.conduit_node_set_path_float64_ptr(node, path, pointer(val), length(val))
    end
    return node
end

function Base.setindex!(node::ConduitNode, val::ConduitNode, path::String)
    API.conduit_node_set_path_node(node, path, val)
    node
end

function destroy(node::ConduitNode) 
    API.conduit_node_destroy(node)
    nothing
end

function ConduitNode(f::Function)
    node = ConduitNode()
    try
	f(node)
    finally
	destroy(node)
    end
    return nothing
end

function about()
    ConduitNode() do node
        API.conduit_about(node)
	print_node(node)
    end
end
 
function print_node(node::ConduitNode; detailed = false)
    if detailed 
        API.conduit_node_print(node)
    else
	API.conduit_node_print_detailed(node)
    end
end

function test_basic_mesh()
    node = ConduitNode()
    API.conduit_blueprint_mesh_examples_basic("hexs", 10, 10, 10, node)
    return node
end

function test_braid_mesh()
    node = ConduitNode()
    GC.@preserve node begin
        API.conduit_blueprint_mesh_examples_braid("hexs", 10, 10, 10, node)
    end
    return node
end

end
