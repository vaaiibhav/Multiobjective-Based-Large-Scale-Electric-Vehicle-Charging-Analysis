%===========================================
%% 一级函数
function [driving, v_is_driving] = MakeDrivingPlan(which_day)
    %global behaviours
    global mc_params
	
    % 出行概率分布
    driving = LoadDrivingPlan();
    
    % 根据出行时间，更新当天统计时段
    total_cperiods = UpdateCurrentPeriod(which_day, driving);
    
    % 计算出行状态，并格式化出行数据
    v_is_driving = false(mc_params.total_EVs, total_cperiods);
    for ev_id=1:mc_params.total_EVs
        % 根据出行行为，生成行驶状态向量 （total_EVs X total_periods）
        [arr_is_driving order_index] = CalDrivingStatus(ev_id, which_day, driving, total_cperiods);
        v_is_driving(ev_id, :) = arr_is_driving;
        
        % 为有效行驶行为排序
        driving = SortDrivingProperty(driving, ev_id, order_index);
    end
    
    % 得到行驶状态数据
	%behaviours.driving = driving;
    %behaviours.v_is_driving = v_is_driving;
    
	% 更新所有EV不同时段的出行状态
	%UpdateDriving();
end


%===========================================
%% 二级函数
function driving = LoadDrivingPlan()
    global mc_params
    global PDF_Travel

    %% test data
    %{
    % 行：(start + end)；列：driving_num
    driving.time = [ 480; ...
                     540 ];
    
    driving.km_per_min = [0.2];
	
	driving.num = 1;
    %}
    
    %% generate data from probability density function
    % 出行次数服从一定均值和方差下的概率分布
    fitness = PDF_Travel.freq_per_day.fitness;
    driving.num = int32( RandByPDF(fitness, mc_params.total_EVs, 1) );
    %random('norm', 3, 0.3, 1, 1);
    max_num = max(driving.num);
    
    % 出行时长服从一定均值和方差下的概率分布
    fitness = PDF_Travel.mins_per_trip.fitness;
    driving.minutes = int32( RandByPDF(fitness, mc_params.total_EVs, max_num) );
    
    % 出行里程服从一定均值和方差下的概率分布
    fitness = PDF_Travel.km_per_trip.fitness;
    driving.km_per_trv = RandByPDF(fitness, mc_params.total_EVs, max_num);
    
    driving.km_per_min = driving.km_per_trv ./ single(driving.minutes);
    
    % 出行时间满足所拟合的概率密度函数 (range: 0-24)
    %time_start = random(PDF_Travel.fit_driving_time, mc_params.total_EVs, max_num);
    fitness_am = PDF_Travel.departure_am.fitness;
    fitness_pm = PDF_Travel.departure_pm.fitness;
    departure_am = RandByPDF(fitness_am, mc_params.total_EVs, floor( single(max_num)/2 ));
    departure_pm = RandByPDF(fitness_pm, mc_params.total_EVs, ceil( single(max_num)/2 ));
    time_start = [departure_am departure_pm];
    driving.time_start = int32(time_start * 60);    % 转换成分钟
    driving.time_end = driving.time_start + driving.minutes;
end

function total_cperiods = UpdateCurrentPeriod(which_day, driving)
    global mc_params
    global t_periods
    
    latest_driving = max( max(driving.time_end) );
    
    end_mins = 24 * 60 * (which_day - 1) + latest_driving;
    arr_end_pid = Int32_Find(end_mins <= t_periods);
    if length(arr_end_pid) > 0
        end_pid = arr_end_pid(1);
    else
        error
    end
    
    % id: t_periods' index
    mc_params.cperiod_start_id = mc_params.cperiod_end_id + 1;
    mc_params.cperiod_end_id = end_pid;
    mc_params.cperiods = mc_params.cperiod_start_id : mc_params.cperiod_end_id;
    
    total_cperiods = mc_params.cperiod_end_id - ...
                                mc_params.cperiod_start_id + 1;
    
end

function [arr_is_driving, order_index] = CalDrivingStatus(ev_id, which_day, driving, total_cperiods)
    global mc_params
    global t_periods
    
    % 提取行驶时间段
    driving_freq = driving.num(ev_id);
    arr_dt_start = driving.time_start(ev_id, 1:driving_freq);
    arr_dt_end = driving.time_end(ev_id, 1:driving_freq);
    
    % 排列时间段
    [arr_dt_start, order_index] = sort(arr_dt_start);
    arr_dt_end = arr_dt_end(order_index);
    
    % 转换成当天的时间段
    start_mins = 24 * 60 * (which_day - 1) + arr_dt_start;
    end_mins = 24 * 60 * (which_day - 1) + arr_dt_end;
    
    v_start_mins = repmat( start_mins', 1, total_cperiods );
    v_end_mins = repmat( end_mins', 1, total_cperiods );
    
    this_periods = t_periods(mc_params.cperiods);
    v_tperiods = repmat( this_periods, driving_freq, 1 );
    
    % 判断是否处于行驶时段
    isDriving1 = (v_start_mins <= v_tperiods);
    isDriving2 = (v_tperiods <= v_end_mins);
    isDriving = logical(isDriving1 .* isDriving2);
    
    % 叠加多次出行状态
    arr_is_driving = logical( sum(isDriving, 1) );
%     index_one = Int32_Find(arr_is_driving ~= 0);
%     arr_is_driving(index_one) = arr_is_driving(index_one) ./ ...
%                                          arr_is_driving(index_one);
end

function driving = SortDrivingProperty(driving, ev_id, order_index)
    d_num = driving.num(ev_id);
    max_num = size(driving.minutes(ev_id, :), 2);
    
    % 行为排序
    if d_num > 0
        travel_index = 1 : d_num;
        driving.minutes(ev_id, travel_index) = driving.minutes(ev_id, order_index);
        driving.km_per_trv(ev_id, travel_index) = driving.km_per_trv(ev_id, order_index);
        driving.km_per_min(ev_id, travel_index) = driving.km_per_min(ev_id, order_index);
        driving.time_start(ev_id, travel_index) = driving.time_start(ev_id, order_index);
        driving.time_end(ev_id, travel_index) = driving.time_end(ev_id, order_index);
    end
    % 无效行驶清零
    if d_num < max_num
        invalid_index = (d_num + 1) : max_num;
        %fprintf('d_num = %d, max_num = %d\n', d_num, max_num);
        driving.minutes(ev_id, invalid_index) = 0;
        driving.km_per_trv(ev_id, invalid_index) = 0;
        driving.km_per_min(ev_id, invalid_index) = 0;
        driving.time_start(ev_id, invalid_index) = 0;
        driving.time_end(ev_id, invalid_index) = 0;
    end
end



