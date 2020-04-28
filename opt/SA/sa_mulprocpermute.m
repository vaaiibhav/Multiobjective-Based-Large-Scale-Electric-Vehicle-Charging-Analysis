function schedule = sa_mulprocpermute(optimValues,problemData)
    % MULPROCPERMUTE changes random bits.
    % NEWX = MULPROCPERMUTE(optimValues,problemData) generate a point based
    % on the current point and the current temperature

    schedule = optimValues.x;
    
    nVars = size(schedule, 1);
    nGenes = size(schedule, 2);
    nMutes = ceil(min(optimValues.temperature(1),100) / 100 * nGenes);
    
    if nMutes == 0 %&& rem(optimValues.iteration, 10) == 0
        sum(schedule, 2)
    end
    
    for i = 1:nVars
        idx = randsample(1:nGenes, nMutes);
%         rd = rand;
%         new_values = (rand(1, nMutes) > rd);
%         schedule(i, idx) = new_values;
        
        schedule(i, idx) = 1 - schedule(i, idx);
    end

end
