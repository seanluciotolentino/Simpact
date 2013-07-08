function aS = ageScatter(SDS)

count = sum(SDS.relations.ID(:, SDS.index.male) ~= 0);
maleAge = nan(1, count);
femaleAge = nan(1, count);

for ii = 1 : count
    maleAge(ii) = SDS.relations.time(ii, SDS.index.start) - ...
        SDS.males.born(SDS.relations.ID(ii, SDS.index.male));
    femaleAge(ii) = SDS.relations.time(ii, SDS.index.start) - ...
        SDS.females.born(SDS.relations.ID(ii, SDS.index.female));
    
        % testing colour coding for the ID of the men
    %colourID(ii) = SDS.relations.ID(ii, SDS.index.male);
    
    
end

aS = scatter(maleAge, femaleAge, 15, 'filled');
set(get(gca,'XLabel'),'string','age men')
set(get(gca,'YLabel'),'string','age women')
set(gca,'YLim',[0,100],'XLim',[0,100])
line([0,100],[0,100])

%xlabel(hAxes, 'male age')
%ylabel(hAxes, 'female age ')



end