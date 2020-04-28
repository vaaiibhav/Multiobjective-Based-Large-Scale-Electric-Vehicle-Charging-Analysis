function isCharging = AdjustCharging(ev_id, pindex_start, pindex_end)
	global behaviours
	
    this_periods = pindex_start : pindex_end;
    
	% �ж��Ƿ�Ϊ�س�ʱ��
	[is_necessary, cur_soc] = IsNecessaryCharge(ev_id, pindex_start, pindex_end);
	
    % ����ʱ��ȫ��ǳɷǳ��״̬
    behaviours.v_is_charging(ev_id, this_periods) = 0;
    
	% ���ݲ�ͬ�������EV��ʼ��������ʱ��
% 	[start_cperiod, end_cperiod] = GetChargingState(is_necessary, ev_id, ...
% 										pindex_start, pindex_end);
    [start_cperiod, end_cperiod] = CalChargingPeriods(is_necessary, cur_soc, ...
										pindex_start, pindex_end);

    if start_cperiod == 0   % no charging periods
        isCharging = false;
        
        %��Ȼ�����磬�ͳ��Էŵ��Ի�ȡ�۸񲹳�
        UpdateDischarge(ev_id, pindex_start, pindex_end);
        
        return;
    else
        isCharging = true;
    end
	
	% ��ǳ��״̬
	behaviours.v_is_charging(ev_id, start_cperiod : end_cperiod) = 1;
	
	% ������ʱ��ȡ��֮��ĳ��ƻ�
	cur_soc = behaviours.soc(ev_id, this_periods);
    org_is_charging = behaviours.v_is_charging(ev_id, this_periods);
    new_is_charging = CancelCharging(org_is_charging, ev_id, cur_soc);
	behaviours.v_is_charging(ev_id, this_periods) = new_is_charging;
	
	% ���³��״̬
	UpdateCharging(ev_id, pindex_start, pindex_end);
end


function [start_cperiod, end_cperiod] = GetChargingState(is_necessary, ev_id, ...
										pindex_start, pindex_end)
    global solutions
	global battery_features
	global mc_params
	global TOU_EPrice
    
	% ���ݲ�ͬ���ԣ�������ʼ���ʱ��
    start_cperiod = 0;
	end_cperiod = 0;
    
    earliest = pindex_start;
    latest = pindex_end - battery_features.fcharge_periods + 1;
    
    % ������
    if solutions.start_charging == 1          % 1.ͣ����������
        start_cperiod = earliest;
		
    elseif solutions.start_charging == 2      % 2.���������
		shall_charge = is_necessary || RandUniform(1, 1, 0, 1);
		if shall_charge
			% ָ�� �ֲ�
			%start_cperiod = ExprndBounded(mean(earliest, latest), 1, earliest, latest);
			%start_cperiod = round(start_cperiod);
            
			% ���ȷֲ�
			% start_cperiod = RandSelect(earliest:latest, 1);
            
            % ͣ�������
            start_cperiod = earliest;
		end
		
    elseif solutions.start_charging == 3      % 3.�������������
		prices = CalChargePrices(earliest:latest);
		[min_price, min_index] = min(prices);
		is_resonable = min_price < TOU_EPrice.mprice;
		
		shall_charge = is_necessary || is_resonable;
		if shall_charge
			% �ӳ���ܼ���С��ʱ�ο�ʼ
			start_cperiod = earliest + min_index - 1;
		end
		
    end
	
    % ������Ч�����ֹʱ��
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
	% �ѳ�����ȡ����ʱ�γ��ƻ�
	ev_fcharged = find(p_soc > battery_features.full_soc);
	new_is_charging = org_is_charging;
	new_is_charging(ev_fcharged) = 0;
end



