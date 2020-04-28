% http://open-power-system-data.org/data-sources
% https://www.entsoe.eu/data/statistics/Pages/monthly_hourly_load.aspx
function DrawHourlyLoad(mw_ev_load)

	% Unit: MW
% 	ls_hourly_load = xlsread('./data/hourly_load_4.xls');
    load './data/hourly_load.mat';
    
    % grid loads from origin & ev
	mw_org_load      = ls_hourly_load(:, 2)';
    mw_ev_load       = mw_ev_load(1:4:96) * 1e-6;
    mw_total_load    = mw_org_load + mw_ev_load;
    
    % curve of load
    DrawStackBar(mw_org_load, mw_ev_load, mw_total_load);
%     DrawLoadCurve(mw_org_load, mw_ev_load, mw_total_load);
end


function DrawLoadCurve(mw_org_load, mw_ev_load, mw_total_load)
    figure;
    
    plot(mw_org_load, '--bo', 'LineWidth', 1.2);
    hold on
    plot(mw_total_load, '-.r*', 'LineWidth', 1.2);
    
    axis( [0 25 0.9e4 1.6e4] );
    set(gca,'xtick',0:1:24);
    %set(gca,'ytick',0:1:10);
    
    xlabel('Hours', 'FontSize', 12);
    ylabel('Power Load (W)', 'FontSize', 12);
    
    % Add a legend
    legend('Usual Load', 'EVs Charging Load');
    grid on
end


function DrawStackBar(mw_org_load, mw_ev_load, mw_total_load)
    figure;
    
    H = bar(1:24, [mw_org_load' mw_ev_load'], 0.6, 'stack');
    
%     P = findobj(gca,'type','patch');
%     set(P(1),'FaceColor', [0 .5 .5], 'EdgeColor', [0 .9 .9], 'LineWidth', 1.5);
%     set(P(2),'FaceColor', [0 .4 .4], 'EdgeColor', [0 .8 .8], 'LineWidth', 1.5);

    % Adjust the axis limits
%     axis( [0 25 0.9e9 1.8e9] );
    axis( [0 25 0.9e4 1.6e4] );
    set(gca,'xtick',0:1:24);

    % Add title and axis labels
%     title('Childhood diseases by month')
    xlabel('Hours', 'FontSize', 12);
    ylabel('Power Load (MW)', 'FontSize', 12);

    % Add a legend
    legend(H, {'Usual Load', 'EVs Charging Load'});
    grid on
end


