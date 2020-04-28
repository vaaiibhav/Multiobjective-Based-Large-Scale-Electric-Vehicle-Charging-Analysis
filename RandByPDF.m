function values = RandByPDF(fitness, r, c)
    if r == 0 || c == 0
        values = [];
        return ;
    end

    fit_pdf = fitness.pdf;
    bounded = fitness.x;
    
    values = single(random(fit_pdf, r*c, 1));
    %norm_values = mapminmax(r_values', min(bounded), max(bounded));
    
    % recursion to replace the invalid values
    idx_invalid = [find(values < min(bounded)); find(values > max(bounded))];
    values_valid = RandByPDF(fitness, length(idx_invalid), 1);
    
    values(idx_invalid) = values_valid;
    
    % reshape
    values = reshape(values, r, c);
end
