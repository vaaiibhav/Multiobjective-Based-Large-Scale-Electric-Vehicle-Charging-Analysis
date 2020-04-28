function [grid, ev_behaviour, mday_indices] = StatisticPowerLoad(result)
    global mc_params
    global solutions
    
    % calculate every single indices
    grid = result.grid;
    ev_behaviour = result.ev_behaviour;
    y_indices = result.y_indices;
    
    v_real_trv = ev_behaviour.trv_num_per_period;
    v_plan_trv = ev_behaviour.plan_trv_num_per_period;
    v_mis_trv = ev_behaviour.plan_trv_num_per_period - ev_behaviour.trv_num_per_period;
    
    m_w_load = mean(single(grid.power_load), 1);
    m_w_charged = mean(single(grid.power_charged), 1);
    m_w_v2g = mean(single(grid.power_V2G), 1);
    
    m_real_trv = mean(single(v_real_trv), 1);
    m_plan_trv = mean(single(v_plan_trv), 1);
    m_mis_trv = mean(single(v_mis_trv), 1);
    
    % caculate final multiple��indices
    [mday_indices, mday_Rmp, mday_Rsc, mday_Rt] = CalIndices(m_w_load, m_w_charged, ...
                              m_real_trv, m_plan_trv, false);
    [y_vars, y_stds, y_indices] = CalVariances(y_indices);
    
    % output results
    if mc_params.output == true
        % draw curve of power load
%         DrawPowerLoad(m_w_load, '������������ (Wh)', '����ÿ���ʱ�ε�ƽ������', true);
%         DrawPowerLoad(m_w_charged, 'EV������� (Wh)', 'EVÿ���ʱ�ε�ƽ�������', true);
%         DrawPowerLoad(m_w_v2g, 'V2G���� (Wh)', 'EVÿ���ʱ�ε�ƽ���ŵ���', false);
%         
%         % draw curve of ev behaviour
%         DrawPowerLoad(m_real_trv, 'ʵ�ʳ��д���', 'EVÿ���ʱ�ε�ƽ�����д���', true);
%         DrawPowerLoad(m_mis_trv, '�����������', '��������㣬EVÿ���ʱ�ε�ƽ��������д���', false);
%         
%         % draw indices
%         DrawIndices(y_indices, y_stds);
        
        % draw orginal/ev-charged/total load curve
        DrawHourlyLoad(m_w_load);

        % print results
        fprintf('--------------------------------- \n');
        fprintf('ģ������---------%d ��\n', mc_params.total_days);
        fprintf('������------%d ��\n', mc_params.total_EVs);
        fprintf('ÿ��������ɷ�ֵ------%d ��\n', max(m_w_load));
        fprintf('ÿ��������ɾ�ֵ------%d ��\n', mean(m_w_load));
        fprintf('ÿ��������ɾ����------%f\n', (mean(m_w_load)/max(m_w_load)));
        fprintf('ÿ�����������------%f\n', (max(m_w_load)/1560e7));
        fprintf('ÿ�������������------%d ��\n', sum(m_w_load));
%         fprintf('������Ȳ�---------%d ��\n', max(m_w_load) - min(m_w_load));
%         fprintf('EV����ֵ---------%d ��\n', max(m_w_charged));
%         fprintf('EV�ŵ��ֵ---------%d ��\n', max(m_w_v2g));
        fprintf('--------------------------------- \n');
%         fprintf('ÿ��EV�������---------%d ��\n', sum(m_w_charged));
%         fprintf('ÿ��EV�ŵ�����---------%d ��\n', sum(m_w_v2g));
        fprintf('�ۺ�����ָ��------%f\n', mday_indices);
        fprintf('�ۺϸ��ɾ����------%f\n', mday_Rmp);
        fprintf('�ۺϵ�ѽ�ʡ��------%f\n', mday_Rsc);
        fprintf('�ۺ�˳��������------%f\n', mday_Rt);
        fprintf('--------------------------------- \n');
    end
    
end



function m_wload = DrawPowerLoad(m_wload, y_label, p_title, is_patch)
    global mc_params
    
    % һ���и�ʱ�ε�ƽ������
    %m_wload = mean(single(grid_power_load), 1);
    
    % axis
    x_interval = 24 / mc_params.periods_per_day;
    X = 0 : x_interval : (24-x_interval);
    
    y_max = max(m_wload);
    if y_max <= 0
        y_max = 1;
    end
    
    % display
    figure;
    plot(X, m_wload);
    axis([0 24 0 y_max]);
    set(gca,'xtick',0:1:24);
    %set(gca,'ytick',0:0.1:1);
    xlabel('ʱ��');
    ylabel(y_label);
    grid on
    
    % darw patch if need
    if is_patch
        % ��߷�ʱ�Σ�90%
        p_seperate = mc_params.periods_per_day/2;
        x_data = X(1 : p_seperate);
        y_data = m_wload(1 : p_seperate);
        [xlo, ylo] = DrawPatch(x_data, y_data, 1.0);

        % ��߷�ʱ�Σ�90%
        x_data = X(p_seperate + 1 : mc_params.periods_per_day);
        y_data = m_wload(p_seperate + 1 : mc_params.periods_per_day);
        [xlo, ylo] = DrawPatch(x_data, y_data, 1.0);
    end
    
    title(p_title);
end


