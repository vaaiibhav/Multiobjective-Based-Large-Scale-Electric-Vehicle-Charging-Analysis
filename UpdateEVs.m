%% all electric vehicles are updated during one period
function UpdateEVs()
    global mc_params
    global behaviours
    
	%start_pi = mc_params.cperiod_start_id;
	%end_pi = mc_params.cperiod_end_id;
    
    v_able_charge = behaviours.v_able_charge;
    v_is_driving = behaviours.v_is_driving;
	
	for ev=1:mc_params.total_EVs
		% test data
		%arr_ev_state = [2 2 2 2 2 1 1 1 0 0 1];
		arr_ev_state = int8( (v_able_charge(ev, :) * 2) + v_is_driving(ev, :) );
		
		k = Int32_Find( [true diff(arr_ev_state)~=0 true] );
		r = k(1:end-1);
		q = diff(k);
		
		driving_pi = r( find( arr_ev_state(r) == 1 ) );
		charge_pi = r( find( arr_ev_state(r) == 2 ) );
        
        if mc_params.output
            fprintf('������������ %d �ڣ�ģ��� %d ���������� %d �죬�ֳ� %d ����ͬʱ�Σ���������\n', ...
                        mc_params.cur_day, ev, mc_params.total_days, length(r));
        end
		
		for i=1:length(r)
            index = r(i);
			p_len = q(i);
			start_index = index;
			end_index = index + p_len - 1;
			
			if ismember(index, driving_pi)				% ������ʻ״̬
				% ������ʻ���
				AdjustDriving(ev, start_index, end_index);
			elseif ismember(index, charge_pi)	% ����ɳ��״̬
				% ���³��״̬
				AdjustCharging(ev, start_index, end_index);
			else 										% idle
				
			end
			
			UpdateSOC(ev, start_index, end_index);
		end
		
	end
	
    
end

