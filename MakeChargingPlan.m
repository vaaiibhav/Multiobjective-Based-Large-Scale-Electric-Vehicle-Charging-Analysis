%===========================================
%% һ������
function MakeChargingPlan()
    global behaviours
	global mc_params
    
    v_is_driving = behaviours.v_is_driving;
    
    % ���ƻ� ������ ���мƻ�
    [v_able_charge] = ChargingPlan(v_is_driving);
	v_is_charging = false(mc_params.total_EVs, mc_params.total_periods);
	
	% ���п��ܵĳ��ʱ��
	%behaviours.v_charge_earlist_pi = v_charge_earlist_pi;
	%behaviours.v_charge_latest_pi = v_charge_latest_pi;
	
	behaviours.v_able_charge = v_able_charge;
	behaviours.v_is_charging = v_is_charging;
end


%===========================================
%% ��������
function [v_able_charge] = ChargingPlan(v_is_driving)
    global mc_params
    
    % test data
    %v_is_driving = [0 0 1 1 1 0 0 0 0 0 1 0 1 1 0 0 0 0 0 0;
    %                1 1 1 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1;
    %                0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1];
    
	v_able_charge = false(mc_params.total_EVs, mc_params.total_periods);
    
    for i=1:mc_params.total_EVs
        ev_is_driving = v_is_driving(i, :);
        
        % ���� �ɳ��ʱ��
        [arr_able_charge] = GetProbableChargePeriod(ev_is_driving);
        
		v_able_charge(i, :) = arr_able_charge;
    end
end


%===========================================
%% ��������
function [arr_able_charge] = GetProbableChargePeriod(ev_is_driving)
    global battery_features
    global mc_params
    
    % ͳ���������ֵ ��ʼλ�� �� ����
    k = find( [true diff(ev_is_driving)~=0 true] );
    r = k(1:end-1);
    q = diff(k);

    % �������ֵ����/ֹλ��
    r_start = r;
    r_end = [ r_start(2:end) - 1, size(ev_is_driving, 2) ];

    % ��������ʱ�Σ����ڼ�ʻ״̬ �� ʱ���� >= fcharge_periods
    index_not_drive = find( ev_is_driving(r_start) == 0 );
    index_fcharge = index_not_drive( ...
            find( q(index_not_drive) >= battery_features.fcharge_periods ) );

    r_start_fcharge = r_start( index_fcharge );
    r_end_fcharge = r_end( index_fcharge );

    % ����ɳ��ʱ�� �� ����ɳ��ʱ��
    %charge_earlist_pi = r_start_fcharge;
    %charge_latest_pi = r_end_fcharge - battery_features.fcharge_periods + 1;
	
	% �ɳ����ʱ��
	charge_index = [];
	for i=1:length(r_start_fcharge)
		charge_period = r_start_fcharge(i) : r_end_fcharge(i);
		charge_index = [charge_index, charge_period];
	end
	
	arr_able_charge = false(1, mc_params.total_periods);
	arr_able_charge(charge_index) = 1;
end

