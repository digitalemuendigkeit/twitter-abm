using Statistics
using LightGraphs
using StatsBase

mutable struct Agent
    opinion::Float64
    inclin_interact::Float64
    perceiv_publ_opinion::Float64
    check_regularity::Float64
    active::Bool
    inactive_ticks::Int16
    feed::Array{Tweet, 1}
    liked_Tweets::Array{Tweet, 1}
    retweeted_Tweets::Array{Tweet, 1}
    function Agent(opinion, inclin_interact, check_regularity)
        # check if opinion value is valid
        if opinion < -1 || opinion > 1
            error("invalid opinion value")
        end
        # check if value for inclination to interact is valid
        if inclin_interact < 0
            error("invalid value for inclination to interact")
        end
        new(
            opinion, 
            inclin_interact, 
            opinion, 
            check_regularity, 
            true, 
            0, 
            Array{Tweet, 1}(undef, 0), 
            Array{Tweet, 1}(undef, 0), 
            Array{Tweet, 1}(undef, 0)
        )
    end
end

function update_perceiv_publ_opinion!(
    graph::AbstractGraph, agent_list::AbstractArray, agent::Integer
)
    this_agent = agent_list[agent]
    # get neighborhood opinion as baseline
    input = outneighbors(graph, agent)
    if length(input) != 0
        input_opinion_mean = mean([agent_list[input_agent].opinion for input_agent in input])
    else
        input_opinion_mean = this_agent.opinion
    end
    # compute feed opinion
    feed_opinions = [tweet.opinion for tweet in this_agent.feed]
    feed_weights = [tweet.weight for tweet in this_agent.feed]
    if length(feed_opinions) > 0
        feed_opinion_mean = (
            sum([opinion * weight for (opinion, weight) in zip(feed_opinions, feed_weights)]) /
            sum(feed_weights)
        )
    else
        feed_opinion_mean = this_agent.opinion
    end
    # perceived public opinion is the mean between the feed and neighborhood opinion
    this_agent.perceiv_publ_opinion = mean([input_opinion_mean, feed_opinion_mean])
end

function update_opinion!(
    agent_list::AbstractArray, agent::Integer,
    opinion_thresh::AbstractFloat=0.3, base_weight::AbstractFloat=0.99
)
    this_agent = agent_list[agent]
    # weighted mean of own opinion and perceived public opinion
    if (abs(this_agent.opinion - this_agent.perceiv_publ_opinion) < opinion_thresh)
        this_agent.opinion = (
            base_weight * this_agent.opinion 
            + (1 - base_weight) * this_agent.perceiv_publ_opinion
        )
    else
        if ((this_agent.opinion * this_agent.perceiv_publ_opinion > 0) 
            && (abs(this_agent.opinion) - abs(this_agent.perceiv_publ_opinion) < 0))
            this_agent.opinion = base_weight * this_agent.opinion
        else
            this_agent.opinion = (2 - base_weight) * this_agent.opinion
        end
        if this_agent.opinion > 1
            this_agent.opinion = 1
        elseif this_agent.opinion < -1
            this_agent.opinion = -1
        end
    end
end

function update_check_regularity!(
    agent_list::AbstractArray, agent::Integer, 
    opinion_thresh::AbstractFloat=0.3, decrease_factor::AbstractFloat=0.9
)
    this_agent = agent_list[agent]
    if (abs(this_agent.opinion - this_agent.perceiv_publ_opinion) > opinion_thresh)
        this_agent.check_regularity = decrease_factor * this_agent.check_regularity
    else
        this_agent.check_regularity = 1.0
    end
end

function like(
    agent_list::AbstractArray, agent::Integer, 
    opinion_thresh::AbstractFloat=0.2
)
    this_agent = agent_list[agent]
    inclin_interact = deepcopy(this_agent.inclin_interact)
    i = 1
    while inclin_interact > rand()
        if i < length(this_agent.feed)
            if ((abs(this_agent.feed[i].opinion - this_agent.opinion) < opinion_thresh) 
                && !(this_agent.feed[i] in this_agent.liked_Tweets))
                this_agent.feed[i].like_count += 1
                this_agent.feed[i].weight *= 1.01
                push!(this_agent.liked_Tweets, this_agent.feed[i])
            end
        else
            break
        end
        i += 1
        inclin_interact -= 1
    end
