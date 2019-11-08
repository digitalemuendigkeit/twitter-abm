using Random
using LightGraphs

# this algorithm is modelled after the python networkx implementation:
# https://github.com/networkx/networkx/blob/master/networkx/generators/random_graphs.py#L655
function create_network(n::Int64, m0::Int64, seed::Int64=0)
    # check if n is smaller than m0
    if n >= m0
        # setup
        Random.seed!(seed)
        g = SimpleDiGraph(n)
        # set of nodes to connect to
        targets = collect(1:m0)
        # growing set of nodes for preferential attachment
        repeated_nodes = Array{Int64}(undef, 0)
        # initial source node
        source = m0 + 1
        # preferential attachment algorithm
        while source <= n
            for e in zip(fill(source, m0), targets)
                add_edge!(g, e[1], e[2])
            end
            append!(repeated_nodes, targets)
            append!(repeated_nodes, fill(source, m0))
            targets = shuffle(repeated_nodes)[1:m0]
            source += 1
            if source > 1000
                break
            end
        end
        return g
    else
        error("n cannot be smaller than m0")
    end
end

# suppress output of include()
;