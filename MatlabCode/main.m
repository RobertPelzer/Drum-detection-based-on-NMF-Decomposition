%%  -----------------------------------------------------------------------
%   -----------------------------  MAIN  ----------------------------------
%   -----------------------------------------------------------------------
%%  --------------------------- Initializing ------------------------------
%   ------------------------------- and -----------------------------------
%   -------------------------- set parameters -----------------------------
% initialize program timer
tic;

%%  --- File and Ground Truth parameter
% metadata from the filename structure
p.metadataPattern = '[\w_\d]+#(?<instrument>\w+)#(?<type>\w+).\w+|[\w_\d]+#(?<instrument>\w+).\w+';
p.fileRumpPattern = '(?<testItem>[\w\d_]+)#(?<type>[\w#]+).\w+';
p.subsetNumPattern = '(?<subSet>\w+)_(?<number>\d+)';

% get platform specific file separator
p.fsep = filesep();

% input directorie names
p.audioDirWAV = ['audio',p.fsep];
p.annotDirXML = ['annotation_xml',p.fsep];

% search suffix
p.suffixWAV = '*.wav';
p.suffixXML = '*.xml';

% get sub database with perfectly isolated mix samples
p.fileListWAV = dir([p.audioDirWAV,p.suffixWAV]);
p.fileListXML = dir([p.annotDirXML,p.suffixXML]);

% convert filenames to cells
p.cellFilenamesWAV = arrayfun(@(x) x.name, p.fileListWAV,'UniformOutput', false);
p.cellFilenamesXML = arrayfun(@(x) x.name, p.fileListXML,'UniformOutput', false);

