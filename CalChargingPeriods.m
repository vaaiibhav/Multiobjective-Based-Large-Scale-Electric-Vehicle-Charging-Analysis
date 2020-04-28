% ���ݲ�ͬ���ԣ�������ʼ���ʱ��
function [start_cperiod, end_cperiod] = CalChargingPeriods(is_necessary, cur_soc, ...
										pindex_start, pindex_end)
    %global solutions
	global battery_features
	%global mc_params
	%global TOU_EPrice
    
	% ��ʼ����
    start_cperiod = 0;
	end_cperiod = 0;
    
    earliest = pindex_start;
    latest = pindex_end - battery_features.fcharge_periods + 1;
    
    % �����ĳһʱ����������ƽ�����
    arrMCost = CalChargePrices(earliest:latest);
    
    % ���ݲ��ԣ�����ÿһʱ�γ�����ȼ�
    [will_charge, best_prior, best_idx] = ...
        CalChargingPrior(is_necessary, cur_soc, arrMCost, pindex_start, pindex_end);
    
    % ��������µ���ѳ����ֹʱ��
    if will_charge
        start_cperiod = best_idx;
        end_cperiod = start_cperiod + battery_features.fcharge_periods - 1;
    end
    
end