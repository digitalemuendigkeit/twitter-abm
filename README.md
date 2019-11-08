# twitter-abm
An agent-based model of polarization on Twitter.


## Agents
Agents are the actors in our Twitter Model. They own the following attributes:
- **Opinion:** Value in [-1,1] that states the current opinion of the agent. Initialized via uniform distribution, adapted over time with function update_opinion()
- **Perceived public opinion:** Value in [-1,1] that states the perceived opinion of the  outneighbors of the agent. Updated via update_perceiv_publ_opinion()
- **Inclination to interact:** Value in [0,1] that states the willingness of an agent to publish new tweets. Initialized via exponential function (few agents with high inclination, most agents with low inclination), updated over time with function update_inclin_interact()
- **Timeline:** Array that holds the timeline that is accessed by the agent. Holds maximum 10 tweets inserted from input neighbors (see function publish_tweet())

Agents have the following functions:
- **update_opinion()**: The own opinion is updated via evaluating the difference between own and perceived public opinion and gradually approximating to the public opinion
- **update_inclin_interact()**: The inclination to interact is updated by evaluating the difference between own and perceived opinion. Inclination to interact rises, if own and public opinion are very similar and falls, if they have a big difference
- **update_perceiv_publ_opinion()**: Perceived public opinion is updated by including the opinion of all outneighbors and the opinions of the current tweets in the timeline of the agent
- **update_timeline():** Weights of the tweets in the agent's timeline are lowered over time so that currency of a tweet plays a role for its weight
- **publish_tweet()**: With considering the inclination to interact, an agent publishes new tweets and sends them to all inneighbors. If the timeline of an inneighbor is not full yet, tweet is automatically published in it. Otherwise weight of tweet is compared to weight of all other tweets in timeline and the tweet with the lowest weight is dropped (weights of existing tweets in timeline decay over time, see function update_timeline())
- **like()**: Agents can interact with the tweets in their timeline by liking them. Like_count of a tweet in turn increases its weight.
- **drop_worst_input()**: Removing the ingoing edge to neighbors that are over accepted opinion threshold
- **add_input**: Adding ingoing edges randomly to other agents, following preferential attachment?
