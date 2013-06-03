function [CD4_500,CD4_350,CD4_200]=CD4Interp(CD4_infection,CD4_death,t,now)

acute = 0.25;
if t<= acute
    CD4_500 = t-interp1q([CD4_death,CD4_infection]',[0,t]',500) + now;
    CD4_350 = t-interp1q([CD4_death,CD4_infection]',[0,t]',350) + now;
    CD4_200 = t-interp1q([CD4_death,CD4_infection]',[0,t]',200) + now;
else
    CD4_500 = t-interp1q([CD4_death,0.75*CD4_infection,CD4_infection]',[0,(t-0.25),t]',500) + now;
    CD4_350 = t-interp1q([CD4_death,0.75*CD4_infection,CD4_infection]',[0,(t-0.25),t]',350) + now;
    CD4_200 = t-interp1q([CD4_death,0.75*CD4_infection,CD4_infection]',[0,(t-0.25),t]',200) + now;

end
end