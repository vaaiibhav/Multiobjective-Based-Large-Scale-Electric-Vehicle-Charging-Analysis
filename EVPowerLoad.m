function [all_indices, mday_indices] = EVPowerLoad(varargin)
    global solutions
    global mc_params
    
    %% ��ʼ������
    [nTerms, nEVs] = Initial(varargin);

    %% ģ�� n�� m���綯����
    if ~mc_params.only_show_results
        for t=1:nTerms
%         	for ev_id=1:total_EV
                all_indices = Simulate(t);
%             end
        end
    end
    
    %% ���ͳ��: ��Ȳ������Ӱ����ʣ����۸񣬼����������е�
    result = TempResult('load');
    [grid, ev_behaviour, mday_indices] = StatisticPowerLoad(result);
end


%% initial parameters
function [nTerms, nEVs] = Initial(params)
    
    %% ���峣��
    global mc_params            % MC ����
    global battery_features     % �������
    global pile_power           % ��׮����
    global solutions            % ����
    global behaviours           % һ���û���Ϊ��EVs X Day_Periods��
	%global all_behaviours		% ����ͳ��ʱ����û���Ϊ��EVs X All_Periods��
    global t_periods            % ����ͳ��ʱ��
	global g2v_features			% �������
	global TOU_EPrice			% ��ʱ���
    global PDF_Travel           % ����һ�����ʷֲ��ĳ�����Ϊ
    
    %% ָ����������
    if size(params, 2) > 0
        nTerms = params{1};
        nDaysPT = params{2};
        nEVs = params{3};
        chargingStrategy = params{4};
        chargingWCoeff = params{5};
        chargingMinSOC = params{6};
        isOutput = params{7};
        % ���ڴ洢�м����������ñ�����ļ�
        saveResult = false;
        showResultOnly = false;
        
    else  % default values
        %     clear all
        clc
        close all
        
        % �Զ������ֵ
        nTerms = 4;
        nDaysPT = 25;
        nEVs = 240000;             %EV����: 2800 5000 62500 240000
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
    
    
    %% ��ʼ������
    mc_params.output = isOutput;                            %�Ƿ�������
    mc_params.cur_day = 1;                                 %��ǰ����
    %mc_params.cur_ev = 1;                                   %��ǰ����ID
    mc_params.periods_per_day = 96;                           %һ�컮��Ϊ����ʱ��
    mc_params.total_days = nDaysPT;                               %ÿ��ģ������
    mc_params.all_days = nTerms * mc_params.total_days;       %�ܹ�ģ������
    mc_params.mins_per_period = (24 * 60) / ...
                                mc_params.periods_per_day;	%ÿ��ʱ�ε�ʱ��
    mc_params.total_periods = mc_params.periods_per_day * ...
                                (mc_params.total_days + 1);       %ʱ������
    mc_params.total_EVs = nEVs;
    
    mc_params.cperiod_start_id = 0;
    mc_params.cperiod_end_id = 0;
    mc_params.cperiods = [];
    
    mc_params.eday_soc = ones(nEVs, 1, 'single');          %��ʼ����EV��SOCΪ1.0
    
    mc_params.save_result = saveResult;
    mc_params.memory_result = [];                           %���ڴ洢�м����������ñ�����ļ�
	mc_params.only_show_results = showResultOnly;           %ֻ���ͳ�ƽ��
    
    battery_features.capacity = 100;                        %�������
    battery_features.voltage = 230;                         %��ص�ѹ
    battery_features.power = battery_features.capacity * ...
                             battery_features.voltage;      %���������
    battery_features.efficiency = 0.3;                      %���Ч��
    battery_features.fcharge_duration = 5;                  %����ʱ��
    battery_features.full_soc = 0.9;                        %soc > ��״̬������Ϊ��س���
    battery_features.lowest_soc = chargingMinSOC;           %soc < ��״̬��������
    battery_features.power_consume_per_km = 0.125e3;        %����
	% ������������� �� ʱ����
    battery_features.fcharge_minutes = battery_features.fcharge_duration * 60;
    battery_features.fcharge_periods = ceil( battery_features.fcharge_minutes / mc_params.mins_per_period );
    
    pile_power = 15e3;                                      %��/�ŵ繦��
    solutions.start_charging = chargingStrategy;            %��ʼ�����ԣ�1.�����磻2.���������磻3.ͣ������磻4.��ϲ���
    solutions.w_coeff = chargingWCoeff;                     %���ֳ��Ӱ�����ص�Ȩ��
    solutions.enable_discharge = false;                     %����V2G�ķŵ�ģʽ
    
    
    % �綯��������
    %EV_type = {'bus', 'taxis', 'official_car', 'private_car'};
    
    
    % 1 X (ģ������ * ÿ��ʱ����)
    t_periods = CreatePeriods();
	
	% ����ÿʱ�ε����������� (Wh)
    g2v_features.grid_w_consumed = mc_params.mins_per_period / 60 * pile_power;
    % ����ÿʱ��EV�������� (Wh)
    g2v_features.ev_w_charged = g2v_features.grid_w_consumed * battery_features.efficiency;
	
	% ���ط�ʱ��۱�
	TOU_EPrice = CreateEPriceList();
    
    % ����������
    if ~mc_params.only_show_results
        ClearResults();
    end
    
    % ���ظ����ܶȺ���
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
	
    %fprintf('����������ģ��� %d �죭��������\n', mc_params.cur_day);
    
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
    
	% ������ʱ����
    result = TempResult('load');
    
    % �ϲ�ÿ��ĵ������ɼ�EV��Ϊ
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
                                (mc_params.total_days + 1);       %ʱ������
    
    mc_params.cperiod_start_id = 0;
    mc_params.cperiod_end_id = 0;
    mc_params.cperiods = [];
    
    % record soc for all EVs when one day is ending
    mc_params.eday_soc = behaviours.soc(:, end);
end


