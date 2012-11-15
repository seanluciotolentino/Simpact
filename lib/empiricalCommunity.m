function communityID = empiricalCommunity(populationsize, community_members)
% populationsize: number of people that need a community ID
communities = ceil(populationsize*2/community_members);
communityID = floor(communities*rand(1,populationsize))+1;
end