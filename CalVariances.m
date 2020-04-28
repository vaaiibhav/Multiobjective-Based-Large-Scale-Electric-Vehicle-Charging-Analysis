function [y_vars, y_stds, y_valid] = CalVariances(y_indices)
    global mc_params
    
    % get rid of invalid Y, which are mainly caused by EVs are charged while a new term re-start
    invalid_y_idx = [1, length(y_indices)];
    for i=2:length(y_indices)
        if mod(i-1, mc_params.total_days) == 0
            invalid_y_idx = [invalid_y_idx, i-1, i];
        end
    end
    y_valid = y_indices;
    y_valid(invalid_y_idx) = [];

    % calculate variance coefficient
    len = length(y_valid);
    y_vars = zeros(1, len);
    y_stds = zeros(1, len);
    
    for i=1:len
        y_sub = y_valid(1:i);
        y_vars(i) = var(y_sub) / mean(y_sub);
        y_stds(i) = std(y_sub) / mean(y_sub);
    end
    
    % get rid of invalid variances
    invalid_v = [1, 2];
    y_vars(invalid_v) = [];
    y_stds(invalid_v) = [];
end