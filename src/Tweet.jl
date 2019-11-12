mutable struct Tweet
    opinion::AbstractFloat
    weight::AbstractFloat
    like_count::Integer
    comment_count::Integer
    retweet_count::Integer
    function Tweet(opinion, weight)
        # check if opinion value is valid
        if opinion < -1 || opinion > 1
            error("invalid opinion value")
        end
        if weight < 0
            error("invalid weight value")
        end
        new(opinion, weight, 0, 0, 0)
    end
end

# suppress output of include()
;