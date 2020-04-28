function [bestWCoeff, bestMinSOC] =  PSO_MC(CreatePopFcn, FitnessFcn, ...
                                        nVars, nPopSize, nIters)
    % for reproducibility
    %rand('seed',1);
    rng(1,'twister');
    
    % nVars * 8(uint8)
    nGenes = nVars * 8;

    % set option
    options.PopulationType = 'bitstring' ;
    options.PopulationSize = nPopSize;
    options.Generations = nIters;
    options.TolFun = 1e-15;
    options.StallTimeLimit = inf;
    options.StallGenLimit = inf;
    options.Display = 'iter';
    options.DemoMode = 'off';    %'fast'
    options.PlotFcns = {@psoplotbestf};
    options.OutputFcns = @OutputFunc;
    %options.UseParallel = 'always';
    options.InitialPopulation = CreatePopFcn(nGenes, [], options);
    
    problem.options = options ;
    problem.Aineq = [] ; problem.bineq = [] ;
    problem.Aeq = [] ; problem.beq = [] ;
    problem.LB = [] ; problem.UB = [] ;
    problem.nonlcon = [] ;
    
    problem.fitnessfcn = FitnessFcn;
    problem.nvars = nGenes;
    
    [chromosome, y_fit,~,~,~,~] = pso(problem);
    
    % convert back to percent(%)
    [bestWCoeff, bestMinSOC] = Bin2VarByConstraint(chromosome);
end


function [state,options] = OutputFunc(options,state,flag)
    global all_scores
    
    % record historical scores
    all_scores(:, state.Generation) = state.Score;
end