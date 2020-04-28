function [q, r_start, r_end] = FindCommonValues(sequence)
    % 统计连续相等值 起始位置 及 个数
    k = Int32_Find( [true diff(sequence)~=0 true] );
    r = k(1:end-1);
    q = diff(k);

    % 求出连续值的起/止位置
    r_start = r;
    r_end = [ r_start(2:end) - 1, size(sequence, 2) ];
end