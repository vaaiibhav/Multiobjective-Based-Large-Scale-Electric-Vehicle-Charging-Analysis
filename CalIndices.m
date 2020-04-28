% m_w_load: һ���е�����ʱ�θ���ƽ��ֵ��periods_per_day X mean_load
% m_w_charged: һ����EV��ʱ�γ��ƽ��ֵ��periods_per_day X mean_charge
% m_real_trv��һ����EV��ʱ�γ��д���ƽ��ֵ��periods_per_day X mean_real_travel
% m_plan_trv��һ����EV��ʱ�μƻ����д���ƽ��ֵ��periods_per_day X mean_plan_travel
function [Y, Rmp, Rsc, Rt] = CalIndices(m_w_load, m_w_charged, ...
                                        m_real_trv, m_plan_trv, is_print)
    global TOU_EPrice
    
%     W1 + W2 + W3 = 1.0
%     W1 * 0.275 = W2 * 0.440 = W3 * 0.975 = Si
% 
%     Mi = [0.275 0.440 0.975]
%     Wi = [0.5455    0.3409    0.1538]
%     Si = [0.15 0.15 0.15]
    
    % ָ��ͳ�Ʒ�Χ �� Ȩ��ϵ��
    RAGmp = [0.05 0.25];	RAGsave=[0.15 0.75];	RAGtrip=[0.95 1.0];
    Wi = [0.4 0.3 0.3];
    
    % �ȷ�� �� ����ֵ������ֵ
%     nWValley = min(m_w_load);
%     nWPeak = max(m_w_load);
%     Rpv = nWValley / nWPeak;

    % ����� �� ����ֵ������ֵ
    nWMeanLoad = mean(m_w_load);
    nWPeakLoad = max(m_w_load);
    Rmp = nWMeanLoad / nWPeakLoad;

    % �û���ʡ����� �� 1 - ʵ�ʵ��/��ߵ��
    nRealCost = sum(m_w_charged .* TOU_EPrice.day_prices);
    nMaxCost = sum(m_w_charged .* max(TOU_EPrice.day_prices));
    Rsc = 1 - nRealCost / nMaxCost;
    
    % ˳�������� �� ʵ�����/�ƻ����
    nRealTrv = sum(m_real_trv);
    nPlanTrv = sum(m_plan_trv);
    Rt = nRealTrv / nPlanTrv;
    
%     Rmp = 0.218;
%     Rsc = 0.193;
%     Rt = 0.972;
    
    % �ۺ�ָ�꣺����ȣ������ʣ�������
    Y = Wi(1) * (Rmp - min(RAGmp)) / (max(RAGmp) - min(RAGmp)) + ...
        Wi(2) * (Rsc - min(RAGsave)) / (max(RAGsave) - min(RAGsave)) + ...
        Wi(3) * (Rt - min(RAGtrip)) / (max(RAGtrip) - min(RAGtrip));
    
    if isnan(Y)
        Y = 0.0;
    end
    
    % ������
    if is_print
        fprintf('----�������ɣ���ֵ= %d �ߣ���ֵ= %d �ߣ������= %f----\n', nWPeakLoad, nWMeanLoad, Rmp);
        fprintf('----�����õ���ã�ʵ�ʵ��= %f Ԫ����ߵ��= %d Ԫ����ʡ��= %f----\n', nRealCost, nMaxCost, Rsc);
        fprintf('----˳�����������ʵ�ʳ������= %f ����ƻ��������= %d ���������= %f----\n', nRealTrv, nPlanTrv, Rt);
        fprintf('----�ۺ�ָ�꣺Y= %f----\n', Y);
    end
end