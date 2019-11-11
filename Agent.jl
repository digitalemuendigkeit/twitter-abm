using Statistics
using LightGraphs

# agent class
mutable struct Agent
    opinion::AbstractFloat
    inclin_interact::AbstractFloat
    perceiv_publ_opinion::AbstractFloat
    timeline::AbstractArray
    function Agent(opinion, inclin_interact)
        # check if opinion value is valid
        if opinion < -1 || opinion > 1
            error("invalid opinion value")
        end
        # check if value for inclination to interact is valid
        if inclin_interact < 0 || inclin_interact > 1
            error("invalid value for inclination to interact")
        end
        new(opinion, inclin_interact, opinion, Array{Tweet, 1}(undef, 0))
    end
end

# compute the perceived public opinion of an agent
function update_perceiv_publ_opinion!(g::AbstractGraph, v::Integer, a::AbstractArray)
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
    a[v].perceiv_publ_opinion = mean([following_opinion_mean, timeline_opinion_mean])
end

function update_opinion!(agent_list::AbstractArray, index::Integer, base_weight::AbstractFloat=0.8)
    # weighted mean of own opinion and perceived public opinion
    agent_list[index].opinion = (
        base_weight * agent_list[index].opinion + 
        (1 - base_weight) * agent_list[index].perceiv_publ_opinion
    )
end

function update_inclin_interact!(agent_list::AbstractArray, index::Integer, base_weight::AbstractFloat=0.9)
    # weighted mean of current inclination to interact and 
    # absolute difference between own and perceived public opinion 
    agent_list[index].inclin_interact = (
        (1 - base_weight) * abs(agent_list[index].opinion - agent_list[index].perceiv_publ_opinion) +
        base_weight * agent_list[index].inclin_interact
    )
end

function like()
end

function drop_worst_input()
end

function add_input()
end

function publish_tweet!(agent_list::AbstractArray, g::AbstractGraph, index::Integer)
    tweet_opinion = agent_list[index].opinion + rand(-0.1:0.0000001:0.1)
    if tweet_opinion > 1
        tweet_opinion = 1.0
    end
    t = Tweet(tweet_opinion, length(outneighbors(g, index)))
    for v in outneighbors(g, index)
        push!(agent_list[v].timeline, t)
        if length(agent_list[v].timeline) > 10
            min_weight = minimum([t.weight for t in agent_list[v].timeline])
            del_idx = findfirst([t.weight == min_weight for t in agent_list[v].timeline])
            deleteat!(agent_list[v].timeline, del_idx)
        end
    end
end

function update_timeline!(agent_list::AbstractArray, index::Integer, decay_factor::AbstractFloat=0.5)
    for t in agent_list[index].timeline
        t.weight = decay_factor * t.weight
    end
end

# suppress output of include()
;
