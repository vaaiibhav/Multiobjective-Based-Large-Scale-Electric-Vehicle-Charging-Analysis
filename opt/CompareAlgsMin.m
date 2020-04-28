function CompareAlgsMin()

    clc
    close all
    clear
    
    %% load result scores
    ga_scores   = LoadData('/opt/scores/OPT_result_Alg(1)_PopSize(100)_Gens(200)_ev(100)_day(30)_el(0-2)_mu(0-1)_ragT(994).mat');
    pso_scores  = LoadData('/opt/scores/OPT_result_Alg(2)_PopSize(100)_Gens(200)_ev(100)_day(30)_C(09-05-05)_ragT(994).mat');
    sa_scores   = LoadData('/opt/scores/OPT_result_Alg(3)_PopSize(1)_Gens(2000).mat');
    
    all_scores      = {};
    all_scores{1}   = ga_scores;
    all_scores{2}   = pso_scores;
    all_scores{3}   = sa_scores;
    
    %% init parameters
    n_iter      = 200;
    n_type      = length(all_scores);
    score_min   = zeros(n_type, n_iter);
    
    %% calculate min value of scores
    for iter = 1:n_iter
        for aType = 1:n_type
            scores = all_scores{aType};
            
            if iter <= size(scores, 2);
                score_min(aType, iter) = min( min( scores(:, 1:iter) ) );
            else
                score_min(aType, iter) = score_min(aType, iter-1);
            end
        end
    end
    
    
    %% draw the min values
    figure;
    
    x_tick = (1:10:n_iter);

    semilogy(score_min(1,x_tick),'Marker','d', 'Color', 'b');
    hold on
    semilogy(score_min(2,x_tick),'Marker','s', 'Color', 'm');
    semilogy(score_min(3,x_tick),'Marker','*', 'Color', 'g');

    axis([0 200 0 0.7]);

    x_label = 0:10:200;
    set(gca, 'XTickMode', 'manual');
    set(gca,'xtick',0:1:200);
    set(gca,'XTickLabel',x_label);

    set(gca, 'YTickMode', 'manual');
    set(gca,'ytick',0:0.05:0.7);

    % title(['\fontsize{12}\bf Convergence curves']);
     xlabel('\fontsize{18}\bf Iteration');
     ylabel('\fontsize{18}\bf Best Fitness');
     legend('\fontsize{15}\bf GA',...
             '\fontsize{15}\bf PSO',...
             '\fontsize{15}\bf SA', 1);
     grid on
     axis tight
end


function scores = LoadData(mat_data)
    load(mat_data);
    scores = all_scores;
end
