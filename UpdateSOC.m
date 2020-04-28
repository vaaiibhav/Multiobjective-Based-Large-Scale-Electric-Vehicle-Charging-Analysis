function UpdateSOC(ev_id, start_index, end_index)
	global battery_features
    global behaviours
	
	v_ev_w_charged = behaviours.v_ev_w_charged(ev_id, start_index : end_index);
	v_ev_w_lost = behaviours.v_driving_cost_power(ev_id, start_index : end_index);
	v_ev_w_discharged = behaviours.v_ev_w_discharged(ev_id, start_index : end_index);
    
	add_soc = v_ev_w_charged / battery_features.power;
    lost_soc = v_ev_w_lost / battery_features.power;
    discharge_soc = v_ev_w_discharged / battery_features.power;
    
    % 充电与耗电时段不能有重叠
    dp_soc = add_soc .* lost_soc;
    if length( find( dp_soc ~= 0 ) ) > 0
        error
    end
    
    pre_soc = GetPreviousSOC(ev_id, start_index);
    behaviours.soc(ev_id, start_index : end_index) = pre_soc + ...
                             cumsum(add_soc - lost_soc - discharge_soc, 2);
    
    behaviours.soc(ev_id, end_index:end) = behaviours.soc(ev_id, end_index);
end