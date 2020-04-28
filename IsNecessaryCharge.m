function [is_necessary, soc_start] = IsNecessaryCharge(ev_id, pindex_start, pindex_end)
	%global behaviours
    global battery_features
    
    % soc低于0.2时必须充电
	soc_start = GetPreviousSOC(ev_id, pindex_start);
	is_necessary = (soc_start < battery_features.lowest_soc);
end