function t = transmissionTime(P, P0now, Tformation, T, alpha, beta)
% transmissionTime given random number P, P0now = P0.now, Tformation =
% external time of relationship formation
expLinear = spTools('handle', 'expLinear');
intExpLinear = spTools('handle', 'intExpLinear');
if Tformation<=T(1)
    alpha = alpha+beta*(T(1:3)-Tformation)';
    if P0now>=T(3)
        t = expLinear(alpha(3),beta,P0now-T(3),P);
    else %P0now<T(3)
        if P0now>=T(2)
            t = expLinear(alpha(2),beta, P0now-T(2),P);
            if t > T(3)-P0now
                Pc =intExpLinear(alpha(2),beta,P0now-T(2),T(3)-T(2));
                P = P-Pc;
                t = expLinear(alpha(3),beta,0,P) + T(3) - P0now;
            end
        else % P0now<=T1
            t = expLinear(alpha(1),beta, P0now-T(1),P);
            if t>T(2)-P0now
                Pc =intExpLinear(alpha(1),beta,P0now-T(1),T(2)-T(1));
                P = P-Pc;
                t = expLinear(alpha(2),beta,0,P) + T(2) - P0now;
                if t> T(3)-P0now
                    Pc =intExpLinear(alpha(2),beta,0,T(3)-T(2));
                    P = P-Pc;
                    t = expLinear(alpha(3),beta,0,P) + T(3) - P0now;
                end
            end
        end
    end
else % Tformation>T(1)
    if P0now>=T(3)
        t = expLinear(alpha(3),beta,P0now-Tformation,P);
    else %P0now<T(3)
        if P0now>=T(2)
            t = expLinear(alpha(2),beta, P0now-Tformation,P);
            if t > T(3)-P0now
                Pc =intExpLinear(alpha(2),beta,P0now-Tformation,T(3)-Tformation);
                P = P-Pc;
                t = expLinear(alpha(3),beta,0,P) + T(3) - P0now;
            end
        else % P0now<=T1
            t = expLinear(alpha(1),beta, P0now-Tformation,P);
            if t>T(2)-P0now
                Pc =intExpLinear(alpha(1),beta,P0now-Tformation,T(2)-Tformation);
                P = P-Pc;
                t = expLinear(alpha(2),beta,0,P) + T(2) - P0now;
                if t> T(3)-P0now
                    Pc =intExpLinear(alpha(2),beta,0,T(3)-T(2));
                    P = P-Pc;
                    t = expLinear(alpha(3),beta,0,P) + T(3) - P0now;
                end
            end
        end
    end
    
end
end