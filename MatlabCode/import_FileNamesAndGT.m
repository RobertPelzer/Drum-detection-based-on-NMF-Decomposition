function [ allItems ] = import_FileNamesAndGT(p)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: import_FileNamesAndGT
%
% Load Groundtruth annotated Data by Dittmar
% go through all audio files and find the corresponding files and 
% annotations
%
% Input:
%   p: parameter container
%
% Output:
%   allItems: container with names and annotations of each test set
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

allItems = [];

for k = 1:p.numItems
        
    % get filename
    currentFilename = char(p.cellFilenamesXML{k});

    % show progress
    disp([num2str(k), ' : ', currentFilename]);

    % and interpret the metadata
    currentMeta = regexpi(currentFilename,p.fileRumpPattern,'names');
    currentInd = regexpi(currentMeta.testItem,p.subsetNumPattern,'names');

    % initialize metadata of this item
    currentItem = [];
    currentItem.testItem = currentMeta.testItem;
    currentItem.subSet = currentInd.subSet;
    currentItem.number = str2num(currentInd.number);

    % get all onset annotations and store them
    currentItem.('GT_onsets') = get_XMLAnnotations(currentFilename,p);
    
    % split mix to TrackTypes
    for N = 1:p.numInstruments
        IndexN = find(~cellfun(@isempty,strfind(currentItem.('GT_onsets').instrName,p.instruments{N})));
        currentItem.('GT_onsets').(p.instruments{N}) = currentItem.('GT_onsets').onset(IndexN);
    end

    % append to internal set
    allItems{end+1} = currentItem;    

end