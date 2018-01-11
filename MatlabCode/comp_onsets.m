function [ currentItem ] = comp_onsets( currentItem, p)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: comp_onsets
%
%   This function gets reconstructed spectrogram of each instrument.
%   Calculates in 5 different frequency bands the novelty curve 
%   from differentiated gaim function and
%   generates one novelty curve out of these fives bands.
%   The onsets are calculated with an dynamic threshold and plausibilty
%   creteria
%
% Input:
%   currentItem: current item container
%   p: parameter container
% 
% Output:
%   currentItem: fill current item with calculated onsets
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% length of reconstructed instrument spectrogram in samples
numFrames = size(currentItem.nmfV{1},2);
currentItem.numFrames = numFrames;

% constant for logarithmation
C = 1;

% initialize novelty Curve
D = zeros(p.numInstruments,numFrames);
currentItem.D = [];

% initialize threshold
T = zeros(p.numInstruments,numFrames);
currentItem.T = [];

% initialize time vectors per instrument
time = zeros(p.numInstruments,10);
Sample_per_Frame = floor(length(currentItem.audio_MIX)/numFrames);

% window for differentation
myhann = @(n)  0.5-0.5*cos(2*pi*((0:n-1)'/(n-1)));

for k = 1:p.numInstruments
    % current instrument spectrum
    Spektrum = currentItem.nmfV{k};
    
    % initialze bands
    bands = [0 500; 500 1250; 1250 3125; 3125 7812.5; 7812.5 floor(currentItem.fs./2)];
    bandNoveltyCurves = zeros(size(bands,1),size(Spektrum,2));

    for band = 1:size(bands,1)

        % bin calculation
        bins = round(bands(band,:)./ (currentItem.fs./p.blockSize));
        bins = max(1,bins);
        bins = min(round(p.blockSize/2)+1,bins);

        bandSpektrum= Spektrum(bins(1):bins(2),:);

        % logarithmation
        bandSpektrum = log(1+C.*bandSpektrum)/log(1+C);

        % smoothed differentiator
        diff_len = 0.3;%sec
        diff_len = max(ceil(diff_len*currentItem.fs/p.blockSize),5);
        diff_len = 2*round(diff_len./2)+1;
        diff_filter = myhann(diff_len).*[-1*ones(floor(diff_len/2),1); 0;ones(floor(diff_len/2),1) ];
        diff_filter = diff_filter(:)';    
        bandDiff = filter2(diff_filter, [repmat(bandSpektrum(:,1),1,floor(diff_len/2)),bandSpektrum,repmat(bandSpektrum(:,end),1,floor(diff_len/2))]);
        bandDiff = bandDiff.*(bandDiff>0);
        bandDiff = bandDiff(:,floor(diff_len/2):end-floor(diff_len/2)-1);

        % novelty curve of the band
        noveltyCurve = sum( bandDiff);
        bandNoveltyCurves(band,:) = noveltyCurve;

    end
    % average novelty curve
    D(k,:) = mean(bandNoveltyCurves);   

    % normalize novelty curve       
    D(k,:) = D(k,:)/max(D(k,:));

    % threshold calculation
    % compression with ^2
    T(k, :) = D(k, :).^2;

    % filtering with exponential moving average filter
    % a higher value of alpha will have less smoothing
    alpha = 0.01 ;
    T(k, :) = filter(alpha, [1 alpha-1],T(k, :));

    % expansion with ^0.5
    T(k, :) = T(k, :).^0.5;

    % boostfactor
    b=0.3;

    T(k, :) = mean(T(k, :))*b + T(k, :);
    
    % initialize condition parameter
    tcount=1;
    On=0;
    Off=0;
    
    % frame counter for frames above threshold
    frame_count=0;

    % frame wise onset condition loop
    for i= 1:numFrames
        % plausibility rules by Battenberg and Dittmar
        if D(k,i) > T(k, i) 
            frame_count=frame_count+1;
        else
            frame_count=0;
        end

        if frame_count == p.nNeighbour
            On=1;
            frame_count=0;
        end

        if On==1 && or(Off==1,i==1)
            time(k, tcount)=i*Sample_per_Frame/currentItem.fs;
            tcount=tcount+1;
            On=0;
            Off=0;
        end

        if   D(k,i) < T(k, i)
            Off=1;

        end

    end

end

currentItem.D = D;
currentItem.T = T;

% getting rid of null's
for k = 1: p.numInstruments
    temp = time(k,time(k,:) > 0);
    currentItem.CUS_onsets.(p.instruments{k}) = temp;
end

end

