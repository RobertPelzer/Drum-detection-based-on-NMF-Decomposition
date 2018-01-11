function [ meanTrainSet, TrainSetCatalog ] = get_trainSetMean(instrument, p )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: get_trainSetMean
%
% generate a average training set for the specified instrument in
% <instrument>
%
% Input:
%   instrument: specified instrument, e.g ('HH', 'SD' or 'KD')
%   p: parameter container
% 
% Output:
%   meanTrainSet: average basis function of the specified instrument
%   TrainSetCatalog: all basis functions of the specific instrument side by
%                    side in a kind of catalog
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize basis function matrix
initW = [];

% window function to generate the spectrum
winFunc = hann(p.blockSize);

% list of indices of the specific instrument named in <instrument> e.g ('HH', 'SD', 'KD')
indexInstrumentWAV = find(~cellfun(@isempty,strfind(p.cellFilenamesWAV,instrument)));

n = 0;

% loop over training sets 
for i = 1:p.numTrainSets
    msg = sprintf('Fill Training Catalog for %s: %d/%d',instrument ,i ,p.numTrainSets);
    fprintf(repmat('\b',1,n));
    fprintf(msg);
    n=numel(msg);
    
    % current audio name
    currentAudioname = char(p.cellFilenamesWAV{indexInstrumentWAV(i)});
    % read training signal from file
    [sig,~] = audioread([p.audioDirWAV,currentAudioname]);

    % get the spectrum
    S = spectrogram(sig,winFunc,p.blockSize-p.hopSize);
    % save in initW the basis function
    initW(:,i) = mean(abs(S')); %% get average spectrum over time
end
fprintf('\n');

% save initW catalog
TrainSetCatalog = initW;
% average over all training set spectrograms in initW
meanTrainSet = mean(initW(:,p.trainSetStart:p.trainSetEnd)');
end