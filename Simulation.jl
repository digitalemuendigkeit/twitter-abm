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

function tick()
    # update_perceiv_publ_opinion()
    # update_opinion()
    # update_inclin_interact()
    # like()
    # drop_worst_input()
    # add_input()
    # publish_tweet()
end

function simulate(n_iter)
    # for n in 1:n_iter
    #     tick()
    # end
end

# suppress output of include()
;