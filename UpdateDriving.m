function UpdateDriving(ev_id, start_index, end_index)
    global behaviours
    global mc_params
    
    periods = start_index:end_index;
    v_is_driving = behaviours.v_is_driving(ev_id, periods);
    
	% 计算行驶里程
    v_driving_km_pp = CalMileage(v_is_driving);
    % 计算行驶能耗
    v_driving_cost_power = CalPowerCost(v_driving_km_pp);
	
	behaviours.v_driving_km_pp(ev_id, periods) = v_driving_km_pp;
    behaviours.v_driving_cost_power(ev_id, periods) = v_driving_cost_power;
	
	% UpdatSOC(ev_id, pindex_start, pindex_end);
end


function [v_driving_km_pp] = CalMileage(v_is_driving)
    global mc_params
    global PDF_Travel
    
    r_num = size(v_is_driving, 1);
    c_num = size(v_is_driving, 2);
    
    % 过滤出行驶状态的时段
    arr_is_driving = single( reshape(v_is_driving', 1, r_num * c_num) );
    travel_index = Int32_Find(arr_is_driving ~= 0);
    
    % 出行时长和里程服从一定均值和方差下的概率分布
    %trv_minutes = round( random(PDF_Travel.fit_driving_mins, 1, length(travel_index)) );
    %trv_km = random(PDF_Travel.fit_driving_km, 1, length(travel_index));
    
    fitness = PDF_Travel.mins_per_trip.fitness;
    trv_minutes = int32( RandByPDF(fitness, 1, length(travel_index)) );
    
    fitness = PDF_Travel.km_per_trip.fitness;
    trv_km = RandByPDF(fitness, 1, length(travel_index));
    
    
    trv_km_per_min = trv_km ./ single(trv_minutes);
    trv_km_per_period = mc_params.mins_per_period * trv_km_per_min;
    
    if length(travel_index) ~= 0
        arr_is_driving(travel_index) = arr_is_driving(travel_index) .* trv_km_per_period;
    elseif mc_params.output == true
        fprintf('－－－－－arr_is_driving len=%d－－－－－\n', length(arr_is_driving(travel_index)));
    end
    
    % 转为每一行驶时段的里程值: km/period
    v_driving_km_pp = reshape(arr_is_driving, c_num, r_num)';
end


function [v_cost_power] = CalPowerCost(v_driving_km_pp)
    global battery_features
    
    % total_EVs X total_periods (values: Wh)
    v_cost_power = v_driving_km_pp * battery_features.power_consume_per_km;
end

