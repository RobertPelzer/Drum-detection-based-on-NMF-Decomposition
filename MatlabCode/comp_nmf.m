function [ currentItem ] = comp_nmf( currentItem, p )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: comp_nmf
%
% prepare trainig set and execute semi adaptive nmf frame wise
%
% Input:
%   currentItem: current item container
%   p: parameter container
% 
% Output:
%   currentItem:    fill current item with gain matrix H
%                   and approximated instrument spectrograms
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize window function for framewise nmf
winFunc = hann(p.blockSize);

% initialize basis function matrix
initW = [];

%% get training signals and extract templates spectra
for k = 1:p.numInstruments
    switch(p.trainSetMode)
        % Mode 0: train set of specific mix
        case 0
          sig = currentItem.(['audio_',p.instruments{k}]);
        % Mode 1: specific train set name in p.trainSet
        case 1
          try
              sig = audioread([p.trainSet,p.instruments{k},'#train.wav']);
          catch
              warning('trainSet not found.. using standard train set ./audio/RealDrum01_00#');
              sig = audioread(['./audio/RealDrum01_00#',p.instruments{k},'#train.wav']);
          end
        % Mode 2: mean of all train sets for a specific range of training sets
        case 2
          initW(:,1) = p.trainSetMean.KD;
          initW(:,2) = p.trainSetMean.SD;
          initW(:,3) = p.trainSetMean.HH;
    end
    
    if(p.trainSetMode ~= 2)
        % load spectrum
        S = spectrogram(sig,winFunc,p.blockSize-p.hopSize);
        % get average spectrum over time
        initW(:,k) = mean(abs(S'));
    end
end

%% get mix signal and it's magnitude spectrogram

sig = currentItem.audio_MIX;
S = spectrogram(sig,winFunc,p.blockSize-p.hopSize);
V = abs(S);
[~,numFrames] = size(V);

currentItem.mixSpectrum = V;

% normalize template spectra
initW = bsxfun(@times,initW,1./(eps+sum(initW)));

% save initW into current item
currentItem.Winit = initW;

% perform semi-adaptive beta NMF on each frame
nmfV = [];
n = 0;

for i = 1:numFrames
    msg = sprintf('Frame: %d/%d', i, numFrames);
    fprintf(repmat('\b',1,n));
    fprintf(msg);
    n=numel(msg);

    % apply NMF to each frame
    [nmfH(:,i),nmfW,tmpV] = get_nmfSemiAdaptive(V(:,i),initW,p);

    % store results
    for k = 1:p.numInstruments
        nmfV{k}(:,i) = tmpV{k};
    end
end
fprintf('\n');

% write results in current item container
currentItem.nmfV = nmfV;
currentItem.H = nmfH;
currentItem.W = nmfW;

end

