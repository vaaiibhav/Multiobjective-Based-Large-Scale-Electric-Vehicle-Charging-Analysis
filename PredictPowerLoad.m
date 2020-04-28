function PredictPowerLoad()
    clc
    close all
    clear all
    
    
    arr_w_load = [];
    arr_w_v2g = [];
    
    arr_days = 100;          %50:10:100;
    arr_EVs = 100:100:1000;
    
    for total_days = arr_days
        for total_EVs = arr_EVs
            [grid, ev_behaviour] = EVPowerLoad(total_days, total_EVs);
            
            m_w_load = mean(grid.power_load, 1);
            m_w_v2g = mean(grid.power_V2G, 1);
            
            max_w_load = max(m_w_load);
            max_w_v2g = max(m_w_v2g);
            
            sum_w_load = sum(m_w_load);
            sum_w_v2g = sum(m_w_v2g);
            
            arr_w_load = [arr_w_load sum_w_load];
            arr_w_v2g = [arr_w_v2g sum_w_v2g];
        end
    end
    
    %save('fitness_days.mat', 'arr_days', 'arr_w_load', 'arr_w_v2g');
    save('fitness_EVs_sum.mat', 'arr_EVs', 'arr_w_load', 'arr_w_v2g');
    
    
    % test the fitness of days
    %load('fitness_days.mat');
    %FitnessDays(arr_days, arr_w_load, arr_w_v2g);
    
    % test the fitness of Evs
    load('fitness_EVs_sum.mat');
    %FitnessEVs(arr_EVs, arr_w_load, arr_w_v2g);
    total_EVs = 240000;     %62500;
    prd_w_load = linear_regress(arr_EVs, arr_w_load, total_EVs);
    prd_w_v2g = linear_regress(arr_EVs, arr_w_v2g, total_EVs);
end


function FitnessDays(arr_days, arr_w_load, arr_w_v2g)
    figure;
    plot(arr_days, arr_w_load, 'linewidth', 2, 'markersize', 16);
    figure;
    plot(arr_days, arr_w_v2g, 'linewidth', 2, 'markersize', 16);
end


function FitnessEVs(arr_EVs, arr_w_load, arr_w_v2g)
    figure;
    plot(arr_EVs, arr_w_load, 'linewidth', 2, 'markersize', 16);
    figure;
    plot(arr_EVs, arr_w_v2g, 'linewidth', 2, 'markersize', 16);
end


function prd_y = linear_regress(x, y, prd_x)
    %figure;
    %plot(x,y,'ro');
    
	[P,S]=polyfit(x,y,1);
    %P为拟合回归系数即y=P(1)*x+p(2)
    fprintf('一元线性回归方程：Y = %0.2f * x + %0.2f \n',P(1),P(2));

    X = prd_x;
	[Y,delta]=polyconf(P, X, S, 0.05);
    %给出回归Y的95%的置信区间为[Y-delta，Y+delta]
    fprintf('预测值为：%0.2f，区间估计为[%0.2f, %0.2f] \n',Y, Y-delta, Y+delta);
    prd_y = Y;
    
	x1=x;
	f=polyval(P,x1);
    figure;
	plot(x,y,'ro',x1,f,'-')%绘图查看拟合效果
    %{
	hold on
	plot(X,Y+delta,'*g')
	plot(X,Y-delta,'*g')%给出拟合的置信区间
    %}
end

