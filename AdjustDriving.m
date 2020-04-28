function AdjustDriving(ev_id, pindex_start, pindex_end)
	global behaviours
	
	% 取消电量不够的出行计划
	ev_cost_power = behaviours.v_driving_cost_power(ev_id, pindex_start : pindex_end);
    
    soc_start = GetPreviousSOC(ev_id, pindex_start);
    
    org_is_driving = behaviours.v_is_driving(ev_id, pindex_start : pindex_end);
	new_is_driving = CancelDriving(org_is_driving, ev_cost_power, soc_start);
    
    behaviours.v_is_driving(ev_id, pindex_start : pindex_end) = new_is_driving;
	
	% 更新出行状态
	UpdateDriving(ev_id, pindex_start, pindex_end);
end


function new_is_driving = CancelDriving(org_is_driving, ev_cost_power, soc_start)
	global battery_features
	global mc_params
    
	soc_cost = cumsum(ev_cost_power, 2) / battery_features.power;
	soc_remain = soc_start - soc_cost;
	
	no_power_index = find(soc_remain < 0.0);
	new_is_driving = org_is_driving;
	new_is_driving(no_power_index) = 0;
    
    if (length(no_power_index) > 0) && mc_params.output
        fprintf('－－－－－no power lead to cancel travel, len=%d－－－－－\n', length(no_power_index));
    end
end