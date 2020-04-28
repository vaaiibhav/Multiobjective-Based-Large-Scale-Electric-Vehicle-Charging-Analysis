function DrawSolutionIndices()

    clc
    close all
    clear
    
    %% load solution result
    all_std_indices = {};
    for i=1:4
        y_indices = LoadData(sprintf('./data/temp_result_EVs(240000)_Days(100)_Slt(%d).mat', i));
        [~, all_std_indices{i}, ~] = CalVariances(y_indices);
    end
    
    %% init parameters
    n_days	= size(all_std_indices{1}, 2);
    n_sols	= length(all_std_indices);
    
    %% draw the min values
    figure;
    
    x_tick = (1:5:n_days);

    semilogy(all_std_indices{1}(x_tick),'Marker','d', 'Color', 'b');
    hold on
    semilogy(all_std_indices{2}(x_tick),'Marker','s', 'Color', 'k');
    semilogy(all_std_indices{3}(x_tick),'Marker','*', 'Color', 'g');
    semilogy(all_std_indices{4}(x_tick),'Marker','v', 'Color', 'm');

    axis([0 90 0 0.1]);

    x_label = 0:5:90;
    set(gca, 'XTickMode', 'manual');
    set(gca,'xtick',0:1:90);
    set(gca,'XTickLabel',x_label);

    set(gca, 'YTickMode', 'manual');
    set(gca,'ytick',0:0.01:0.1);

    % title(['\fontsize{12}\bf Convergence curves']);
     xlabel('\fontsize{18}\bf Iteration');
     ylabel('\fontsize{18}\bf The variance coefficient of Y');
     legend('\fontsize{15}\bf Randomness',...
             '\fontsize{15}\bf Tariff guidance',...
             '\fontsize{15}\bf Parking-charging',...
             '\fontsize{15}\bf Multi-objectives',1);
     grid on
     axis tight
end


function y_indices = LoadData(mat_data)
    load(mat_data);
    y_indices   = result.y_indices;
end