end

function drop_input!(
    graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, 
    opinion_thresh::AbstractFloat=0.5
)
    this_agent = agent_list[agent]
    # look for current input tweets that have too different opinion compared to own
    # and remove them if source agent opinion is also too different
    for tweet in this_agent.feed
        if abs(tweet.opinion - this_agent.opinion) > opinion_thresh
            if abs(agent_list[tweet.source_agent].opinion - this_agent.opinion) > opinion_thresh
                rem_edge!(graph, tweet.source_agent, agent)
            end
        end
    end
end

function add_input!(
    graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, 
    new_input_count::Integer=4
)
    # neighbors of neighbors
    input_candidates = Integer[]
    for neighbor in inneighbors(graph, agent)
        append!(input_candidates, setdiff(inneighbors(graph, neighbor), inneighbors(graph, agent)))
    end
    shuffle!(input_candidates)
    # Order neighbors by frequency of occurence in input_candidates descending
    input_queue = first.(sort(collect(countmap(input_candidates)), by=last, rev=true))
    # add edges
    if (length(input_queue) - new_input_count) < 0
        new_input_count = length(input_queue)
    end
    for _ in 1:new_input_count
        add_edge!(graph, popfirst!(input_queue), agent)
    end
end

function set_inactive!(
    graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, tweet_list::AbstractArray
)
    this_agent = agent_list[agent]
    this_agent.active = false
    agent_edges = [e for e in edges(graph) if (src(e) == agent || dst(e) == agent)]
    for e in agent_edges
        rem_edge!(graph, e)
    end
    empty!(this_agent.feed)
    for t in tweet_list
        if t.source_agent == agent
            t.weight = -1
        end
    end
    return true
end

function retweet!(
    graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, 
    opinion_thresh::AbstractFloat=0.1
)
    this_agent = agent_list[agent]
    for tweet in this_agent.feed
        if ((abs(this_agent.opinion - tweet.opinion) <= opinion_thresh) 
            && !(tweet in this_agent.retweeted_Tweets))
            tweet.weight *= 1.01
            tweet.retweet_count += 1
            push!(this_agent.retweeted_Tweets, tweet)
            for neighbor in outneighbors(graph, agent)
                push!(agent_list[neighbor].feed, tweet)
            end
            break
        end
    end
end

function publish_tweet!(
    graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, tweet_list::AbstractArray, 
    tick_nr::Integer=0
)
    this_agent = agent_list[agent]
    tweet_opinion = this_agent.opinion + 0.1 * (2 * rand() - 1)
    # upper opinion limit is 1
    if tweet_opinion > 1
        tweet_opinion = 1.0
    # lower opinion limit is -1
    elseif tweet_opinion < -1
        tweet_opinion = -1.0
    end
    tweet = Tweet(tweet_opinion, length(outneighbors(graph, agent)), agent, tick_nr)
    push!(tweet_list, tweet)
    # send tweet to each outneighbor
    for neighbor in outneighbors(graph, agent)
        push!(agent_list[neighbor].feed, tweet)
    end
end

function update_feed!(
    graph::AbstractGraph, agent_list::AbstractArray, agent::Integer, 
    decay_factor::AbstractFloat=0.5
)
    this_agent = agent_list[agent]
    unique!(this_agent.feed)
    deletedTweets = Integer[]
    for (index,tweet) in enumerate(this_agent.feed)
        if tweet.weight == -1 || !(tweet.source_agent in inneighbors(graph, agent))
            push!(deletedTweets,index)
        else
            tweet.weight = decay_factor * tweet.weight
        end
    end
    deleteat!(this_agent.feed,deletedTweets)
    sort!(this_agent.feed, lt=<, rev=true)
    if length(this_agent.feed) > 10
        this_agent.feed = this_agent.feed[1:10]
    end
end

# suppress output of include()
;
