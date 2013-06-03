function vartimeexact = decay_n_var_relation(startn, stopn, hazard)

% plots variance of time from startn to stopn as a function of startn;

vartimeexact = NaN(1,startn-stopn);
meantimeexact = NaN(1,startn-stopn);

for i = stopn+1:startn,
    vartimeexact(i) = sum(1./((hazard.*(i:-1:stopn+1)).^2));
%     meantimeexact(i) = sum(1./(hazard.*(i:-1:stopn+1)));
%     
%     varmeanratio = sqrt(vartimeexact)./meantimeexact;
    
    
end

plot(stopn+1:startn,vartimeexact)




