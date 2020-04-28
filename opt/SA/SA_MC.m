function [bestWCoeff, bestMinSOC] = SA_MC(CreatePopFcn, SingleFitnessFcn, ...
                                        nVars, nPopSize, nIters)
    
    % for reproducibility
    rng(1,'twister');
    
    % is all genes in one group: (1 * 40) or (5 * 8)
    is_gene_group = true;
    
    % nVars * 8(uint8)
    if is_gene_group
        nGenes = nVars * 8;
        nGroups = 1;
    else
        nGenes = 8;
        nGroups = nVars;
    end
    
    % set options
%     opt.PopulationSize = nPopSize;
%     opt.Generations = nIters;
    
    % Random value of variable (starting point)
%     sampleSchedule = CreatePopFcn(nGenes, [], opt);
    sampleSchedule = PopFunction(nGroups, nGenes);
    
    % SingleFitnessFcn was defined earlier
    %fitnessfcn = @(x) sa_mulprocfitness(x, SingleFitnessFcn);
    fitnessfcn = SingleFitnessFcn;

    %% Simulated Annealing Options Setup
    % We choose the custom annealing and plot functions that we have created,
    % as well as change some of the default options. |ReannealInterval| is set to
    % 800 because lower values for |ReannealInterval| seem to raise the temperature
    % when the solver was beginning to make a lot of local progress. We also
    % decrease the |StallIterLimit| to 800 because the default value makes the
    % solver too slow. Finally, we must set the |DataType| to 'custom'.
    options = saoptimset( 'DataType', 'custom', 'AnnealingFcn', @sa_mulprocpermute, ...
        'StallIterLimit',5000, 'ReannealInterval', 60, 'PlotInterval', 5, ...
        'PlotFcns', {@saplotf,@saplotbestf},...
        'MaxIter',nIters, 'TemperatureFcn', @temperatureexp,'OutputFcn',@OutputFunc );
    
    %%
    % Finally, we call simulated annealing with our problem information.
    [schedule, fval, exitflag, output] = simulannealbnd(fitnessfcn, sampleSchedule, [], [], options);
    
    % convert back to percent(%)
    [bestWCoeff, bestMinSOC] = Bin2VarByConstraint(schedule);

end


function [xPop] = PopFunction(nVars, nGenes)
    RD = rand;
    xPop = (rand(nVars, nGenes) > RD);
end


function [stop,options,optchanged] = OutputFunc(options,optimvalues,flag)
    global all_scores
    
    % record historical scores
    all_scores(:, optimvalues.iteration + 1) = optimvalues.fval;
    
    stop = false;
    optchanged = false;
end