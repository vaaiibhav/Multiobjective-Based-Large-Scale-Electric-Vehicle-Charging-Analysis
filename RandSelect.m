function data_selected = RandSelect(data, n)
    rand = randperm( length(data) );
    index = rand(1:n);
    index = sort(index);
    data_selected = data(index);
end