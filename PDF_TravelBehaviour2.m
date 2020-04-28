function PDF_TravelBehaviour2()
    clc
    close all
    clear
    
    %% load travel statistics
    figure;
    
    % BirnbaumSaunders,Gamma,GeneralizedExtremeValue,Loglogistic,Lognormal
    subplot(2,2,1);
    freq = Fitness_Travel('Daily travel frequency', 'Gamma');
    DrawFitness(freq, 'Daily travel frequency', 'Distribution percentage', '(a)', ...
        8, 1);
    
    % BirnbaumSaunders,Exponential,Gamma,GeneralizedExtremeValue,GeneralizedPareto,Weibull
    subplot(2,2,2);
    mileage = Fitness_Travel('Driving mileage per trip', 'BirnbaumSaunders');
    DrawFitness(mileage, 'Driving mileage per trip (km)', 'Distribution percentage', '(b)', ...
        80, 3);
    
    % Exponential,Gamma,GeneralizedPareto,Loglogistic,Nakagami,NegativeBinomial,Weibull
    subplot(2,2,3);
    duration = Fitness_Travel('Travel duration per trip', 'Gamma');
    DrawFitness(duration, 'Travel duration per trip (min)', 'Distribution percentage', '(c)', ...
        140, 10);
    
    % Logistic,Loglogistic,Normal,Poisson,Rician,tLocationScale,Weibull
    subplot(2,2,4);
    t_start_am = Fitness_Travel('Trip starting time(AM)', 'tLocationScale');
    t_start_pm = Fitness_Travel('Trip starting time(PM)', 'Normal');
    t_start = CombineStartTime(t_start_am, t_start_pm);
    DrawFitness(t_start, 'The departure time', 'Distribution percentage', '(d)', ...
        24, 1);
    
    %% save fitness
    pdf_travel.freq_per_day = freq;
    pdf_travel.km_per_trip = mileage;
    pdf_travel.mins_per_trip = duration;
    pdf_travel.departure_am = t_start_am;
    pdf_travel.departure_pm = t_start_pm;
    save('fitness_travel.mat', 'pdf_travel');
end


function freq = Fitness_Travel(sheet, fit_method)
    % load data
    [num_freq,~,~] = xlsread('../../data/travel_behaviour.xls', sheet);
    
    % 实际数值曲线
    statistics.x = num_freq(:, 1);
    statistics.y = num_freq(:, 2) / sum(num_freq(:, 2));    % normalize
    
    % 拟合 -- http://cn.mathworks.com/help/stats/fitdist.html?refresh=true
    bins = statistics.x;
    obsCounts = round(statistics.y * 1000);
    [expCounts, pd] = FitDistribution(fit_method, bins, obsCounts);

    fitness.pdf = pd;
    fitness.x = statistics.x;
    fitness.y = expCounts / sum(expCounts);    % normalize
    
    % 检验
    nTsObs = statistics.y * sum(obsCounts);
    nTsExp = fitness.y * sum(obsCounts);
    Rtest = MultiTest(bins, nTsObs, nTsExp);
    
    % 概率 或 数量
    %statistics.y = nTsObs;
    %fitness.y = nTsExp;
    
    % 返回结果
    freq.statistics = statistics;
    freq.fitness = fitness;
    freq.Rtest = Rtest;
end


function DrawFitness(data, label_x, label_y, str_title, max_x, interval_x)
    % 统计分布曲线
    plot(data.statistics.x, data.statistics.y, '--b*', 'LineWidth', 1.5);
    hold on
    grid on
    
    %max_x = max(data.statistics.x);
    max_y = 0.5;%(max(data.statistics.y) + 0.1);
    %interval_x = max_x / 10;
    
    axis( [0 max_x 0 max_y] );
    set(gca,'xtick',0:interval_x:max_x);
    set(gca,'ytick',0:0.1:0.5);
    
    xlabel(label_x, 'FontSize', 14);
    ylabel(label_y, 'FontSize', 14);
    
    % 拟合分布曲线
    plot(data.fitness.x, data.fitness.y, '-.ro', 'LineWidth', 1.5);

    legend('Statistics', 'Fitness');
    title(str_title, 'FontSize', 16, 'FontWeight', 'bold');
end


function [expCounts, pd] = FitDistribution(method, bins, obsCounts)
	n = sum(obsCounts);
	pd = fitdist(bins,method,'Frequency',obsCounts);
	expCounts = n * pdf(pd,bins);
    
    m_pd = mean(pd);
    std_pd = std(pd);
end


function Rtest = MultiTest(bins, obsCounts, expCounts)
    [test_chi2.h,test_chi2.p,test_chi2.st] = Test('chi2', bins, obsCounts, expCounts);
	[test_ks.h,test_ks.p] = Test('ks', bins, obsCounts, expCounts);
	[test_F.h,test_F.p,test_F.st] = Test('F', bins, obsCounts, expCounts);
	[test_T.h,test_T.p] = Test('T', bins, obsCounts, expCounts);
    
    Rtest.chi2 = test_chi2;
    Rtest.ks = test_ks;
    Rtest.F = test_F;
    Rtest.T = test_T;
end

function [h,p,st] = Test(method, bins, obsCounts, expCounts)
    if strcmp(method, 'chi2') == 1
        % 卡方检验
        [h,p,st] = chi2gof(bins,'Ctrs',bins,...
                            'Frequency',obsCounts, ...
                            'Expected',expCounts,...
                            'NParams',1,...
                            'Alpha', 0.05);
    elseif strcmp(method, 'ks') == 1
        % ks检验
        [h,p] = kstest2(obsCounts,expCounts,'Alpha',0.05);
    elseif strcmp(method, 'fisher') == 1
        x = int64([obsCounts; expCounts]);
        [h,p,st] = fishertest(x,'Tail','right','Alpha',0.05);
    elseif strcmp(method, 'F') == 1
        [h,p,ci,st] = vartest2(obsCounts, expCounts);
    elseif strcmp(method, 'T') == 1
        [h,p] = ttest(obsCounts, expCounts,'Alpha',0.01);
    end
end


function t_start = CombineStartTime(t_start_am, t_start_pm)
    statistics.x = [t_start_am.statistics.x; t_start_pm.statistics.x];
    statistics.y = [t_start_am.statistics.y; t_start_pm.statistics.y];
    
    fitness.x = [t_start_am.fitness.x; t_start_pm.fitness.x];
    fitness.y = [t_start_am.fitness.y; t_start_pm.fitness.y];
    
    t_start.statistics = statistics;
    t_start.fitness = fitness;
end