% track types e.g ['MIX,'KD','SD','HH']
p.trackTypes = {'MIX','KD','SD','HH'};
% number of track types
p.numTrackTypes = length(p.trackTypes);
% instruments e.g ['KD','SD','HH']
p.instruments = p.trackTypes(2:end);
% number of Instruments, e.g. #['KD','SD','HH'] = 3
p.numInstruments = length(p.instruments);

% number of files to use in calculation,
% depends on files in annotaion_xml and
% starts with file number 1 always
p.numItems = 95;

% number of training sets
p.numTrainSets = length(p.fileListWAV) / p.numTrackTypes;

%%  --- train set initialization
% initialize average training set vectors
p.trainSetMean.KD = [];
p.trainSetMean.SD = [];
p.trainSetMean.HH = [];

% initialize train set catalog
p.trainSetCatalog.KD = [];
p.trainSetCatalog.SD = [];
p.trainSetCatalog.HH = [];

% train set Modi:   0 = every drum mix gets the according training set
%                   1 = specific train set name in p.trainSet
%                   2 = mean value of all train sets within a specific range
p.trainSetMode = 2;

% train set mode 1: train set name
p.trainSet = './audio/WaveDrum02_56#';

% train set mode 2: set train set start and end file number from
% the catalog
p.trainSetStart = 1;
p.trainSetEnd = 95;

%%  --- NMF and onset detection parameters
% frame length [samples]
p.blockSize = 2048;

% hop size [samples]
p.hopSize = 512;

% number of nmf iterations 
p.nmfIterations = 30;

% parameters for semi-adaptive NMF
p.adaptDegree = 1*ones(1,p.numInstruments);
p.adaptPower = 4*ones(1,p.numInstruments);

% this can be used to switch between
% Itakura-Saito divergence -> beta = 0
% Kullback-Leibler divergence -> beta = 1
% Euclidean distance -> beta = 2
p.beta = 1;

% number of Frames in Onset Dectection
% they have to be above threshhold T in succession
p.nNeighbour = 3;


%%  --- F Score initialization
% f score tolerance in miliseconds
p.fScoreTolerance = 0.09;

% initialize avarage f scroe vectors
avgFScore.KD = 0;
avgFScore.SD = 0;
avgFScore.HH = 0;

% initialize avarage f scroe counters
avgFScore.counter.KD = 0;
avgFScore.counter.SD = 0;
avgFScore.counter.HH = 0;

%%  --- plot parameter
p.plot.itemNumber = 2;
p.plot.onsets = false;
p.plot.nmf = false;
p.plot.mix = false;
p.plot.novCurve = false;
p.plot.all = true;

% save plots to png?
p.plot.save = true;

%%  --------------------------- Import data -------------------------------
%   ---------------------- and initialize F Score container ---------------
% imports ground truth of annotated files in allItems
[ allItems ] = import_FileNamesAndGT(p);

% initialize avarage f scroe vectors
avgFScore.KD = 0;
avgFScore.SD = 0;
avgFScore.HH = 0;

% initialize avarage f scroe counters
avgFScore.counter.KD = 0;
avgFScore.counter.SD = 0;
avgFScore.counter.HH = 0;


%%  ------------------------------- LOOP ----------------------------------
%   -----------------------------Test-Files -------------------------------
% Calculates nmf, onsets and F Score for all Test Data
for n = 1:p.numItems
    clc;
    fprintf('Testsetnumber:\t%d/%d\nTestsetname: %s\n',n,p.numItems,allItems{n}.testItem);

    % load ground truth into current item
    currentItem = allItems{n};

    % find matching annotations via the base name
    indexWAV = find(~cellfun(@isempty,strfind(p.cellFilenamesWAV,allItems{n}.testItem)));

    for h = 1:length(indexWAV)
        % get current filename
        currentAudioname = char(p.cellFilenamesWAV{indexWAV(h)});

        % read the audiofile
        [sig,currentItem.fs] = audioread([p.audioDirWAV,currentAudioname]);

        % interpret metadata
        audioMeta = regexpi(currentAudioname,p.metadataPattern,'names');

        % and store the signals accordingly
        sig = sig(:,1);
        currentItem.(['audio_',[audioMeta.instrument]]) = sig;

        % generate average train set with p.trainSetStart and p.trainSetEnd
        % when p.trainSetMode = 2
        if(~strcmp(audioMeta.instrument,'MIX'))
            if(isempty(p.trainSetMean.(audioMeta.instrument)) && (p.trainSetMode == 2))
                [p.trainSetMean.(audioMeta.instrument),p.trainSetCatalog.(audioMeta.instrument)] = get_trainSetMean(audioMeta.instrument, p);
            end
        end
    end

    % nmfV of current item
    currentItem = comp_nmf(currentItem, p);
    % onsets of current item
    currentItem = comp_onsets(currentItem, p);
    % save calculated onsets of current item into allItems
    allItems{n}.CUS_onsets = currentItem.CUS_onsets;
    % F Scores of current item
    currentItem = get_fScore(currentItem,p);
    % save F Score of current item into allItems
    allItems{n}.F = currentItem.F;

    % plots of current item, if plotOnsets = true
    if(p.plot.itemNumber == n)
        get_plots(currentItem, p);
    end
end

%%  ----------------------------- Verage F Score --------------------------
% calculate the average FScore of all items
for n = 1:p.numItems
    for i = 2:length(p.trackTypes)
        elem = p.trackTypes{i};
        if(isnan(allItems{n}.F.(elem)) == false)
            avgFScore.(elem) = avgFScore.(elem) + allItems{n}.F.(elem);
            avgFScore.counter.(elem) = avgFScore.counter.(elem) + 1;
        end
    end
end

avgFScore.KD = avgFScore.KD / avgFScore.counter.KD;
avgFScore.SD = avgFScore.SD / avgFScore.counter.SD;
avgFScore.HH = avgFScore.HH / avgFScore.counter.HH;

%%  ---------------------------- Print text -------------------------------
% print result to command line
fprintf('\naverage F-Score KD: %1.2f\n', avgFScore.KD);
fprintf('average F-Score SD: %1.2f\n', avgFScore.SD);
fprintf('average F-Score HH: %1.2f\n', avgFScore.HH);

% print needed time to command line
processTime = toc;
fprintf('\nTime needed: %d minutes and %2.1f seconds\n',floor(processTime/60),rem(processTime,60));
