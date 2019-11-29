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
            for e in zip(targets, fill(source, m0))
                add_edge!(g, e[1], e[2])
            end
            append!(repeated_nodes, targets)
            append!(repeated_nodes, fill(source, m0))
            targets = shuffle(repeated_nodes)[1:m0]
            source += 1
        end
        return g
    else
        error("n cannot be smaller than m0")
    end
end

# function update_network(g::AbstractGraph, agent_list::AbstractArray)

#     # Network grows with a rate of 30%
#     joiningAgentscount = floor(Integer, nv(g) * 0.3)

#     # # First step: Delete agents that have below 10% input connections compared to current vertex count
#     # leavingAgents = Integer[]
#     # for v in 1:nv(g)
#     #     if length(inneighbors(g,v)) < nv(g) / 10
#     #         # println("Agent $v has only " * string(inneighbors(g,v)) * " inneighbors and will leave the network.")
#     #         append!(leavingAgents,v)
#     #     end
#     # end
#     #
#     # deleteat!(agent_list,leavingAgents)
#     # rem_vertices!(g,leavingAgents)

#     # println("$joiningAgentscount will join the network now.")

#     add_vertices!(g, joiningAgentscount)
#     append!(agent_list,create_agents(joiningAgentscount))

#     # Joining Agents get connected randomly to existing agents.
#     # Number of edges for new agent is randomly chosen out of 1:3
#     for i in 1:joiningAgentscount
#         currentAgent = nv(g)-joiningAgentscount+i
#         newNeighborlist = getNewNeighbors(g,currentAgent)
#         for j in 1:5
#             # If Abfrage eigentlich nicht erforderlich, solange j < nv(g)
#             if length(newNeighborlist) > 0
#                 newNeighbor = pop!(newNeighborlist)
#                 add_edge!(g,currentAgent, newNeighbor)
#                 # println("Edge added from $currentAgent => $newNeighbor.")
#             else
#                 # println("No new neighbors possible")
#                 break
#             end
#         end
#     end
# end

function update_network!(graph::AbstractGraph, agent_list::AbstractArray, new_agent_count::Integer=4, initial_inputs::Integer=4)
    pref_attach_list = [src(e) for e in edges(graph) if agent_list[src(e)].active]
    for _ in 1:new_agent_count
        push!(agent_list, Agent(generate_opinion(), generate_inclin_interact(), generate_check_regularity()))
        add_vertex!(graph)
        shuffle!(pref_attach_list)
        for i in 1:initial_inputs
            add_edge!(graph, nv(graph), pref_attach_list[i])
        end
    end
end

# function getNewNeighbors(g::AbstractGraph, v::Integer)
#     candidates = shuffle(setdiff([1:(v - 1); (v + 1):nv(g)], inneighbors(g, v)))
#     return candidates
# end


# suppress output of include()
;
