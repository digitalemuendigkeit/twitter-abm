# imports
using LightGraphs
using SimpleWeightedGraphs
using MetaGraphs
using Statistics
using Random
using GraphPlot, Compose
import Cairo, Fontconfig
using Colors

# tweet class
mutable struct Tweet
    opinion::AbstractFloat
    weight::Integer
    like_count::Integer
    comment_count::Integer
    retweet_count::Integer
    function Tweet(opinion, weight, like_count=0, comment_count=0, retweet_count=0)
        # check if opinion value is valid
        if opinion < -1 || opinion > 1
            error("invalid opinion value")
        end
        new(opinion, weight, like_count, comment_count, retweet_count)
    end
end

# agent class
mutable struct Agent
    opinion::AbstractFloat
    inclin_interact::AbstractFloat
    perceiv_publ_opinion::AbstractFloat
    timeline::AbstractArray
    function Agent(opinion, inclin_interact, timeline=Array{Tweet, 1}(undef, 0))
        # check if opinion value is valid
        if opinion < -1 || opinion > 1
            error("invalid opinion value")
        end
        # check if value for inclination to interact is valid
        if inclin_interact < 0 || inclin_interact > 1
            error("invalid value for inclination to interact")
        end
        new(opinion, inclin_interact, opinion, timeline)
    end
end

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

# this algorithm is modelled after the python networkx implementation:
# https://github.com/networkx/networkx/blob/master/networkx/generators/random_graphs.py#L655
function barabasi_albert_directed(n::Int64, m0::Int64, seed::Int64)
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

# compute the perceived public opinion of an agent
function update_perceiv_publ_opinion(g::AbstractGraph, v::Integer, a::AbstractArray)
    # get neighborhood opinion as baseline
    following = outneighbors(g, v)
    if length(following) != 0
        following_opinion_mean = mean([a[f].opinion for f in following])  # weighted?
    else
        following_opinion_mean = a[v].opinion
    end
    # compute timeline opinion 
    timeline_opinions = [t.opinion for t in a[v].timeline]
    timeline_weights = [t.weight for t in a[v].timeline]
    if length(timeline_opinions) > 0 
        timeline_opinion_mean = (
            sum([a * b for (a, b) in zip(timeline_opinions, timeline_weights)]) / 
            sum(timeline_weights)
        )
    else
        timeline_opinion_mean = a[v].opinion
    end
    # perceived public opinion is the mean between the timeline and neighborhood opinion
    return mean([following_opinion_mean, timeline_opinion_mean])
end

# initialize agent list
function create_agents(g::AbstractGraph)
    agent_list = Array{Agent, 1}(undef, length(vertices(g)))
    for i in 1:length(agent_list)
        agent_list[i] = Agent(generate_opinion(), generate_inclin_interact())
    end
    return agent_list
end

# tweet function for agents
function tweet(g::AbstractGraph, v::Integer)
    print("hello")
end





### --- TESTING AREA --- ####

# test tweeting to other agents timeline
t = Tweet(0.2, 2000)
a = Agent(0.5, 0.5, 0.5)
push!(a.timeline, t)

# test network setup and agent creation
g = barabasi_albert_directed(100, 3, 2)
a = create_agents(g)

# test compute_perceiv_publ_opinion()
for ag in 1:nv(g)
    print(update_perceiv_publ_opinion(g, ag, a), "\n")
end

# test plotting
gplot(g, layout=spring_layout, arrowlengthfrac=0.03)

# test if follower distribution is actually exponential
using Plots
follower_dist = [indegree(g, i) for i in vertices(g)]
gr()
plot(follower_dist)

# utility for neighbor follower_count
n_followers(g, n) = sum([indegree(g, i) == n for i in vertices(g)])