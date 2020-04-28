function prices = CalChargePrices(cp_index)
	global t_periods
	global TOU_EPrice
	global battery_features
	
	prices = single( zeros(1, length(cp_index)) );
	for i=1:length(cp_index)
		charge_periods = cp_index(i) : (cp_index(i) + battery_features.fcharge_periods - 1);
		charge_prices = TOU_EPrice.prices( charge_periods );
		
		prices(i) = mean(charge_prices);
	end
end