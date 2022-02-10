module Conduit

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
	    node_destroy!(node)
    end
    return nothing
end

Base.setindex!(node::ConduitNode, val, path::String) = node_set!(node, path, val)

for numtype in (:UInt8, :Int8, :UInt16, :Int16, :UInt32, :Int32, :UInt64, :Int64, :Float32, :Float64)
    cnumtype = Symbol(lowercase("$(numtype)"))
    node_set_path = Symbol("conduit_node_set_path_$(cnumtype)")
    node_set_path_ptr = Symbol("conduit_node_set_path_$(cnumtype)_ptr")
    @eval begin
        function node_set!(node::ConduitNode, path::String, val::$numtype)
            API.$node_set_path(node, path, val)
            return node
        end
        function node_set!(node::ConduitNode, path::String, val::Array{$numtype})
            API.$node_set_path_ptr(node, path, pointer(val), length(val))
            return node
        end
    end
end

function node_set!(node::ConduitNode, path::String, val::String)
    API.conduit_node_set_path_char8_str(node, path, val)
    return node
end

function node_set!(node::ConduitNode, path::String, val::ConduitNode)
    API.conduit_node_set_path_node(node, path, val)
    return node
end

function node_has_path(node::ConduitNode, path::String)
    return Bool(API.conduit_node_has_path(node, path))
end

function node_path(node::ConduitNode)
    return unsafe_string(API.conduit_node_path(node))
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

function node_info!(dest_node::ConduitNode, src_node::ConduitNode)
    API.conduit_node_info(src_node, dest_node)
    return dest_node
end
function node_info(f::Function, node::ConduitNode)
    info = ConduitNode()
    try
        node_info!(info, node)
        f(info)
    finally
	    node_destroy!(info)
    end
    return
end

function node_destroy!(node::ConduitNode)
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

function node_print_string(node::ConduitNode; detailed = false)
    output_buffer = IOBuffer()
    default_stdout = stdout

    pipe = Pipe()
    Base.link_pipe!(pipe; reader_supports_async = true, writer_supports_async = true)
    pe_stdout = pipe.in
    redirect_stdout(pe_stdout)

    buffer_redirect_task = @async write(output_buffer, pipe)
    try
        node_print(node; detailed);
    finally
        redirect_stdout(default_stdout)
        close(pe_stdout)
        wait(buffer_redirect_task)
    end
    return String(take!(output_buffer))
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

for example in (:example_basic_mesh, :example_braid_mesh)
    @eval begin
        function ($example)(f::Function; kw...)
            node = ($example)(; kw...)
            try
                f(node)
            finally
                node_destroy!(node)
            end
        end
    end
end

end