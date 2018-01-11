function [ annotations ] = get_XMLAnnotations( currentFilename, p )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: get_XMLAnnotations
%
% function reads the annotation xml file of the current item
%
% Input:
%   currentFilename: audio file name of the current item
%   p: parameter container
% 
% Output:
%   annotations.instrName: instrument short name
%   annotations.instrCode: instrument short code
%   annotations.pitch: the MIDI pitch
%   annotations.onset: onset in seconds
%   annotations.offset: offset in seconds
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% xml file name
xmlFile = [p.annotDirXML,currentFilename];
% read xml file
dom = xmlread(xmlFile);

% get events in file (entries)
events = dom.getElementsByTagName('event');
% get number of entries
numEvents = events.getLength-1;

% initialize xml variables
instrName = [];
pitch = [];
onset = [];
offset = [];

% loop over entries in xml file
for p = 1:numEvents
  instrName{p} = char(events.item(p-1).getElementsByTagName('instrument').item(0).getTextContent);
  pitch(p) = str2num(events.item(p-1).getElementsByTagName('pitch').item(0).getTextContent);
  onset(p) = str2num(events.item(p-1).getElementsByTagName('onsetSec').item(0).getTextContent);
  offset(p) = str2num(events.item(p-1).getElementsByTagName('offsetSec').item(0).getTextContent);
end

% prepare output struct
annotations.instrName = [];
annotations.pitch = [];
annotations.onset = [];
annotations.offset = [];

% stuff everything into output container
annotations.instrName = instrName;
annotations.pitch = pitch;
annotations.onset = onset;
annotations.offset = offset;

end

