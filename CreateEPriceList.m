% http://wenku.baidu.com/link?url=iUecO4ipjQFd5tlFEtDPt8Rceil2ki8VUSXxJnE4SQrWv7cweuKj5rnZ_iXlrEHl1P9_RQ0oXN73MjYawX0ZKj1Lq6R_F3r7N-7ahfJKZ6m
function tou_eprice = CreateEPriceList()
	global t_periods
	global mc_params

	%price_list = xlsread('electricity_price_list');
    load './data/price_list.mat';

	% �۸�Ԫ/��ʱ
	ele_prices = price_list(:, 2)' / 1e3;
    
    % �������
    %DrawTOUPrice(ele_prices);

	% ʱ��
	plen = size(price_list, 1);
	ele_periods = (0 : (plen-1)) * (24 * 60 / plen);

	% time-of-use electricity price
	%tou_eprice.prices = ele_prices;
	%tou_eprice.periods = ele_periods;
	%tou_eprice.mprice = mean(ele_prices);
	
	% ת����ʽ��1 X periods_per_day�����ó�ÿһʱ�εĵ�ۣ�Ԫ/(��*ʱ��)
	tou_eprice.prices = zeros(1, mc_params.periods_per_day, 'single');
	for i=1:mc_params.periods_per_day
		ep_index = find( ele_periods <= t_periods(i)  );
		
		tou_eprice.prices(i) = ele_prices( ep_index(end) ) * ...
                                (mc_params.mins_per_period / 60);
    end
    
    % һ���и�ʱ��toc��ۣ�1 X periods_per_day����Ԫ/(��*ʱ��)
    tou_eprice.day_prices = tou_eprice.prices;
    
    % toc�վ��ۣ�Ԫ/(��*ʱ��)
    tou_eprice.mprice = mean(tou_eprice.day_prices);
	
    % ��ģ�������ظ���չ��
	tou_eprice.prices = repmat(tou_eprice.prices, 1, (mc_params.total_days + 1));
end


function DrawTOUPrice(price)
    % ��ʱ���
    X = 1:24;
    Y = price(X*2);
    plot(X, Y, '-bo', 'LineWidth', 1.5);
    
    axis( [1 24 0 1e-3] );
    set(gca,'xtick',0:1:24);
    %set(gca,'ytick',0:1:10);
    
    xlabel('Hours', 'FontSize', 12);
    ylabel('Price (RMB)', 'FontSize', 12);
    grid on
end
