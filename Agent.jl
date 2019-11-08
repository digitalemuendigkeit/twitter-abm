# agent class
mutable struct Agent
end

function update_perceiv_publ_opinion()
    # mean of input neighbors and current timeline
end

function update_opinion()
    # 0.8 * own_opinion + 0.2 * perceiv_publ_opinion
end

function update_inclin_interact()
    # if 0.1 * abs(own_opinion - perceiv_publ_opinion) + 0.9 * own_inclin_interact  
end

function like()
end

function drop_worst_input()
end

function add_input()
end

function publish_tweet()
end






