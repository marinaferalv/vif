function VIF = calculate_vif(X)
% CALCULATE_VIF Compute Variance Inflation Factor (VIF) for variables in a linear regression model.
%
%   Notes:
%       The VIF of a variable measures how much the variance of the regression coefficients is inflated due to multicollinearity with other variables.
%       A VIF greater than 5 or 10 is often considered indicative of problematic multicollinearity.
%
%   Use:
%       vif_values = calculate_vif(X) computes the VIF for each variable in a linear regression model represented by the matrix X.
%
%   Inputs:
%       X: A table or matrix where each column represents an independent variable in the regression model.
%          If a variable X1 is continuous (double), you should transform it to cell: num2cell(X1(:,1)
%          If a variable X2 is categorical (cell), you should transform keep it: X2(:,1) 
%          X = cell2table([X1,X2],'VariableNames',{'X1','X2'})
%
%   Outputs:
%       vif_values: A vector containing the VIF values corresponding to each variable in the regression model.
%
%   See also: fitlm, calculate_interaction_terms
% 
%   Notes:  if you want to calculate the VIF of the interaction term of several variables, use calculate_interaction_terms,
%           to add the to the variable's table. Example:
%           interaction_terms=[var1name,var2name];
%                   [int_result, int_names] = calculate_interaction(table_vars, interaction_terms,'not_all'); % add all minus 1 to avoid absolute correlation between levels of the same variable
%                   table_varsX=[table_vars,cell2table(num2cell(int_result,'VariableNames',int_names)]; 
% 
%   Author: Marina Fernandez-Alvarez
%   marina.fdez.alvarez@gmail.com

    %variable names
    varnames = X.Properties.VariableNames;

    %categorical vars
    categorical_vars = varfun(@(x) isa(x, 'cell'), X);
    categorical_vars = find(categorical_vars{1,:});
    X_categorical = X{:, categorical_vars};
    X_dummies = cell2mat(arrayfun(@(x) dummyvar(categorical(X_categorical(:, x))), 1:size(X_categorical, 2), 'UniformOutput', false));
                
    %continuous vars
    continuous_vars=1:size(X,2); continuous_vars=continuous_vars(~ismember(continuous_vars,categorical_vars));

    % Calculate VIF
    num_predictores = size(X, 2);
    VIF_values=[];
    clearvars VIF_names
    count=0;
    for i = 1:num_predictores
        if ismember(i,continuous_vars)
            Y_model=X{:, i};
            pos=1:size(X,2); pos=pos(~ismember(pos,[categorical_vars,i])); % %continuous vars position except itself
            X_continuous = X{:, pos};
            X_model=[X_continuous,X_dummies]; %continuous vars except itself + all dummyvars   
            mdl = fitlm(X_model, Y_model);
            count=count+1;
            VIF_names(count) = varnames(1,i);
            r_squared = mdl.Rsquared.Ordinary;
            vifc = 1 / (1 - r_squared);
            VIF_values(count) = vifc;
        else
            Y_model0=X{:, i};
            Y_dum = dummyvar(categorical(Y_model0)); 
            for ii=1:size(Y_dum,2)-1
                count=count+1;
                pos_y=1:size(Y_dum,2);pos_y=pos_y(~ismember(pos_y,[size(Y_dum,2),ii])); 
                if ~isempty(pos_y); other_lev_Y=Y_dum(:,pos_y); else; other_lev_Y=[]; end
                Y_model=Y_dum(:,ii);
                pos=1:size(X,2); pos=pos(~ismember(pos,[continuous_vars,i])); % %continuous vars position except itself
                X_continuous = X{:, continuous_vars};
                X_cat = X{:, pos}; 
                X_dum = cell2mat(arrayfun(@(x) dummyvar(categorical(X_cat(:, x))), 1:size(X_cat, 2), 'UniformOutput', false));
                X_model=[X_continuous,X_dum,other_lev_Y]; %dummyvars except itself 
                mdl = fitlm(X_model, Y_model);
                pos_level=find(Y_model==1); pos_level=pos_level(1,1);
                levelname=Y_model0{pos_level,1};
                VIF_names(count) = {[varnames{1,i} levelname]};
                r_squared = mdl.Rsquared.Ordinary;
                vifc = 1 / (1 - r_squared);
                VIF_values(count) = vifc;
            end
        end
    end

    %display results:
    clc;
    disp(char(10)); disp('*******************   Variance Inflation Factor (VIF)   *******************');  disp(char(10)); 
    VIF=cell2table((num2cell(VIF_values)),'VariableNames',VIF_names);
    disp(VIF);

end