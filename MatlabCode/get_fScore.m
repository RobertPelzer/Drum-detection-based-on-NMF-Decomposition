function [ currentItem ] = get_fScore( currentItem, p )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: get_fScore
%
%   F - score
%   f_n false negative -> onset detected, but no ground truth
%   f_p false positive -> onset not detected, but ground truth detects a
%   hit
%       detection in    |     ground truth
%           algo        |  yes  |   no    |
%           yes         |  r_p  |   f_p   |
%           no          |  f_n  |   r_n   |
%  
%       precision = r_p /(r_p + f_p);
%       recall = r_p /(r_p +f_n);
%       F  = precision * recall / ( precision + recall)
% 
% Input:
%   currentItem: current item container
%   p: parameter container
% 
% Output:
%   currentItem: fill current item F score values
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate F Score, instrument loop
for k = 1:p.numInstruments
    % get groundtruth
    GT = currentItem.GT_onsets.(p.instruments{k});
    % get values of onsets detection
    CUS = currentItem.CUS_onsets.(p.instruments{k});
    
    %% calculate F score
    % length of ground truth vector
    GT_len = length(GT);
    % initialize right positive vector with zeors
    r_p = zeros(GT_len,1);
    % initialize false negative vector with ones
    f_n = ones(GT_len,1);
    % initialize false positive vector with ones
    f_p = ones(length(CUS),1);

    j_n = 0;
    for i = 1: GT_len
        for j = 1:length(CUS)
            if abs(GT(i) - CUS(j)) < p.fScoreTolerance
                if r_p(i) ==    0
                    r_p(i) = 1;
                    j_n = j_n + 1;
                    f_p(j) = 0;
                end
            end
        end
    end

    f_n = f_n - r_p; 
    r_p = sum(r_p);
    f_p = sum(f_p);
    f_n = sum(f_n);

    % calculate precision
    precision = r_p /(r_p + f_p);
    % calculate recall
    recall = r_p /(r_p +f_n);
    % calculate f score
    F  = 2* precision * recall / ( precision + recall);

    % if f score is zero, no matches exist and a warning message is printed
    if F==0
        disp('No matches, please increase tolerance')
    end

    % if no grondtruth exist f score = nan
    if GT_len==0
        F = nan; 
    end
    
    % write into current item container F score value
    currentItem.F.(p.instruments{k}) = F;
end