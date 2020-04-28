%===========================================
%% 一级函数
function MakeDaysPlan()
    global mc_params
    global behaviours
    global all_behaviours
    
    %% 每天的出行计划
    behaviours.v_is_driving = false(mc_params.total_EVs, mc_params.total_periods);
    nPeriods = int32(0);
    for d=1:mc_params.total_days
        [driving, v_is_driving] = MakeDrivingPlan(d);
        
        start_idx = nPeriods + 1;
        end_idx = nPeriods + size(v_is_driving, 2);
        
        behaviours.v_is_driving(:, start_idx:end_idx) = v_is_driving;
        behaviours.driving{d} = driving;
        
        nPeriods = end_idx;
        %abs_day = (mc_params.cur_day - 1) * mc_params.total_days + d;
        if mc_params.output
            fprintf('－－－第 %d-%d 天出行计划，共出行 %d 趟－－－\n', ...
                        mc_params.cur_day, d, sum(driving.num));
        end
    end
    
    % 截断
    mc_params.total_periods = nPeriods;
    behaviours.v_is_driving = behaviours.v_is_driving(:, 1:nPeriods);
    behaviours.v_plan_driving = behaviours.v_is_driving;
    
    % 根据出行时段，初始行驶状态
    UpdateDriving(1:mc_params.total_EVs, 1, mc_params.total_periods);
    
    
    %% 充电计划 依赖于 出行计划
    MakeChargingPlan();
    
    % 根据充电时段，初始能耗状态
    UpdateCharging(1:mc_params.total_EVs, 1, mc_params.total_periods);
    UpdateDischarge(1:mc_params.total_EVs, 1, mc_params.total_periods);
    
    
    %% 初始EV状态
    pre_soc = GetPreviousSOC(1:mc_params.total_EVs, 1);
    behaviours.soc = repmat(pre_soc, 1, mc_params.total_periods);
end



