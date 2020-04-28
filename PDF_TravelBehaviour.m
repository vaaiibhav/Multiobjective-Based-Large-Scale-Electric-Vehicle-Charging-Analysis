function PDF_TravelBehaviour()
    clc
    close all
    clear
    
    %% which travel behaviour for fitness
    %choose from 'time' / 'frequency' / 'mileage' / 'duration'
    
    % for passenger car in workdays
    
    subplot(2,2,1);
    pdf_travel.fit_driving_time = TravelDistribution('time', 24, 0.18, 'Daily starting time of trip', 1, 0.02);
    
    subplot(2,2,2);
    pdf_travel.fit_driving_freq = TravelDistribution('frequency', 6, NaN, 'Daily travel frequncy', 1, 0.1);
    
    subplot(2,2,3);
    pdf_travel.fit_driving_km = TravelDistribution('mileage', 35, 0.12, 'Driving mileage per trip (km)', 5, 0.01);
    
    subplot(2,2,4);
    pdf_travel.fit_driving_mins = TravelDistribution('duration', 80, 0.08, 'Driving duration per trip (minutes)', 5, 0.01);
    
    %% save fitness
    save('fitness_travel.mat', 'pdf_travel');
end


function fit_driving_time = TravelDistribution(travel_behaviour, max_x, max_y, ...
                                            label_x, interval_x, interval_y)
    %% Generate some data
    % for reproducibility
    rng default
    if strcmp(travel_behaviour, 'time')
        % 早高峰出行时段为7:00 to 8:00
        X1 = 7.5 + 0.1 * randn(5000, 1);
        % 晚高峰出行时段为17:00 to 18:00
        %X2 = 17.5 + 0.8 * randn(1000, 1);
        X2 = poissrnd(2, 5000, 1) + 15.5;

        X = [X1; X2];
        
        % Fit a distribution using a kernel smoother
        fit_driving_time = fitdist(X, 'Kernel', 'Kernel', 'normal', 'Width', 1.2);
    elseif strcmp(travel_behaviour, 'frequency')
        %X = 2.29 + 0.5 * randn(5000, 1);
        %X = poissrnd(0.2, 5000, 1) + 2.09;
        %fit_driving_time = fitdist(X, 'Kernel', 'Kernel', 'normal');
        
        m = 2.29;
        v = 0.9;
        mu = log((m^2)/sqrt(v+m^2));
        sigma = sqrt(log(v/(m^2)+1));
        %[M,V]= lognstat(mu,sigma);
        X = lognrnd(mu,sigma,1e6, 1);
        
        fit_driving_time = fitdist( X ,'Lognormal');
        
    elseif strcmp(travel_behaviour, 'mileage')
        %X = 13.7 + 2 * randn(5000, 1);
        
        %a = 12;  b = 13.7 / a;
        %X = gamrnd(a, b, 5000, 1);
        %[M,V] = gamstat(a, b);
        
        m = 13.7;
        v = 15.6;
        mu = log((m^2)/sqrt(v+m^2));
        sigma = sqrt(log(v/(m^2)+1));
        %[M,V]= lognstat(mu,sigma);
        X = lognrnd(mu,sigma,1e6, 1);
        
        fit_driving_time = fitdist( X ,'Lognormal');
        
        %fit_driving_time = fitdist(X, 'Kernel', 'Kernel', 'normal');
    elseif strcmp(travel_behaviour, 'duration')
        X = 0.6*60 + 6 * randn(5000, 1);
        
        fit_driving_time = fitdist(X, 'Kernel', 'Kernel', 'normal');
    end

    %% Visualize the resulting fit
    [x_index, y_pdf] = DrawPDF(fit_driving_time, max_x, max_y, label_x, interval_x, interval_y);
    
    if strcmp(travel_behaviour, 'time')
        half_len = length(x_index) / 2;
        DrawPatch(x_index(1:half_len), y_pdf(1:half_len), 0.9);
        DrawPatch(x_index(half_len:end), y_pdf(half_len:end), 0.9);
    else
        DrawPatch(x_index, y_pdf, 0.9);
        grid on
    end
    

    %% Generate a set of random numbers drawn from the distribution
    %hold on
    %TestDistribution(fit_driving_time);
    
    %% set title
    %legend('拟合概率分布', '随机生成数据');
    %title(pdf_title);
end


function [x_index, y_pdf] = DrawPDF(fit_driving_time, max_x, max_y, label_x, interval_x, interval_y)
    x_index = linspace(0, max_x, 1000);
    y_pdf = pdf(fit_driving_time, x_index);
    plot(x_index, y_pdf, 'LineWidth', 1.5);
    
    if isnan(max_y)
    	max_y = max(y_pdf) + 0.1;
    end
    axis([0 max_x 0 max_y]);
    set(gca,'xtick',0:interval_x:max_x);
    set(gca,'ytick',0:interval_y:max_y);
    
    xlabel(label_x, 'FontSize', 12);
    ylabel('Probability Distribution', 'FontSize', 12);
end


function DrawPeakLines(x_index, y_pdf, cutoff1, cutoff2)
    xlo = [cutoff1 x_index(cutoff2>=x_index & x_index>=cutoff1) cutoff2];
    ylo = [0 y_pdf(cutoff2>=x_index & x_index>=cutoff1) 0];

    peak_period = patch(xlo, ylo, 'b', 'linestyle', '-.');
    alpha(peak_period, 0.0);
end


function [expCounts, pd] = Fitness(method, bins, obsCounts)
    %{
    st_arv = tabulate( round(X) );
    bins = st_arv(:, 1)';
    obsCounts = st_arv(:, 2)';
    [expCounts, fit_driving_time] = Fitness('Poisson', bins, obsCounts);
    %}

	n = sum(obsCounts);
	pd = fitdist(bins',method,'Frequency',obsCounts');
	expCounts = n * pdf(pd,bins);
end


function TestDistribution(fit_driving_time)
    numbers = random(fit_driving_time, 1, 1000);
    
    st_arv = tabulate( round(numbers) );
    arrival.x_arv_num = st_arv(:, 1)';
    arrival.y_arv_perc = st_arv(:, 3)' / 100;
    
    plot(arrival.x_arv_num, arrival.y_arv_perc, '-.r*', 'LineWidth',1.2);
    %axis([0 max(arrival.x_arv_num) 0 0.5]);
    %set(gca,'xtick',0:1:max(arrival.x_arv_num));
    %set(gca,'ytick',0:0.1:1);
end