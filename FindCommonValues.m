function [q, r_start, r_end] = FindCommonValues(sequence)
    % ͳ���������ֵ ��ʼλ�� �� ����
    k = Int32_Find( [true diff(sequence)~=0 true] );
    r = k(1:end-1);
    q = diff(k);

    % �������ֵ����/ֹλ��
    r_start = r;
    r_end = [ r_start(2:end) - 1, size(sequence, 2) ];
end