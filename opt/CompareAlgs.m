function CompareAlgs()
    clc
    close all
    clear
    
    %% load result scores
    ga_scores = LoadData('/opt/scores/OPT_result_Alg(1)_PopSize(100)_Gens(200)_ev(100)_day(30)_el(0-2)_mu(0-1)_ragT(994).mat');
    pso_scores = LoadData('/opt/scores/OPT_result_Alg(2)_PopSize(100)_Gens(200)_ev(100)_day(30)_C(09-05-05)_ragT(994).mat');
    sa_scores = LoadData('/opt/scores/OPT_result_Alg(3)_PopSize(1)_Gens(2000).mat');
    
    all_scores = {};
    all_scores{1} = ga_scores;
    all_scores{2} = pso_scores;
    all_scores{3} = sa_scores;
    
    %% init parameters
    n_pop = size(pso_scores, 1);
    n_iter = size(pso_scores, 2);
    n_type = 2; %length(all_scores);
    score_mean = zeros(n_type, n_iter);
    score_min = zeros(n_type, n_iter);
    
    %% calculate mean & min of scores
    % GA & PSO
    for iter = 1:n_iter
        for aType = 1:n_type
            scores = all_scores{aType};
            score_mean(aType, iter) = mean( scores(:, iter) );
            score_min(aType, iter) = min( scores(:, iter) );
        end
    end
    
    % SA
    for iter = 1:size(sa_scores, 2)
        scores = sa_scores;
        sa_score_mean(1, iter) = mean( scores(:, iter) );
        sa_score_min(1, iter) = min( scores(:, 1:iter) );
    end
    
    
    %% draw results for GA & PSO
    figure;
    lcolors = ['r', 'b'];
    lstyles = ['*', '.'];
    
    subplot(1,2,1);
    for ptc_type = 1:n_type
        DrawScores(score_mean(ptc_type, :), lcolors(ptc_type), lstyles(ptc_type));
    end
    legend('GA', 'PSO');
    title('The mean fitness of population', 'FontSize', 16);
    
    subplot(1,2,2);
    for ptc_type = 1:n_type
        DrawScores(score_min(ptc_type, :), lcolors(ptc_type), lstyles(ptc_type));
    end
    legend('GA', 'PSO');
    title('The best fitness of population', 'FontSize', 16);
    
    % mean & best score
    fprintf( 'GA-----mean score: %f \n', mean(ga_scores(:, end)) );
    fprintf( 'GA-----best score: %f \n', min(min(ga_scores)) );
    fprintf( 'PSO-----mean score: %f \n', mean(pso_scores(:, end)) );
    fprintf( 'PSO-----best score: %f \n', min(min(pso_scores)) );
end


function scores = LoadData(mat_data)
    load(mat_data);
    scores = all_scores;
end

function DrawScores(scores, line_color, line_style)
    %figure;
    plot(scores, 'Color', line_color, 'linestyle', line_style);
    hold on
    
    %axis( [0 24 0 (max(trv_num_pp) + 4e3)] );
    %set(gca,'xtick',0:1:24);
    
    xlabel('Iterations', 'FontSize', 14);
    ylabel('(1 - Y)', 'FontSize', 14);
end
