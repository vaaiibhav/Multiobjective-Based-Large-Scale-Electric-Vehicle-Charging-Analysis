function [all_indices, mday_indices] = EVPowerLoad(varargin)
    global solutions
    global mc_params
    
    %% 初始化变量
    [nTerms, nEVs] = Initial(varargin);

    %% 模拟 n天 m辆电动汽车
    if ~mc_params.only_show_results
        for t=1:nTerms
%         	for ev_id=1:total_EV
                all_indices = Simulate(t);
%             end
        end
    end
    
    %% 结果统计: 峰谷差，出行受影响概率，充电价格，加入噪声出行等
    result = TempResult('load');
    [grid, ev_behaviour, mday_indices] = StatisticPowerLoad(result);
end


%% initial parameters
function [nTerms, nEVs] = Initial(params)
    
    %% 定义常量
    global mc_params            % MC 参数
    global battery_features     % 电池特性
    global pile_power           % 电桩特性
    global solutions            % 策略
    global behaviours           % 一天用户行为（EVs X Day_Periods）
	%global all_behaviours		% 所有统计时间的用户行为（EVs X All_Periods）
    global t_periods            % 所有统计时段
	global g2v_features			% 充电特性
	global TOU_EPrice			% 分时电价
    global PDF_Travel           % 服从一定概率分布的出行行为
    
    %% 指定参数运行
    if size(params, 2) > 0
        nTerms = params{1};
        nDaysPT = params{2};
        nEVs = params{3};
        chargingStrategy = params{4};
        chargingWCoeff = params{5};
        chargingMinSOC = params{6};
        isOutput = params{7};
        % 用于存储中间结果，而不用保存成文件
        saveResult = false;
        showResultOnly = false;
        
    else  % default values
        %     clear all
        clc
        close all
        
        % 自定义参数值
        nTerms = 4;
        nDaysPT = 25;
        nEVs = 240000;             %EV数量: 2800 5000 62500 240000
        chargingStrategy = 4;
        chargingWCoeff = [0.1512,0.7384,0.1105,0.0196];%ones(1, 4) * 0.25;
        chargingMinSOC = 0.5686;%0.2;
        isOutput = true;
        saveResult = true;         %default:true;
        showResultOnly = true;      %default:false;
        
        seed=15;
        randn('state',seed);
        rand('state',seed);
    end
    
    
    %% 初始化常量
    mc_params.output = isOutput;                            %是否输出结果
    mc_params.cur_day = 1;                                 %当前天数
    %mc_params.cur_ev = 1;                                   %当前汽车ID
    mc_params.periods_per_day = 96;                           %一天划分为若干时段
    mc_params.total_days = nDaysPT;                               %每期模拟天数
    mc_params.all_days = nTerms * mc_params.total_days;       %总共模拟天数
    mc_params.mins_per_period = (24 * 60) / ...
                                mc_params.periods_per_day;	%每个时段的时长
    mc_params.total_periods = mc_params.periods_per_day * ...
                                (mc_params.total_days + 1);       %时段总数
    mc_params.total_EVs = nEVs;
    
    mc_params.cperiod_start_id = 0;
    mc_params.cperiod_end_id = 0;
    mc_params.cperiods = [];
    
    mc_params.eday_soc = ones(nEVs, 1, 'single');          %初始所有EV的SOC为1.0
    
    mc_params.save_result = saveResult;
    mc_params.memory_result = [];                           %用于存储中间结果，而不用保存成文件
	mc_params.only_show_results = showResultOnly;           %只输出统计结果
    
    battery_features.capacity = 100;                        %电池容量
    battery_features.voltage = 230;                         %电池电压
    battery_features.power = battery_features.capacity * ...
                             battery_features.voltage;      %电池总能量
    battery_features.efficiency = 0.3;                      %充电效率
    battery_features.fcharge_duration = 5;                  %充满时间
    battery_features.full_soc = 0.9;                        %soc > 此状态，即认为电池充满
    battery_features.lowest_soc = chargingMinSOC;           %soc < 此状态，必须充电
    battery_features.power_consume_per_km = 0.125e3;        %耗能
	% 满充所需分钟数 及 时段数
    battery_features.fcharge_minutes = battery_features.fcharge_duration * 60;
    battery_features.fcharge_periods = ceil( battery_features.fcharge_minutes / mc_params.mins_per_period );
    
    pile_power = 15e3;                                      %充/放电功率
    solutions.start_charging = chargingStrategy;            %起始充电策略：1.随机充电；2.电价引导充电；3.停车即充电；4.组合策略
    solutions.w_coeff = chargingWCoeff;                     %各种充电影响因素的权重
    solutions.enable_discharge = false;                     %允许V2G的放电模式
    
    
    % 电动汽车类型
    %EV_type = {'bus', 'taxis', 'official_car', 'private_car'};
    
    
    % 1 X (模拟天数 * 每天时段数)
    t_periods = CreatePeriods();
	
	% 计算每时段电网耗用能量 (Wh)
    g2v_features.grid_w_consumed = mc_params.mins_per_period / 60 * pile_power;
    % 计算每时段EV所充能量 (Wh)
    g2v_features.ev_w_charged = g2v_features.grid_w_consumed * battery_features.efficiency;
	
	% 加载分时电价表
	TOU_EPrice = CreateEPriceList();
    
    % 清除结果数据
    if ~mc_params.only_show_results
        ClearResults();
    end
    
    % 加载概率密度函数
    load './data/fitness_travel.mat';
    PDF_Travel = pdf_travel;
