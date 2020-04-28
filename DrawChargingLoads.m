function DrawChargingLoads()

    clc
    close all
    clear
    
    %% load results by charging strategy id
    w_load      = {};
    for i=1:4
        w_load{i} = LoadData(sprintf('./data/temp_result_EVs(240000)_Days(100)_Slt(%d).mat', i));
    end
    
    n_periods = size(w_load{1}, 2);
    
    %% draw the power load
    figure;
    
    x_tick = (1:4:n_periods);

    semilogy(w_load{1}(x_tick),'Marker','d', 'Color', 'b');
    hold on
    semilogy(w_load{2}(x_tick),'Marker','s', 'Color', 'k');
    semilogy(w_load{3}(x_tick),'Marker','*', 'Color', 'g');
    semilogy(w_load{4}(x_tick),'Marker','v', 'Color', 'm');

    axis([0 n_periods 1e4 1e10]);

    x_label = 1:1:n_periods;
    set(gca, 'XTickMode', 'manual');
    set(gca,'xtick',1:1:n_periods);
    set(gca,'XTickLabel',x_label);

%     set(gca, 'YTickMode', 'manual');
%     set(gca,'ytick',[1e4 1e10]);

    
    xlabel('\fontsize{18}\bf Hours');
    ylabel('\fontsize{18}\bf Power Load (W)');
    legend('\fontsize{15}\bf Randomness',...
             '\fontsize{15}\bf Tariff guidance',...
             '\fontsize{15}\bf Parking-charging',...
             '\fontsize{15}\bf Multi-objectives', 4);
     grid on
     axis tight
end


function w_load = LoadData(mat_data)
    load(mat_data);
    grid        = result.grid;
    w_load      = mean(single(grid.power_load), 1);
end

