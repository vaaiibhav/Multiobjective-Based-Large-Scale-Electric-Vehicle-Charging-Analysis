function best_fit = sa_mulprocfitness(schedule, SingleFitnessFcn)
    %MULPROCFITNESS determines the "fitness" of the given schedule.
    %  In other words, it tells us how long the given schedule will take using the
    %  knowledge given by "lengths"

    [nrows ncols] = size(schedule);
    best_fit = zeros(1,nrows);
    
    for i = 1:nrows
        best_fit(i) = SingleFitnessFcn( schedule(i, :) );
    end
    best_fit = min(best_fit);

end