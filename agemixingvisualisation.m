% Age Mixing pattern visualisation

% rows: from no funnel to wide funnel
% columns: from no to large age difference growth

f=figure(1); % High penalty for deviation from preferred 
for i=1:9
    subplot(3,3,i)
    filename = sprintf('SDS%d28May.mat',i-1);
    load(filename);
    aS = ageScatter(SDS);
end
[ax,h1]=suplabel('Age Difference growth'); 
[ax,h2]=suplabel('Dispersion effect (funnel)','y'); 
[ax,h3]=suplabel('Small deviation from preferred' ,'t'); 
set(h3,'FontSize',16)
filename = 'SmallDeviation';
print(f, '-djpeg', filename);
print(f, '-dpdf', filename);

f=figure(2); % Medium penalty for deviation from preferred 
for i=10:18
    subplot(3,3,i-9)
    filename = sprintf('SDS%d28May.mat',i-1);
    load(filename);
    aS = ageScatter(SDS);
end
[ax,h1]=suplabel('Age Difference growth'); 
[ax,h2]=suplabel('Dispersion effect (funnel)','y'); 
[ax,h3]=suplabel('Medium deviation from preferred' ,'t'); 
set(h3,'FontSize',16) 
filename = 'MediumDeviation';
print(f, '-djpeg', filename);
print(f, '-dpdf', filename);

f=figure(3); % Low penalty for deviation from preferred 
for i=19:27
    subplot(3,3,i-18)
    filename = sprintf('SDS%d28May.mat',i-1);
    load(filename);
    aS = ageScatter(SDS);
end
[ax,h1]=suplabel('Age Difference growth'); 
[ax,h2]=suplabel('Dispersion effect (funnel)','y'); 
[ax,h3]=suplabel('Large deviation from preferred' ,'t'); 
set(h3,'FontSize',16)
filename = 'LargeDeviation';
print(f, '-djpeg', filename);
print(f, '-dpdf', filename);
