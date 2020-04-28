% m_w_load: 一天中电网各时段负荷平均值，periods_per_day X mean_load
% m_w_charged: 一天中EV各时段充电平均值，periods_per_day X mean_charge
% m_real_trv：一天中EV各时段出行次数平均值，periods_per_day X mean_real_travel
% m_plan_trv：一天中EV各时段计划出行次数平均值，periods_per_day X mean_plan_travel
function [Y, Rmp, Rsc, Rt] = CalIndices(m_w_load, m_w_charged, ...
                                        m_real_trv, m_plan_trv, is_print)
    global TOU_EPrice
    
%     W1 + W2 + W3 = 1.0
%     W1 * 0.275 = W2 * 0.440 = W3 * 0.975 = Si
% 
%     Mi = [0.275 0.440 0.975]
%     Wi = [0.5455    0.3409    0.1538]
%     Si = [0.15 0.15 0.15]
    
    % 指标统计范围 及 权重系数
    RAGmp = [0.05 0.25];	RAGsave=[0.15 0.75];	RAGtrip=[0.95 1.0];
    Wi = [0.4 0.3 0.3];
    
    % 谷峰比 ＝ 充电谷值／充电峰值
%     nWValley = min(m_w_load);
%     nWPeak = max(m_w_load);
%     Rpv = nWValley / nWPeak;

    % 均峰比 ＝ 充电均值／充电峰值
    nWMeanLoad = mean(m_w_load);
    nWPeakLoad = max(m_w_load);
    Rmp = nWMeanLoad / nWPeakLoad;

    % 用户节省电费率 ＝ 1 - 实际电费/最高电费
    nRealCost = sum(m_w_charged .* TOU_EPrice.day_prices);
    nMaxCost = sum(m_w_charged .* max(TOU_EPrice.day_prices));
    Rsc = 1 - nRealCost / nMaxCost;
    
    % 顺利出行率 ＝ 实际里程/计划里程
    nRealTrv = sum(m_real_trv);
    nPlanTrv = sum(m_plan_trv);
    Rt = nRealTrv / nPlanTrv;
    
%     Rmp = 0.218;
%     Rsc = 0.193;
%     Rt = 0.972;
    
    % 综合指标：均峰比，节能率，出行率
    Y = Wi(1) * (Rmp - min(RAGmp)) / (max(RAGmp) - min(RAGmp)) + ...
        Wi(2) * (Rsc - min(RAGsave)) / (max(RAGsave) - min(RAGsave)) + ...
        Wi(3) * (Rt - min(RAGtrip)) / (max(RAGtrip) - min(RAGtrip));
    
    if isnan(Y)
        Y = 0.0;
    end
    
    % 输出结果
    if is_print
        fprintf('----电网负荷：峰值= %d 瓦；均值= %d 瓦；均峰比= %f----\n', nWPeakLoad, nWMeanLoad, Rmp);
        fprintf('----居民用电费用：实际电费= %f 元；最高电费= %d 元；节省率= %f----\n', nRealCost, nMaxCost, Rsc);
        fprintf('----顺利出行情况：实际出行里程= %f 公里；计划出行里程= %d 公里；出行率= %f----\n', nRealTrv, nPlanTrv, Rt);
        fprintf('----综合指标：Y= %f----\n', Y);
    end
end