% http://cn.mathworks.com/help/optim/write-constraints.html#brhkghv-16
% http://cn.mathworks.com/help/optim/ug/types-of-constraints.html
% http://cn.mathworks.com/help/gads/mixed-integer-optimization.html#bs1cifg)

function [bestWCoeff, bestMinSOC] = GA_MC(CreatePopFcn, FitnessFcn, ...
                                        nVars, nPopSize, nIters)
    % for reproducibility
    %rand('seed',1);
    rng(1,'twister');
    
    % nVars * 8(uint8)
    nGenes = nVars * 8;
    
    % set option
    tournamentSize = 2;
    nElites = round(nPopSize * 0.2);
    options = gaoptimset('CreationFcn', {CreatePopFcn},...
                         'PopulationSize',nPopSize,...
                         'Generations',nIters,...
                         'PopulationType', 'bitstring',... 
                         'SelectionFcn',{@selectiontournament,tournamentSize},...
                         'MutationFcn',{@mutationuniform, 0.1},...
                         'CrossoverFcn', {@crossovertwopoint},...
                         'EliteCount',nElites,...
                         'StallGenLimit',100,...
                         'PlotFcns',{@gaplotbestf},...  
                         'OutputFcns', {@OutputFunc},...
                         'Display', 'iter'); 
    
    %FitnessFcn = @FitFunc_MC;
    [chromosome, y_fit,~,~,~,~] = ga(FitnessFcn, nGenes, options);
    
    % convert back to percent(%)
    [bestWCoeff, bestMinSOC] = Bin2VarByConstraint(chromosome);
end


function[state,options,optchanged] = OutputFunc(options, state, flag)
    optchanged = false;
    % DO NOT set options, state, or flag!
    % Just write code to calculate whatever it is you want here.
    % If you need to read an option, then read it, don't set it.
    % Make sure that your options include @outputfun as your output function.
 
    global all_scores
    
    % record historical scores
    all_scores(:, state.Generation+1) = state.Score;
end





