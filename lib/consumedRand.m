function Pc = consumedRand(P0now, Tformation, T, Tlc, alpha, beta)
intExpLinear = spTools('handle', 'intExpLinear');
if Tformation>T(1)
    if P0now<T(2)
        Pc = intExpLinear(alpha(1), beta, Tlc-Tformation, P0now-Tformation);
    else
        if P0now<T(3)
            if Tlc>T(2)
                Pc =  intExpLinear(alpha(2), beta, Tlc-T(2),P0now-T(2));
            else
                Pc = intExpLinear(alpha(1), beta, Tlc-Tformation, T(2)-Tformation)...
                    +intExpLinear(alpha(2), beta, 0,P0now-T(2));
            end
        else %P0now>T3
            if Tlc>T(3)
                Pc = intExpLinear(alpha(3), beta, Tlc-T(3),P0now-T(3));
            else
                if Tlc>T(2)
                    Pc = intExpLinear(alpha(2), beta, Tlc-T(2), T(3)-T(2))...
                        +intExpLinear(alpha(3), beta, 0,P0now-T(3));
                else
                    Pc = intExpLinear(alpha(1), beta, Tlc-Tformation, T(2)-Tformation)...
                        +intExpLinear(alpha(2), beta, 0,T(3)-T(2))...
                        +intExpLinear(alpha(3), beta, 0,P0now-T(3));
                end
            end
        end
        
    end
    
else % Tformation <=T(1)
    alpha = alpha + beta*(T(1:3)-Tformation)';
    if P0now<T(2)
        Pc = intExpLinear(alpha(1), beta, Tlc-T(1), P0now-T(1));
    else % P0now>T2
        if P0now<T(3) % P0now~(T2,T3)
            if Tlc>T(2)
                Pc =  intExpLinear(alpha(2), beta, Tlc-T(2),P0now-T(2));
            else
                Pc = intExpLinear(alpha(1), beta, Tlc-T(1), T(2)-T(1))...
                    +intExpLinear(alpha(2), beta, 0,P0now-T(2));
            end
        else %P0now?T3
            if Tlc>T(3)
                Pc = intExpLinear(alpha(3), beta, Tlc-T(3),P0now-T(3));
            else
                if Tlc>T(2)
                    Pc = intExpLinear(alpha(2), beta, Tlc-T(2), T(3)-T(2))...
                        +intExpLinear(alpha(3), beta, 0,P0now-T(3));
                else
                    Pc = intExpLinear(alpha(1), beta, Tlc-T(1), T(2)-T(1))...
                        +intExpLinear(alpha(2), beta, 0,T(3)-T(2))...
                        +intExpLinear(alpha(3), beta, 0,P0now-T(3));
                end
            end
        end
        
    end
    
end


end