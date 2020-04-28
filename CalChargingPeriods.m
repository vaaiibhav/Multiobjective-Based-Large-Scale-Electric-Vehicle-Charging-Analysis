% 根据不同策略，计算起始充电时段
function [start_cperiod, end_cperiod] = CalChargingPeriods(is_necessary, cur_soc, ...
										pindex_start, pindex_end)
    %global solutions
	global battery_features
	%global mc_params
	%global TOU_EPrice
    
	% 初始参数
    start_cperiod = 0;
	end_cperiod = 0;
    
    earliest = pindex_start;
    latest = pindex_end - battery_features.fcharge_periods + 1;
    
    % 计算从某一时段起充电所需平均电价
    arrMCost = CalChargePrices(earliest:latest);
    
    % 根据策略，计算每一时段充电优先级
    [will_charge, best_prior, best_idx] = ...
        CalChargingPrior(is_necessary, cur_soc, arrMCost, pindex_start, pindex_end);
    
    % 计算策略下的最佳充电起止时间
    if will_charge
        start_cperiod = best_idx;
        end_cperiod = start_cperiod + battery_features.fcharge_periods - 1;
    end
    
end