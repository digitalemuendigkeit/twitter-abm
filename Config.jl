struct Config
    agent_count::Int64  # create_agents => agent_count & create_network => n
    network_m0::Int64  # create_network => m0
    network_growth_rate::Int64  # simulate => growth
    simulation_n_iter::Int64  # simulate => n_iter
    max_inactive_ticks::Int64  # tick => max_inactive_ticks
    opinion_backfire_thresh::Float64  # update_opinion => opinion_thresh
    own_opinion_weight::Float64  # update_opinion => base_weight
    check_unease_thresh::Float64  # update_check_regularity => opinion_thresh
    check_decrease_factor::Float64  # update_check_regularity => decrease_factor
    like_opinion_thresh::Float64  # like => opinion_thresh
    unfollow_opinion_thresh::Float64  # drop_input => opinion_thresh
    n_new_follows::Int64  # add_input => new_input_count
    retweet_opinion_thresh::Float64  # retweet => opinion_thresh
    tweet_decay_factor::Float64  # update_feed => decay_factor
    inclin_interact_lambda::Float64  # generate_inclin_interact => lambda

    function Config(
        ;
        agent_count=0, 
        network_m0=0,
        network_growth_rate=0,
        simulation_n_iter=0,
        max_inactive_ticks=0,
        opinion_backfire_thresh=0.0,
        own_opinion_weight=0.0,
        check_unease_thresh=0.0,
        check_decrease_factor=0.0,
        like_opinion_thresh=0.0,
        unfollow_opinion_thresh=0.0,
        n_new_follows=0,
        retweet_opinion_thresh=0.0,
        tweet_decay_factor=0.0,
        inclin_interact_lambda=0.0
    )
        new(
            agent_count,
            network_m0, 
            network_growth_rate,
            simulation_n_iter,
            max_inactive_ticks,
            opinion_backfire_thresh,
            own_opinion_weight,
            check_unease_thresh,
            check_decrease_factor,
            like_opinion_thresh,
            unfollow_opinion_thresh,
            n_new_follows,
            retweet_opinion_thresh,
            tweet_decay_factor,
            inclin_interact_lambda
        )
    end
end

c = Config()

d = Config(
    agent_count=100, 
    network_m0=15,  
    network_growth_rate=4, 
    simulation_n_iter=100, 
    max_inactive_ticks=2, 
    opinion_backfire_thresh=0.5, 
    own_opinion_weight=0.9, 
    check_unease_thresh=0.5, 
    check_decrease_factor=0.5, 
    like_opinion_thresh=0.3, 
    unfollow_opinion_thresh=0.4, 
    n_new_follows=4, 
    retweet_opinion_thresh=0.5, 
    tweet_decay_factor=0.5, 
    inclin_interact_lambda=0.5
)

d