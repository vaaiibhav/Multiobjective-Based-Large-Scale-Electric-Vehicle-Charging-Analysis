function [will_charge, best_prior, best_idx] = ...
        CalChargingPrior(is_necessary, cur_soc, arrMCost, ...
                        pindex_start, pindex_end)
    global TOU_EPrice
    global solutions
    global battery_features
    
    % debug by fei
    if (pindex_end - pindex_start + 1) < battery_features.fcharge_periods
        error
    end
    
    % 优先权重系数
    if solutions.start_charging == 4    %如果是组合策略，用上所有系数
        W = solutions.w_coeff;
        % 剩余SOC/最低SOC
        u_s = 1.5 - cur_soc / battery_features.lowest_soc;
    else
        W = zeros(1, 4);
        W(solutions.start_charging) = 1;
        W(4) = 1;
        
    end
    
    % 是否必须充电
        if is_necessary
            u_s = 10000;    %inf
        else
            u_s = 0;
        end
    
    
    nPrior = length(arrMCost);
    % 从某个时刻开始充电的平均电价：元/（瓦＊时段）
    %arrMCost = [];
    % TOC平均电价：元/（瓦＊时段）
    nMTOC = TOU_EPrice.mprice;
    % 充电需用时段
    nTch = single( battery_features.fcharge_periods );
    % 剩余空闲时段
    nTidle = pindex_end - pindex_start + 1;
    arrTidle = single(nTidle) : -1 : nTch;
    % 随机优先 [0 1]
    nRndPr = round(rand);
    arrRndPr = single( nRndPr * rand(1, nPrior) );
    
    % 计算不同时段的充电优先程度
    arrPrior = W(1)*arrRndPr + ...
                W(2)*(1.5 - arrMCost ./ nMTOC) + ...
                W(3)*(1.5 - nTch ./ arrTidle) + ...
                u_s + W(4);
    
    % 最优充电级别与时段
    [p, i] = max(arrPrior);
    best_prior = p;
    best_idx = pindex_start + i - 1;
    % 是否建议充电
    will_charge = (best_prior > 0.5);
end