function DrawIndices(Y, y_vars)
    global mc_params
    
    % axis
    X = 1 : 1 : length(Y);
    
    % display
    figure;
    plot(X, Y, '--bo', 'LineWidth', 1.2);
    axis([1 length(Y) 0 1]);
    set(gca,'xtick',1:25:length(Y));
    set(gca,'ytick', 0:0.1:1);
    xlabel('Days');
    ylabel('Indices (Y)');
    grid off
    
    title('Indices by days');
    
    % variance coefficients of Y
    figure;
    X = 1 : 1 : length(y_vars);
    plot(X, y_vars, '-.r*', 'LineWidth', 1.2);
    %axis([1 length(Y) 0 1]);
    set(gca,'xtick',1:25:length(y_vars));
    %set(gca,'ytick', 0:0.1:1);
    xlabel('Days');
    ylabel('Variances of Indice');
    grid on
        
    title('Indice variances by days');
end


function Draw_Load_Discharge(grid_power_load, ev_discharge)
    global mc_params
    
    % һ���и�ʱ�ε�ƽ������ �� �ŵ���
    m_wload = mean(grid_power_load, 1);
    m_wdischarge = mean(ev_discharge, 1);
    
    x_interval = 24 / mc_params.periods_per_day;
    X = 0 : x_interval : (24-x_interval);
    
    figure;
    plot(X, m_wload, '-.bo', 'LineWidth', 1.2);
    hold on
    plot(X, m_wdischarge, '-.r*', 'LineWidth', 1.2);
    
    axis([0 24 0 (max(m_wload) + 1e7)]);
    set(gca,'xtick',0:1:24);
    xlabel('Periods of One Day', 'FontSize', 12);
    ylabel('Power (W)', 'FontSize', 12);
    grid on
    
    legend('Power Load of Grid', 'V2G Power');
end


function DrawTravelBehaviour(ev_behaviour)
    global mc_params
    
    figure;
    %% travel frequency
    subplot(2,2,1);
    X = [];
    [X_data, Y_data] = DrawPDFTravel(ev_behaviour.freq, X, 'ÿ����д���');
    DrawPatch(X_data, Y_data, 0.9);
    
    %% travel mileage
    subplot(2,2,2);
    X = [];
    [X_data, Y_data] = DrawPDFTravel(round(ev_behaviour.km_per_trv), X, 'ÿ�˳�����̣�km��');
    DrawPatch(X_data, Y_data, 0.9);
    
    %% travel duration
    subplot(2,2,3);
    X = [];
    [X_data, Y_data] = DrawPDFTravel(round(ev_behaviour.mins_per_trv), X, 'ÿ�˳���ʱ����minutes��');
    DrawPatch(X_data, Y_data, 0.9);
    
    %% start travel time
    subplot(2,2,4);
    x_interval = 24 / mc_params.periods_per_day;
    X = 0 : x_interval : (24-x_interval);
    [X_data, Y_data] = DrawPDFTravel(ev_behaviour.trv_start, X, 'ÿ�����ʱ��');
    set(gca,'xtick',0:1:24);
    
    x_len = length(X_data);
    DrawPatch(X_data(1:x_len/2), Y_data(1:x_len/2), 0.9); % ��߷�ʱ�Σ�90%
    DrawPatch(X_data((x_len/2+1):end), Y_data((x_len/2+1):end), 0.9); % ��߷�ʱ�Σ�90%
end


function [X, Y, p] = DrawPDFTravel(data, X_values, label_x)
    % convert to number-percent type
    tab_data = tabulate(data);
    x_num = tab_data(:, 1)';
    y_perc = tab_data(:, 3)' / 100;
    
    if length(X_values) > 0
        X = X_values;
    else
        X = x_num;
    end
    Y = y_perc;
    
    p = plot(X, Y, 'LineWidth', 1.2);
    xlabel(label_x);
    ylabel('�����ܶ� (%)');
    axis( [0 max(X) 0 max(Y)] );
end


function DrawStartCharging(ev_behaviour)
    global mc_params
    
    x_interval = 24 / mc_params.periods_per_day;
    X = 0 : x_interval : (24-x_interval);
    
    figure;
    %% the time period of finishing travel
    [X_data, Y_data] = DrawPDFTravel(ev_behaviour.trv_end, X, 'ʱ��');
    set(gca,'xtick',0:1:24);
    
    hold on
    
    %% the time period of starting charging
    [X_data, Y_data, p] = DrawPDFTravel(ev_behaviour.cha_start, X, 'ʱ��');
    set(gca,'xtick',0:1:24);
    set(p,'Color','red', 'LineStyle', '--');
    
    legend('ÿ����н���ʱ��', 'ÿ�쿪ʼ���ʱ��');
    %title('�Աȳ��н������翪ʼʱ��');
end


function Draw_Travel_Charge(ev_behaviour)
    global mc_params
    
    % total_days X total_peirods
    trv_num_pp = mean(ev_behaviour.trv_num_per_period, 1);
    cha_num_pp = mean(ev_behaviour.cha_num_per_period, 1);
    dischar_num_pp = mean(ev_behaviour.dischar_num_per_period, 1);
    
    x_interval = 24 / mc_params.periods_per_day;
    X = 0 : x_interval : (24-x_interval);
    
    figure;
    % the number of EVs in travel at different periods
    plot(X, trv_num_pp, ':bs');
    hold on
    % the number of EVs in charging at different periods
    plot(X, cha_num_pp, '-.r*');
    hold on
    % the number of EVs in discharging at different periods
    plot(X, dischar_num_pp, '-.m.');
    grid on
    
    axis( [0 24 0 (max(trv_num_pp) + 4e3)] );
    set(gca,'xtick',0:1:24);
    
    xlabel('Periods of One Day', 'FontSize', 12);
    ylabel('The Number of Electric Vehicles', 'FontSize', 12);
    legend('Evs in Driving', 'EVs in Charging', 'EVs in Discharging');
end


