%{
sizeOut = [1, 1000]; % sample size
mu = 100; % parameter of exponential 
r1 = 50;  % lower bound
r2 = 150; % upper bound

r = exprndBounded(mu, sizeOut, r1, r2); % bounded output    
%}

function r = ExprndBounded(mu, sizeOut, r1, r2)

minE = exp(-r1/mu); 
maxE = exp(-r2/mu);

randBounded = minE + (maxE-minE).*rand(sizeOut);
r = -mu .* log(randBounded);

end
