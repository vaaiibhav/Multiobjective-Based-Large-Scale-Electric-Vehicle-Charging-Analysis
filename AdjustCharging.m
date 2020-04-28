function isCharging = AdjustCharging(ev_id, pindex_start, pindex_end)
	global behaviours
	
    this_periods = pindex_start : pindex_end;
    
	% 判断是否为必充时段
	[is_necessary, cur_soc] = IsNecessaryCharge(ev_id, pindex_start, pindex_end);
	
    % 将此时段全标记成非充电状态
    behaviours.v_is_charging(ev_id, this_periods) = 0;
    
	% 根据不同策略求出EV起始与结束充电时段
% 	[start_cperiod, end_cperiod] = GetChargingState(is_necessary, ev_id, ...
% 										pindex_start, pindex_end);
    [start_cperiod, end_cperiod] = CalChargingPeriods(is_necessary, cur_soc, ...
										pindex_start, pindex_end);

    if start_cperiod == 0   % no charging periods
        isCharging = false;
        
        %既然不需充电，就尝试放电以换取价格补偿
        UpdateDischarge(ev_id, pindex_start, pindex_end);
        
        return;
    else
        isCharging = true;
    end
	
	% 标记充电状态
	behaviours.v_is_charging(ev_id, start_cperiod : end_cperiod) = 1;
	
	% 当满充时，取消之后的充电计划
	cur_soc = behaviours.soc(ev_id, this_periods);
    org_is_charging = behaviours.v_is_charging(ev_id, this_periods);
    new_is_charging = CancelCharging(org_is_charging, ev_id, cur_soc);
	behaviours.v_is_charging(ev_id, this_periods) = new_is_charging;
	
	% 更新充电状态
	UpdateCharging(ev_id, pindex_start, pindex_end);
end


function [start_cperiod, end_cperiod] = GetChargingState(is_necessary, ev_id, ...
										pindex_start, pindex_end)
    global solutions
	global battery_features
	global mc_params
	global TOU_EPrice
    
	% 根据不同策略，计算起始充电时段
    start_cperiod = 0;
	end_cperiod = 0;
    
    earliest = pindex_start;
    latest = pindex_end - battery_features.fcharge_periods + 1;
    
    % 充电策略
    if solutions.start_charging == 1          % 1.停车即充电策略
        start_cperiod = earliest;
		
    elseif solutions.start_charging == 2      % 2.随机充电策略
		shall_charge = is_necessary || RandUniform(1, 1, 0, 1);
		if shall_charge
			% 指数 分布
			%start_cperiod = ExprndBounded(mean(earliest, latest), 1, earliest, latest);
			%start_cperiod = round(start_cperiod);
            
			% 均匀分布
			% start_cperiod = RandSelect(earliest:latest, 1);
            
            % 停车即充电
            start_cperiod = earliest;
		end
		
    elseif solutions.start_charging == 3      % 3.电价引导充电策略
		prices = CalChargePrices(earliest:latest);
		[min_price, min_index] = min(prices);
		is_resonable = min_price < TOU_EPrice.mprice;
		
		shall_charge = is_necessary || is_resonable;
		if shall_charge
			% 从充电总价最小的时段开始
			start_cperiod = earliest + min_index - 1;
		end
		
    end
	
    % 计算有效充电起止时间
	if start_cperiod > 0
		end_cperiod = start_cperiod + battery_features.fcharge_periods - 1;
	end
end


function new_is_charging = CancelCharging(org_is_charging, ev_id, cur_soc)
	global battery_features
	global behaviours
    global g2v_features
	
	add_soc = g2v_features.ev_w_charged / battery_features.power ...
				* org_is_charging;
	p_soc = cur_soc + cumsum(add_soc);
	% 已充满，取消该时段充电计划
	ev_fcharged = find(p_soc > battery_features.full_soc);
	new_is_charging = org_is_charging;
	new_is_charging(ev_fcharged) = 0;
end



