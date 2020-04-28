function [wCoeff, minSOC] = Bin2VarByConstraint(pop)
    if size(pop, 1) == 1
        nVars = size(pop, 2) / 8;
        xBins = reshape(pop, 8, nVars)';
    else
        nVars = size(pop, 1);
        xBins = pop;
    end
    
    % 00000010 to 2
    xVars = bi2de(xBins, 'left-msb')';
    
    % bounded constraint: uint8 to [0.0 1.0]
    validW = xVars( 1, 1:(nVars-2) ) / 255;
    bias = xVars( 1, nVars-1 ) / 255;
    minSOC = xVars( 1, nVars ) / 255;
    
    % linear equality constraint: sum(Wi) = 1.0
    wCoeff = validW / sum(validW);
    if nVars == 4
%         wCoeff = [0, wCoeff];
        wCoeff = [wCoeff, 1];
    elseif nVars == 3
        wCoeff = [0, wCoeff, 1];
    elseif nVars == 5
        wCoeff = [wCoeff, bias];
    end
        
    %x = (de2bi(5, 8, 'left-msb') > 0);
end