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
    
    % ����Ȩ��ϵ��
    if solutions.start_charging == 4    %�������ϲ��ԣ���������ϵ��
        W = solutions.w_coeff;
        % ʣ��SOC/���SOC
        u_s = 1.5 - cur_soc / battery_features.lowest_soc;
    else
        W = zeros(1, 4);
        W(solutions.start_charging) = 1;
        W(4) = 1;
        
    end
    
    % �Ƿ������
        if is_necessary
            u_s = 10000;    %inf
        else
            u_s = 0;
        end
    
    
    nPrior = length(arrMCost);
    % ��ĳ��ʱ�̿�ʼ����ƽ����ۣ�Ԫ/���ߣ�ʱ�Σ�
    %arrMCost = [];
    % TOCƽ����ۣ�Ԫ/���ߣ�ʱ�Σ�
    nMTOC = TOU_EPrice.mprice;
    % �������ʱ��
    nTch = single( battery_features.fcharge_periods );
    % ʣ�����ʱ��
    nTidle = pindex_end - pindex_start + 1;
    arrTidle = single(nTidle) : -1 : nTch;
    % ������� [0 1]
    nRndPr = round(rand);
    arrRndPr = single( nRndPr * rand(1, nPrior) );
    
    % ���㲻ͬʱ�εĳ�����ȳ̶�
    arrPrior = W(1)*arrRndPr + ...
                W(2)*(1.5 - arrMCost ./ nMTOC) + ...
                W(3)*(1.5 - nTch ./ arrTidle) + ...
                u_s + W(4);
    
    % ���ų�缶����ʱ��
    [p, i] = max(arrPrior);
    best_prior = p;
    best_idx = pindex_start + i - 1;
    % �Ƿ�����
    will_charge = (best_prior > 0.5);
end