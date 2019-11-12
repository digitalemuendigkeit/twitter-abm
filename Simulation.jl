using LightGraphs

# generate a random opinion value
function generate_opinion()
    return rand(-1:0.0000001:1)
end

# generate a random value for inclination to interact
# this function was adapted from:
#    https://www.johndcook.com/julia_rng.html
function generate_inclin_interact(mean=0.2)
    if mean <= 0.0
        error("mean must be positive")
    end
    random_exp = -mean*log(rand())
    if random_exp > 1
        random_exp = generate_inclin_interact(mean)
    end
    return random_exp
end

# initialize agent list
function create_agents(g::AbstractGraph)
    agent_list = Array{Agent, 1}(undef, length(vertices(g)))
    for i in 1:length(agent_list)
        agent_list[i] = Agent(generate_opinion(), generate_inclin_interact())
    end
    return agent_list
end
# simulation step
function tick!(agent_list::AbstractArray, g::AbstractGraph)
    for idx in shuffle(1:length(agent_list))
        update_perceiv_publ_opinion!(g, idx, agent_list)
        update_opinion!(agent_list, idx)
        update_inclin_interact!(agent_list, idx)
        # like()
        drop_worst_input(g,idx, agent_list)
        add_input(g,idx, agent_list)
        if rand() < agent_list[idx].inclin_interact
            publish_tweet!(agent_list, g, idx)
        end
        update_timeline!(agent_list, idx)
    end
end

# the actual simulation
function simulate(g::AbstractGraph, agent_list::AbstractArray, n_iter::Integer)
    agent_list = deepcopy(agent_list)
    g = deepcopy(g)
    for n in 1:n_iter
        tick!(agent_list, g)
    end
    return g, agent_list
end

# suppress output of include()
;
