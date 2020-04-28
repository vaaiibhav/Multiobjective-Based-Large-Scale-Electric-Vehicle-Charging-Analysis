function UpdateCharging(ev_id, start_index, end_index)
    %global mc_params
    %global battery_features
    global behaviours
    
    periods = start_index:end_index;
    v_is_charging = behaviours.v_is_charging(ev_id, periods);
    
	% 计算EV充电量 及 电网负荷
    [v_ev_w_charged, v_grid_w_consumed] = CalEVsPowerCharged(v_is_charging);
    
    % EV因充电获得的能量
    behaviours.v_ev_w_charged(ev_id, periods) = v_ev_w_charged;
    
    % 电网因EV充电消耗的能量
    arr_grid_w_consumed = CalGridPowerLoad(v_grid_w_consumed);
    if isfield(behaviours, 'grid_power_load') && ...
            length(behaviours.grid_power_load) > 0
        cur_load = behaviours.grid_power_load(1, periods);
        behaviours.grid_power_load(1, periods) = cur_load + arr_grid_w_consumed;
        
    else
        behaviours.grid_power_load(1, periods) = arr_grid_w_consumed;
        
    end
end


function [v_ev_w_charged, v_grid_w_consumed] = CalEVsPowerCharged(v_is_charging)
    global g2v_features
    
    % total_EVs X total_periods (values: Wh)
    v_grid_w_consumed = single(v_is_charging * g2v_features.grid_w_consumed);
    v_ev_w_charged = single(v_is_charging * g2v_features.ev_w_charged);
end


function arr_grid_w_consumed = CalGridPowerLoad(v_grid_w_consumed)
    % 1 X total_periods (values: Wh)
    arr_grid_w_consumed = sum(v_grid_w_consumed, 1);
end