end


%% simulate one day
function all_indices = Simulate(t)
    global mc_params
	global behaviours
    %global t_periods
    
    mc_params.cur_day = t;
    %mc_params.cur_ev = ev_id;
    %w_day = mod( (d-1), 7 );
    
	%% clear all behaviours
    ClearAllBehaviours();
	
    %fprintf('－－－－－模拟第 %d 天－－－－－\n', mc_params.cur_day);
    
    %% make the driving & charging plan for all days
    MakeDaysPlan();
    
    %% update all EVs
    UpdateEVs();
    
    %% formating data
    [grid, ev_behaviour, y_indices] = StatDataFormat();
    
	%% combine data of everyday
    all_indices = CombineData(grid, ev_behaviour, y_indices);
    
    %% update params
    UpdateMCParams();
end

function all_periods = CreatePeriods()
    global mc_params
    
    % construct the period array
    all_periods = int32( 0 : (mc_params.total_periods - 1) ) * ...
                    mc_params.mins_per_period;
end


function ClearAllBehaviours()
    global behaviours
    
    % init array for EV behaviours
    behaviours = [];
    behaviours.v_is_driving = logical([]);
    behaviours.v_plan_driving = logical([]);
    behaviours.v_driving_km_pp = single([]);
    behaviours.v_driving_cost_power = single([]);
    behaviours.v_able_charge = logical([]);
    behaviours.v_is_charging = logical([]);
	behaviours.v_ev_w_charged = single([]);
    behaviours.v_ev_w_discharged = single([]);
    behaviours.grid_power_load = single([]);
    behaviours.soc = single([]);
end

function ClearResults()
    global mc_params
    global solutions
    
    ndays = mc_params.all_days;
    
    % init & save temporary data
    result.grid.power_load = zeros(ndays, mc_params.periods_per_day, 'single');
    result.grid.power_charged = zeros(ndays, mc_params.periods_per_day, 'single');
    result.grid.power_V2G = zeros(ndays, mc_params.periods_per_day, 'single');
    
    result.ev_behaviour.trv_num_per_period = zeros(ndays, mc_params.periods_per_day, 'int32');
    result.ev_behaviour.plan_trv_num_per_period = zeros(ndays, mc_params.periods_per_day, 'int32');
    result.ev_behaviour.cha_num_per_period = zeros(ndays, mc_params.periods_per_day, 'int32');
    result.ev_behaviour.dischar_num_per_period = zeros(ndays, mc_params.periods_per_day, 'int32');
    
    result.y_indices = zeros(ndays, 1, 'single');
    
    TempResult('save', result);
    
    clear 'result';
end


function all_indices = CombineData(grid, ev_behaviour, y_indices)
	global behaviours
    %global all_behaviours
    global solutions
    global mc_params
	
    ndays = mc_params.all_days;
    cur_day = ((mc_params.cur_day - 1) * mc_params.total_days + 1) : ...
        mc_params.cur_day * mc_params.total_days;
    
	% 加载临时数据
    result = TempResult('load');
    
    % 合并每天的电网负荷及EV行为
    result.grid.power_load(cur_day, :) = grid.power_load;
    result.grid.power_charged(cur_day, :) = grid.power_charged;
    result.grid.power_V2G(cur_day, :) = grid.power_V2G;
    
    result.ev_behaviour.trv_num_per_period(cur_day, :) = ev_behaviour.trv_num_per_period;
    result.ev_behaviour.plan_trv_num_per_period(cur_day, :) = ev_behaviour.plan_trv_num_per_period;
    result.ev_behaviour.cha_num_per_period(cur_day, :) = ev_behaviour.cha_num_per_period;
    result.ev_behaviour.dischar_num_per_period(cur_day, :) = ev_behaviour.dischar_num_per_period;
    
    result.y_indices(cur_day, :) = y_indices;
    
    % save temporary data
    TempResult('save', result);
    
    % clear data from memory
    all_indices = result.y_indices;
    clear 'result';
end


function UpdateMCParams()
    global mc_params
    global behaviours
    
    % clear mc prams
    mc_params.total_periods = mc_params.periods_per_day * ...
                                (mc_params.total_days + 1);       %时段总数
    
    mc_params.cperiod_start_id = 0;
    mc_params.cperiod_end_id = 0;
    mc_params.cperiods = [];
    
    % record soc for all EVs when one day is ending
    mc_params.eday_soc = behaviours.soc(:, end);
end


