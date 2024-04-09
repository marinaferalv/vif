function [int_result, int_names] = calculate_interaction_terms(table_vars, interaction_terms,type)
%  CALCULATE_INTERACTION_TERMS Function to calculate interaction term of variables in a table 
% 
%   Inputs:
%       table_vars: A table or matrix where each column represents an independent variable in the regression model.
%          If a variable X1 is continuous (double), you should transform it to cell: num2cell(X1(:,1)
%          If a variable X2 is categorical (cell), you should transform keep it: X2(:,1) 
%          X = cell2table([X1,X2],'VariableNames',{'X1','X2'})
%
%       interaction_terms: cell array (1,n) with the name of variables to compute 
%                         the interaction term; the name of the variables must be the same as in
%			              table_vars. Options of variables: 3 double, 2 double, 2 categorical, 
%			              1 double 1 categorical, 1 double 2 categorical or 2 double 1 categorical   
%       type: char indicating 'all' / 'not_all'. Default: type='all'; if
%             'not_all'> it gives as output the interaction term columns except
%             one to avoid absolute correlation if vif it is going to be computed
%
%   Outputs:
%       int_result: A matrix containing interaction terms.
%	    int_names: vector containing the name of interacction terms
%
%   Author: Marina Fernandez-Alvarez
%   marina.fdez.alvarez@gmail.com

    if nargin==2
        type='all';
    end

    % Extract variable names and their indices
    variable_names = table_vars.Properties.VariableNames;
    variable_indices = zeros(1, length(interaction_terms));
    for i = 1:length(interaction_terms)
        [~, variable_indices(i)] = ismember(interaction_terms{i}, variable_names);
    end
    var_names=variable_names(variable_indices);

    % Remove indices with value 0
    variable_indices = variable_indices(variable_indices ~= 0);

    % Check if variables are continuous or categorical
    vars_int = table_vars(:, variable_indices);
    vars_int_cont=[]; vars_int_cat=[]; cont_names=[];
    for v = 1:size(vars_int,2)
        var_i=vars_int{:,v};
        if isnumeric(var_i)
            vars_int_cont=[vars_int_cont,var_i];
            cont_names=[cont_names,var_names(1,v)];
        else
            vars_int_cat=[vars_int_cat,var_i];
        end
    end

    % Compute interactions
    if ~isempty(vars_int_cont)
        vars_int_cont_int=prod(vars_int_cont,2); cont_names_int=char(string(join(cont_names,'_')));
    end
    if ~isempty(vars_int_cat)
        if length(cont_names)==2
            % add double interaccion
            int_names_onlycont = {cont_names_int};
            int_result_onlycont = vars_int_cont_int;
        elseif length(cont_names)==3
            % add double and triple interaccion
            int_names_onlycont = {[cont_names_int, char(string(join(cont_names(1,[1,2]),'_'))), char(string(join(cont_names(1,[1,3]),'_'))), char(string(join(cont_names(1,[2,3]),'_')))]};
            int_result_onlycont = [vars_int_cont_int,prod(vars_int_cont(:,[1,2]),2),prod(vars_int_cont(:,[1,3]),2),prod(vars_int_cont(:,[2,3]),2)];
        else
            int_names_onlycont = [];
            int_result_onlycont = [];
        end
        % all continuous
        all_cont_names=[cont_names,int_names_onlycont];
        all_cont=[vars_int_cont,int_result_onlycont];

        % add interaccion with categorical variables
        if size(vars_int_cat,2)==2
            vars_int_cat = strcat(vars_int_cat(:, 1), {'_'}, vars_int_cat(:, 2));
        end
        vars_int_cat_d=dummyvar(categorical(vars_int_cat));
        vars_int_cat_labels = categories(categorical(vars_int_cat)); vars_int_cat_labels=vars_int_cat_labels';

        if ~isempty(vars_int_cont)
            int_names = [int_names_onlycont]; % provisional output
            int_result = [int_result_onlycont];% provisional output
            if string(type)=="all"
                for vv=1:length(all_cont_names)
                    vcont_name=all_cont_names{1,vv};
                    vcont=all_cont(:,vv);
                    int_names_cat = cellfun(@(x) [x '_' vcont_name], vars_int_cat_labels, 'UniformOutput', false); 
                    int_result_cat = vars_int_cat_d.*vcont;
                    % output
                    int_names = [int_names,int_names_cat];
                    int_result = [int_result,int_result_cat];
                end
            elseif string(type)=="not_all"
                vars_int_cat_d=vars_int_cat_d(:,end-1);
                vars_int_cat_labels = vars_int_cat_labels(1,end-1);
                for vv=1:length(all_cont_names)
                    vcont_name=all_cont_names{1,vv};
                    vcont=all_cont(:,vv);
                    int_names_cat = cellfun(@(x) [x '_' vcont_name], vars_int_cat_labels, 'UniformOutput', false);
                    int_result_cat = vars_int_cat_d.*vcont;
                    % output
                    int_names = [int_names,int_names_cat];
                    int_result = [int_result,int_result_cat];
                end
            else
                error('Third input is wrong.')
            end
        else
            if string(type)=="all"
                int_names = [vars_int_cat_labels]; 
                int_result = [vars_int_cat_d];
            elseif string(type)=="not_all"
                vars_int_cat_d=vars_int_cat_d(:,end-1);
                vars_int_cat_labels = vars_int_cat_labels(1,end-1);
                int_names = [vars_int_cat_labels]; 
                int_result = [vars_int_cat_d];
            end
        end
        
    else % only double
        if length(cont_names)==2
            int_names={cont_names_int};
            int_result=vars_int_cont_int;
        elseif length(cont_names)==3
            % add double and triple interaccion
            int_names=[{cont_names_int},{char(string(join(cont_names(1,[1,2]),'_')))},{char(string(join(cont_names(1,[1,3]),'_')))},{char(string(join(cont_names(1,[2,3]),'_')))}];
            int_result=[vars_int_cont_int,prod(vars_int_cont(:,[1,2]),2),prod(vars_int_cont(:,[1,3]),2),prod(vars_int_cont(:,[2,3]),2)];
        end
    end

end

