function UpdateDischarge(ev_id, start_index, end_index)
    %global mc_params
    global battery_features
    global behaviours
    global solutions
    
    % 初始放电状态
    periods = start_index:end_index;
    behaviours.v_ev_w_discharged(ev_id, periods) = single(0);
    
    if solutions.enable_discharge && start_index > 1
        % 符合放电要求，电网从该EV回收电能并提供价格补偿
        pre_soc = GetPreviousSOC(ev_id, start_index);
        ev_index = find(pre_soc > 0.8);
        
        discharge_capacity = battery_features.power * (pre_soc(ev_index) - 0.5);
        
        behaviours.v_ev_w_discharged(ev_id(ev_index), start_index) = discharge_capacity;
    end
end

