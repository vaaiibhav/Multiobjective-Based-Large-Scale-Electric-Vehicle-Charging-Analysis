%===========================================
%% 一级函数
function MakeChargingPlan()
    global behaviours
	global mc_params
    
    v_is_driving = behaviours.v_is_driving;
    
    % 充电计划 依赖于 出行计划
    [v_able_charge] = ChargingPlan(v_is_driving);
	v_is_charging = false(mc_params.total_EVs, mc_params.total_periods);
	
	% 所有可能的充电时段
	%behaviours.v_charge_earlist_pi = v_charge_earlist_pi;
	%behaviours.v_charge_latest_pi = v_charge_latest_pi;
	
	behaviours.v_able_charge = v_able_charge;
	behaviours.v_is_charging = v_is_charging;
end


%===========================================
%% 二级函数
function [v_able_charge] = ChargingPlan(v_is_driving)
    global mc_params
    
    % test data
    %v_is_driving = [0 0 1 1 1 0 0 0 0 0 1 0 1 1 0 0 0 0 0 0;
    %                1 1 1 0 0 0 0 0 0 0 1 1 1 1 1 1 1 1 1 1;
    %                0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1 0 1];
    
	v_able_charge = false(mc_params.total_EVs, mc_params.total_periods);
    
    for i=1:mc_params.total_EVs
        ev_is_driving = v_is_driving(i, :);
        
        % 求算 可充电时段
        [arr_able_charge] = GetProbableChargePeriod(ev_is_driving);
        
		v_able_charge(i, :) = arr_able_charge;
    end
end


%===========================================
%% 三级函数
function [arr_able_charge] = GetProbableChargePeriod(ev_is_driving)
    global battery_features
    global mc_params
    
    % 统计连续相等值 起始位置 及 个数
    k = find( [true diff(ev_is_driving)~=0 true] );
    r = k(1:end-1);
    q = diff(k);

    % 求出连续值的起/止位置
    r_start = r;
    r_end = [ r_start(2:end) - 1, size(ev_is_driving, 2) ];

    % 求算满充时段：不在驾驶状态 且 时段数 >= fcharge_periods
    index_not_drive = find( ev_is_driving(r_start) == 0 );
    index_fcharge = index_not_drive( ...
            find( q(index_not_drive) >= battery_features.fcharge_periods ) );

    r_start_fcharge = r_start( index_fcharge );
    r_end_fcharge = r_end( index_fcharge );

    % 最早可充电时段 及 最晚可充电时段
    %charge_earlist_pi = r_start_fcharge;
    %charge_latest_pi = r_end_fcharge - battery_features.fcharge_periods + 1;
	
	% 可充电标记时段
	charge_index = [];
	for i=1:length(r_start_fcharge)
		charge_period = r_start_fcharge(i) : r_end_fcharge(i);
		charge_index = [charge_index, charge_period];
	end
	
	arr_able_charge = false(1, mc_params.total_periods);
	arr_able_charge(charge_index) = 1;
end

