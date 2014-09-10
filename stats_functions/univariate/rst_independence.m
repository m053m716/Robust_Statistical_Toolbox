function [Chi2,pval,effect_size]=rst_independence(X,Y,test)

% this function allows to test the independance of two data sets X and Y
% for 2 x 2 contingency tables
%
% FORMAT [Chi2,pval,effect_size]=rst_independence(X,Y,test)
%
% INPUT X and Y are two vectors (n*1) of 1s and 0s indicating success or failure
%       using X and Y a contigency table is created with 4 classes: a, b, c, d
%       -----------------------------------------------------------------
%                            |                    X
%                            |      success              failure
%       -----------------------------------------------------------------
%                success    |         a                    b
%          Y                |
%                failure    |         c                    d
%       -----------------------------------------------------------------
%       test indicates the test to perform: 'McNemar' or 'Pearson'
%       McNemar test is used for paired nominal data (same subjects)
%       Pearson's Chi Square is used for unpaired data
%
% OUTPUT [Chi2,pval,effect_size]=rst_independence(a,b,c,d,type)
%         Chi2 is the Chi-square value (the statistics)
%         p val is the p value for the theoretical distribution
%         effect size is odd ratio 
%
% McNemar test: The null hypothesis is that marginals prob are the same, 
% that is, a+b=a+c and d+c=d+b thus effectively testing that c = b. The 
% Chi-square stat is (b-c)^2 / (b+c) and the p value is obtained using the
% central Fisher�s exact test (Fay, 2010), i.e. using a binomial distribution#
% of b on b+c with 50% of success. Correction for continuity, use of Chi^2
% distribution, etc were usefull before we could compute easily the exact
% binomial value, so this is not used here (ie these are outdated practices)
% Significance indicates that tests 1 and tests 2 are not associated.
% Ref: McNemar, Q. (1947). Note on the sampling error of the difference between
% correlated proportions or percentages" Psychometrika 12:153-157.
% Fay,(2010) Biostatistics, 11, 2, pp. 373�374 doi:10.1093/biostatistics/kxp050
%
% Pearson's Chi Square
% The null hypothesis is that the occurrence of the observed
% outcomes are independent, ie each cell as a frequency of (colunn*row)/total
% The Chi-square stat is the sum of (Observed-Expected)^2 / Expected over each cells
% For permutation testing, since under the null all cells are equal, the classes
% are ramdomly assigned a 1000 times and distribution obtained. The p value
% is 2*(1-number of times the observed Chi^2 above the alpha quantile)
% Significance indicates that the 2 variables are associated
% Ref Yates, F (1934). "Contingency table involving small numbers and the ?2 test". 
% Supplement to the Journal of the Royal Statistical Society 1(2): 217�235
%
% Cyril Pernet - v1 - Septembre 2014
% ----------------------------------------------------------------------
% Copyright (C) RST Toolbox Team 2014


%% imputs

if nargin ~=3
    error('three inputs expected')
end

[n1,p1]=size(X);
if n1==1 && p1>1
    X=X';
    [n1,p1]=size(X);
end

[n2,p2]=size(Y);
if n2==1 && p2>1
    Y=Y';
    [n2,p2]=size(Y);
end

if n1~=n2
    error('the number of observations is not the same for X and Y')
end

if (~strcmp(lower(test),'mcnemar') .* ~strcmp(lower(test),'pearson'))
    error('test name unrecognized: use McNemar or Pearson')
end

%% Make the contingency table
a = sum((X+Y)==2); % success for X and Y
b = length(intersect(find(X==0),find(Y==1))); % failure for X and success for Y
c = length(intersect(find(X==1),find(Y==0))); % success for X and failure for Y
d = sum((X+Y)==0); % failure for X and Y

% display in the command window
disp('-------------------------------------------------------')
disp('                 |                X                   |')
disp('                 |    success          failure        |')
disp('-------------------------------------------------------')
fprintf('      success    |      %g                %g            |\n',a,b)
disp('  Y              |                                    |')
fprintf('      failure    |      %g                %g            |\n',c,d)
disp('-------------------------------------------------------')

% quick check
if a+b+c+d ~= n1
    error('something went wrong, the sum of cells does not sum to N')
end


switch lower(test)
    
%% McNemar test
    case {'mcnemar'}
        
        Chi2 = ((b-c)^2) / (b+c);
        % pval = min(1,2*min(binocdf(b,(b+c),0.5),1-binocdf(b,(b+c),0.5))); % central Fisher�s exact test
        pval = min(1,2*min(1-binocdf(b,(b+c),0.5)));
        
        % odd ratio and 95% CI
        if nargout == 3
            effect_size.phi = b / c;  % odd ratio
        end
        
%% Pearson test
        
    case {'pearson'}
        
        % marginal values
        row1 = a+b; row2 = c+d; column1 = a+c; column2 = b+d;
         
        if a>5 && b>5 && c>5 && d>5
            
            % compute the expected counts from marginal data
            expected(1) = row1*column1/n1;
            expected(2) = row1*column2/n1;
            expected(3) = row2*column1/n1;
            expected(4) = row2*column2/n1;
            
            % Chi^2
            Chi2 = ((a-expected(1))^2) / expected(1) + ...
                ((b-expected(2))^2) / expected(2) + ...
                ((c-expected(3))^2) / expected(3) + ...
                ((d-expected(4))^2) / expected(4);
           pval = 1 -chi2cdf(Chi2,1);
           
        else % apply Yates correction
            % (http://en.wikipedia.org/wiki/Yates%27s_correction_for_continuity)
            
            Chi2 = (n1*(max(0,(abs(a*b-b*c)-n1/2)))^2) / (row1*row2*column1*column2);
            pval = 2*(1-binocdf(b,(b+c),0.5)); % Fisher exact test
            
        end
        
        if nargout == 3
            effect_size.phi = Chi2 / n1;
        end
        
end











