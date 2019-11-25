using Statistics
using LightGraphs

mutable struct Agent
    opinion::AbstractFloat
    inclin_interact::AbstractFloat
    perceiv_publ_opinion::AbstractFloat
    activity::AbstractFloat
    feed::AbstractArray
    function Agent(opinion, inclin_interact, activity)
        # check if opinion value is valid
        if opinion < -1 || opinion > 1
            error("invalid opinion value")
        end
        # check if value for inclination to interact is valid
        if inclin_interact < 0
            error("invalid value for inclination to interact")
        end
        new(opinion, inclin_interact, opinion, activity,Array{Tweet, 1}(undef, 0))
    end
end

function update_perceiv_publ_opinion!(graph::AbstractGraph, agent_list::AbstractArray, agent::Integer)
    # get neighborhood opinion as baseline
    input = outneighbors(graph, agent)
    if length(input) != 0
        input_opinion_mean = mean([agent_list[input_agent].opinion for input_agent in input])
    else
        input_opinion_mean = agent_list[agent].opinion
    end
    # compute feed opinion
    feed_opinions = [tweet.opinion for tweet in agent_list[agent].feed]
    feed_weights = [tweet.weight for tweet in agent_list[agent].feed]
    if length(feed_opinions) > 0
        feed_opinion_mean = (
            sum([opinion * weight for (opinion, weight) in zip(feed_opinions, feed_weights)]) /
            sum(feed_weights)
        )
    else
        feed_opinion_mean = agent_list[agent].opinion
    end
    # perceived public opinion is the mean between the feed and neighborhood opinion
    agent_list[agent].perceiv_publ_opinion = mean([input_opinion_mean, feed_opinion_mean])
end

function update_opinion!(agent_list::AbstractArray, agent::Integer, base_weight::AbstractFloat=0.95)
    # weighted mean of own opinion and perceived public opinion
    if (abs(agent_list[agent].opinion - agent_list[agent].perceiv_publ_opinion) < 0.3)
        agent_list[agent].opinion = (
            base_weight * agent_list[agent].opinion +
            (1 - base_weight) * agent_list[agent].perceiv_publ_opinion
            )
        agent_list[agent].activity = 1.2 * agent_list[agent].activity
        if agent_list[agent].activity > 1
            agent_list[agent].activity = 1
        end
        else
            agent_list[agent].activity = 0.95 * agent_list[agent].activity
    # else
    #     agent_list[agent].opinion = 1.02 * agent_list[agent].opinion
    #     if agent_list[agent].opinion > 1
    #         agent_list[agent].opinion = 1
    #     elseif agent_list[agent].opinion < -1
    #         agent_list[agent].opinion = -1
    #     end
    end
end

function update_inclin_interact!(agent_list::AbstractArray, agent::Integer, base_weight::AbstractFloat=0.9)
    # weighted mean of current inclination to interact and
    # absolute difference between own and perceived public opinion
    agent_list[agent].inclin_interact = (
        (1 - base_weight) * abs(agent_list[agent].opinion - agent_list[agent].perceiv_publ_opinion) +
        base_weight * agent_list[agent].inclin_interact
    )
end

function like()
end

function drop_worst_input(graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, opinion_thresh=0.5)
    # look for current input tweets that have too different opinion compared to own
    # and remove them if source agent opinion is also too different
    for tweet in agent_list[agent].feed
        if abs(tweet.opinion - agent_list[agent].opinion) > opinion_thresh
            if abs(agent_list[tweet.source_agent].opinion - agent_list[agent].opinion) > opinion_thresh
                rem_edge!(graph, tweet.source_agent, agent)
            end
        end
    end
end

function add_input(graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, new_input_count::Integer=4)
    # neighbors of neighbors
    input_candidates = Integer[]
    for neighbor in inneighbors(graph, agent)
        append!(input_candidates, setdiff(inneighbors(graph, neighbor), inneighbors(graph, agent)))
    end
    # occurrence counts of agents in input_candidates in reverse order
    weights = sort(unique([length(findall(x -> x == i, input_candidates)) for i in input_candidates]), rev=true)
    # final shuffled input queue
    input_queue = Integer[]
    for w in weights
        subset = shuffle(unique([i for i in input_candidates if length(findall(x -> x == i, input_candidates)) == w]))
        append!(input_queue, subset)
    end
    # add edges
    for _ in 1:new_input_count
        try
            add_edge!(graph, popfirst!(input_queue), agent)
        catch
            break
        end
    end
end

function publish_tweet!(graph::AbstractGraph, agent_list::AbstractArray, agent::Integer)
    tweet_opinion = agent_list[agent].opinion + rand(-0.1:0.0000001:0.1)
    # upper opinion limit is 1
    if tweet_opinion > 1
        tweet_opinion = 1.0
    # lower opinion limit is -1
    elseif tweet_opinion < -1
        tweet_opinion = -1.0
    end
    tweet = Tweet(tweet_opinion, length(outneighbors(graph, agent)), agent)
    # send tweet to each outneighbor
    for neighbor in outneighbors(graph, agent)
        push!(agent_list[neighbor].feed, tweet)
        if length(agent_list[neighbor].feed) > 10
            min_weight = minimum([t.weight for t in agent_list[neighbor].feed])
            del_idx = findfirst([t.weight == min_weight for t in agent_list[neighbor].feed])
            deleteat!(agent_list[neighbor].feed, del_idx)
        end
    end
end

function update_feed!(agent_list::AbstractArray, agent::Integer, decay_factor::AbstractFloat=0.5)
    for tweet in agent_list[agent].feed
        tweet.weight = decay_factor * tweet.weight
    end
end

# suppress output of include()
;
