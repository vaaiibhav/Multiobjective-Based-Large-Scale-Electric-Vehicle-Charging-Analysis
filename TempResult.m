function tRes = TempResult(operate, pRes)
    global mc_params
    global solutions
    
    if strcmp(operate, 'load') == 1
        if ~mc_params.save_result
            tRes = mc_params.memory_result;
        else
            load(sprintf('./data/temp_result_EVs(%d)_Days(%d)_Slt(%d).mat', ...
                    mc_params.total_EVs, mc_params.all_days, solutions.start_charging));
            tRes = result;
        end
        
    elseif strcmp(operate, 'save') == 1
        if ~mc_params.save_result
            mc_params.memory_result = pRes;
        else
            result = pRes;
            save(sprintf('./data/temp_result_EVs(%d)_Days(%d)_Slt(%d).mat', ...
                    mc_params.total_EVs, mc_params.all_days, solutions.start_charging), ...
                    'result', '-v7.3');
        end
        
    end
end