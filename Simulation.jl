using LightGraphs
using DataFrames
using Statistics

function generate_opinion()
    return rand(-1:0.0000001:1)
end

# this function was adapted from:
# https://www.johndcook.com/julia_rng.html
function generate_inclin_interact(lambda=log(25))
    if lambda <= 0.0
        error("mean must be positive")
    end
    -(1 / lambda) * log(rand())
end

function create_agents(graph::AbstractGraph)
    agent_list = Array{Agent, 1}(undef, length(vertices(graph)))
    for agent in 1:length(agent_list)
        agent_list[agent] = Agent(generate_opinion(), generate_inclin_interact())
    end
    return agent_list
end

function create_agents(agent_count::Integer)
    agent_list = Array{Agent, 1}(undef, agent_count)
    for agent in 1:length(agent_list)
        agent_list[agent] = Agent(generate_opinion(), generate_inclin_interact())
    end
    return agent_list
end

# simulation step
function tick!(graph::AbstractGraph, agent_list::AbstractArray)
    for agent in shuffle(1:length(agent_list))
        update_perceiv_publ_opinion!(graph, agent_list, agent)
        update_opinion!(agent_list, agent)
        # update_inclin_interact!(agent_list, agent)
        # like()
        drop_worst_input(graph, agent_list, agent)
        add_input(graph, agent_list, agent)
        inclin_interact = deepcopy(agent_list[agent].inclin_interact)
        while inclin_interact > 0
            if rand() < inclin_interact
                publish_tweet!(graph, agent_list, agent)
            end
            inclin_interact -= 1.0
        end
        update_feed!(agent_list, agent)
    end
    return log_Network(graph,agent_list)
end

function log_Network(graph::AbstractGraph, agent_list::AbstractArray)
    agent_opinions = [a.opinion for a in agent_list]
    agent_perceiv_publ_opinion = [a.perceiv_publ_opinion for a in agent_list]
    agent_indegree = indegree(graph)
    return DataFrame(Opinion = agent_opinions, Perceiption = agent_perceiv_publ_opinion, Indegree = agent_indegree)
end


# the actual simulation
function simulate(graph::AbstractGraph, agent_list::AbstractArray, n_iter::Integer)
    agent_list = deepcopy(agent_list)
    graph = deepcopy(graph)
    df = DataFrame(Opinion = Float64[], Perceiption = Float64[], Indegree = Int64[])
    for i in 1:n_iter
        append!(df,tick!(graph, agent_list))
        if i % ceil(n_iter / 10) == 0
            print(".")
        end
    end
    return graph, agent_list, df
end

# suppress output of include()
;
