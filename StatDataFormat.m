function [grid, ev_behaviour, y_indices] = StatDataFormat()
    global mc_params
    global behaviours
    global solutions
    
    
    r_num = mc_params.total_days;
    c_num = mc_params.periods_per_day;
    
    PaddingData();
    
    % power grid in one day: Wh
    grid.power_load = reshape(behaviours.grid_power_load, c_num, r_num)';
    
    % power of ev charged
    arr_w_charged = sum(behaviours.v_ev_w_charged, 1);
    grid.power_charged = reshape(arr_w_charged, c_num, r_num)';
    
    % power from vehicle to grid
    arr_w_V2G = sum(behaviours.v_ev_w_discharged, 1);
    grid.power_V2G = reshape(arr_w_V2G, c_num, r_num)';
    
    % convert behaviours to statistic data
    ev_behaviour = FormatEVBehaviours();
    
    % calculate indices of everyday
    y_indices = FormatIndices(grid, ev_behaviour);
    
    % save statistic results
%     save(sprintf('statistic_data_EVs(%d)_Days(%d)_Slt(%d).mat', ...
%         mc_params.total_EVs, mc_params.total_days, solutions.start_charging), ...
%         'grid', 'ev_behaviour', 'y_indices', '-v7.3');
    
    % test data
%     load(sprintf('statistic_data_EVs(%d)_Days(%d)_Slt(%d).mat', ...
%         mc_params.total_EVs, mc_params.total_days, solutions.start_charging));
end


function PaddingData()
    global behaviours
    global mc_params
    
    total_periods = mc_params.total_days * mc_params.periods_per_day;
    cur_periods = size(behaviours.v_is_driving, 2);
    
    if (cur_periods < total_periods)
        v_zeros = false(mc_params.total_EVs, total_periods - cur_periods);
        behaviours.v_is_driving = [behaviours.v_is_driving v_zeros];
        behaviours.v_plan_driving = [behaviours.v_plan_driving v_zeros];
        behaviours.v_driving_km_pp = [behaviours.v_driving_km_pp v_zeros];
        behaviours.v_driving_cost_power = [behaviours.v_driving_cost_power v_zeros];
        behaviours.v_able_charge = [behaviours.v_able_charge v_zeros];
        behaviours.v_is_charging = [behaviours.v_is_charging v_zeros];
        behaviours.v_ev_w_charged = [behaviours.v_ev_w_charged v_zeros];
        behaviours.v_ev_w_discharged = [behaviours.v_ev_w_discharged v_zeros];
        
        arr_zeros = zeros(1, total_periods - cur_periods);
        behaviours.grid_power_load = [behaviours.grid_power_load arr_zeros];
        
        last_soc = behaviours.soc(:, end);
        v_last_soc = repmat(last_soc, 1, total_periods - cur_periods);
        behaviours.soc = [behaviours.soc v_last_soc];
        
    else
        behaviours.v_is_driving = behaviours.v_is_driving(:, 1:total_periods);
        behaviours.v_plan_driving = behaviours.v_plan_driving(:, 1:total_periods);
        behaviours.v_driving_km_pp = behaviours.v_driving_km_pp(:, 1:total_periods);
        behaviours.v_driving_cost_power = behaviours.v_driving_cost_power(:, 1:total_periods);
        behaviours.v_able_charge = behaviours.v_able_charge(:, 1:total_periods);
        behaviours.v_is_charging = behaviours.v_is_charging(:, 1:total_periods);
        behaviours.v_ev_w_charged = behaviours.v_ev_w_charged(:, 1:total_periods);
        behaviours.v_ev_w_discharged = behaviours.v_ev_w_discharged(:, 1:total_periods);
        behaviours.grid_power_load = behaviours.grid_power_load(:, 1:total_periods);
        behaviours.soc = behaviours.soc(:, 1:total_periods);
        
    end
end


function ev_behaviour = FormatEVBehaviours()
    global behaviours
    global mc_params
    
    total_periods = mc_params.total_days * mc_params.periods_per_day;
    
    % driving or charging
    ev_behaviour.trv_num_per_period = zeros(mc_params.total_days, mc_params.periods_per_day, 'int32');
    ev_behaviour.plan_trv_num_per_period = zeros(mc_params.total_days, mc_params.periods_per_day, 'int32');
    ev_behaviour.cha_num_per_period = zeros(mc_params.total_days, mc_params.periods_per_day, 'int32');
    ev_behaviour.dischar_num_per_period = zeros(mc_params.total_days, mc_params.periods_per_day, 'int32');
    
    % data conversion
    period = int32(1);
    day = int32(1);
    while (period <= total_periods)
        if mc_params.output == true
            fprintf('－－－－－－－转换第 %d-%d 天数据－－－－－－－\n', mc_params.cur_day, day);
        end
        
        % periods during one day
        day_periods = period : (period + mc_params.periods_per_day - 1);
        
        % 某天每一时段的出行／充电／放电的EV数
        v_is_driving = behaviours.v_is_driving(:, day_periods);
        v_plan_driving = behaviours.v_plan_driving(:, day_periods);
        v_is_charging = behaviours.v_is_charging(:, day_periods);
        
        v_w_discharging = behaviours.v_ev_w_discharged(:, day_periods);
        v_is_discharging = (v_w_discharging > 0);
        
        trv_num_pp = sum(v_is_driving, 1);
        plan_trv_num_pp = sum(v_plan_driving, 1);
        cha_num_pp = sum(v_is_charging, 1);
        dischar_num_pp = sum(v_is_discharging, 1);
        
        % total_days X total_peirods
        ev_behaviour.trv_num_per_period(day, :) = trv_num_pp;
        ev_behaviour.plan_trv_num_per_period(day, :) = plan_trv_num_pp;
        ev_behaviour.cha_num_per_period(day, :) = cha_num_pp;
        ev_behaviour.dischar_num_per_period(day, :) = dischar_num_pp;
        
        % next day
        period = period + mc_params.periods_per_day;
        day = day + 1;
    end
end


function StaticsticBehaviours(ev_behaviour)
    

end


function y_indices = FormatIndices(grid, ev_behaviour)
    global mc_params
    
    % indices for the charging solution: 1 X days
    days = mc_params.total_days;
    y_indices = single( zeros(1, days) );
    
    % calculate indices for everyday
    for d=1:days
        arr_w_Load = grid.power_load(d, :);
        arr_w_charged = grid.power_charged(d, :);
        
        arr_real_trv = ev_behaviour.trv_num_per_period(d, :);
        arr_plan_trv = ev_behaviour.plan_trv_num_per_period(d, :);
        
%         if d==1 || d==days
%             isprint = true;
%         else
            isprint = false;
%         end
        
        [Y, Rpv, Rc, Rt] = CalIndices(arr_w_Load, arr_w_charged, ...
                                        arr_real_trv, arr_plan_trv, isprint);
                                    
        y_indices(d) = Y;
    end
    
end

