function expEventTimes

a = 0:0.1:5;
b = -5:0.1:-0.1;
expT = nan(length(a),length(b));
medianT = nan(length(a),length(b));
for i = 1:length(a)
    for j = 1:length(b)
        
        rnd = rand(1,200);
        rnd = -log(rnd);
        x = rnd.*b(j)./exp(a(i))+1;
        eventTime = log(x)./b(j);
        eventTime(x<0)= Inf;
        expT(i,j) = mean(eventTime);
        medianT(i,j) = median(eventTime);
    end
end

grid = meshgrid(a,b);

end


