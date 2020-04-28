%===========================================
%% һ������
function MakeDaysPlan()
    global mc_params
    global behaviours
    global all_behaviours
    
    %% ÿ��ĳ��мƻ�
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
            fprintf('�������� %d-%d ����мƻ��������� %d �ˣ�����\n', ...
                        mc_params.cur_day, d, sum(driving.num));
        end
    end
    
    % �ض�
    mc_params.total_periods = nPeriods;
    behaviours.v_is_driving = behaviours.v_is_driving(:, 1:nPeriods);
    behaviours.v_plan_driving = behaviours.v_is_driving;
    
    % ���ݳ���ʱ�Σ���ʼ��ʻ״̬
    UpdateDriving(1:mc_params.total_EVs, 1, mc_params.total_periods);
    
    
    %% ���ƻ� ������ ���мƻ�
    MakeChargingPlan();
    
    % ���ݳ��ʱ�Σ���ʼ�ܺ�״̬
    UpdateCharging(1:mc_params.total_EVs, 1, mc_params.total_periods);
    UpdateDischarge(1:mc_params.total_EVs, 1, mc_params.total_periods);
    
    
    %% ��ʼEV״̬
    pre_soc = GetPreviousSOC(1:mc_params.total_EVs, 1);
    behaviours.soc = repmat(pre_soc, 1, mc_params.total_periods);
end



