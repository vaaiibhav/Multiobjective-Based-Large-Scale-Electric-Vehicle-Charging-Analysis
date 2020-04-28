function rand_values = RandUniform(rows, columns, min, max)
   rand_values = round( 0 + rand(rows, columns) * ( max - min ) );
end