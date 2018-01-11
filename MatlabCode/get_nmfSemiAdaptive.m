function [ H,W,instrumentVhat ] = get_nmfSemiAdaptive(X,initW,p)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: get_nmfSemiAdaptive
%
% get semi adaptive calculated gain per time vector H and approximated spectrum
% for each instrument
%
% Input:
%   X: mixture spectrum
%   initW: initial basis function matrix
%   p: parameter container
%
% Output:
%   H: gain matrix
%   instrumentVhat: approximated instrument spectrogram
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[numRows,numCols] = size(X);
% remove zeros by adding one spacing of floating point numbers to avoid
% calculation problems when 1/X
X = X + eps;

% initialize basis function matrix
W = initW;

% initialize time vector matrix
H = ones(p.numInstruments,numCols);

% the estimated sources will be mixed with the initial ones
% whereas they will get stronger towards the end
weight = linspace(0,1,p.nmfIterations);

% iteratively calculate NMF parameters
for k = 1:p.nmfIterations 
  
    % pre-compute the approximation
    WH = eps+(W*H);

    % pre-compute basis transpose
    Wt = W';

    % update the gain functions using the formula introduced by Lee and
    % Seung
    H = H.*(Wt*(X.*WH.^(p.beta-2)))./( eps+(Wt*WH.^(p.beta-1)));

    % pre-compute gain transpose
    Ht = H';

    % pre-compute approximation
    WH = eps+(W*H);

    % update the basis functions using the formula introduced by Lee and
    % Seung
    W = W.*((X.*WH.^(p.beta-2))*Ht)./( eps+((WH).^(p.beta-1)*Ht));  

    %% mix with originally estimated sources
    % this is the semi-adaptive part
    % Here, the blending parameter is calculated. The blending_parameter 
    % depends on the ratio of current iteration count k to iteration limit 
    % taken to the power of adapt_power as shown in the according equation
    % in the paper
    blending_parameter = repmat((weight(k).*p.adaptDegree).^p.adaptPower,numRows,1);
    
    %limit blending parameter to 1.0
    blending_parameter(:,p.adaptDegree > 1.0) = 1;

    % compute counter part
    initWeight = 1-blending_parameter;
    W = W.*blending_parameter + initW.*initWeight;
  
    % apply normalization to all basis functions
    normB = 1./(eps+sum(W)); 
    W = bsxfun(@times,W,normB);
  
end

% generate the component approximations
for k = 1:p.numInstruments
    instrumentVhat{k} = W(:,k)*H(k,:);
end