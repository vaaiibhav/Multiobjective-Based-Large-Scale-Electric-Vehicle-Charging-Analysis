function [xlo, ylo] = DrawPatch(x_data, y_data, confidence_level)
    [list_perc, index] = sort(y_data, 'descend');
    
    energy = 0.0;	k = 1;
    arr_periods = [];
    energy_confidence = sum(y_data) * confidence_level;
    while( abs((energy_confidence / energy) - 1.0) > 1e-2 )
        if (k > length(index))
            break
        end
        arr_periods = [arr_periods, x_data( index(k) )];
        energy = energy + list_perc(k);
        k = k + 1;
    end
    
    cutoff1 = min(arr_periods);
    cutoff2 = max(arr_periods);

    xlo = [cutoff1 x_data(cutoff2>=x_data & x_data>=cutoff1) cutoff2];
    ylo = [0 y_data(cutoff2>=x_data & x_data>=cutoff1) 0];
    
    peak_period = patch(xlo, ylo, 'b', 'FaceColor', 'r', 'FaceAlpha', 0.08, ...
        'linestyle', '-.', 'LineWidth', 2.0, ...
        'EdgeColor', 'r', 'EdgeAlpha', 0.4);
    %alpha(peak_period, 0.0);
end