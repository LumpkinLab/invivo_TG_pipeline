function [raw_xls_data] = readFile()
%Reads selected .xlsx raw trace data file
%   User selects input file
%   Outputs raw_data variable
    [fileName, pathName] = uigetfile('*.xlsx');
    [~,~,raw] = xlsread(fullfile(pathName,fileName));
    raw_xls_data = raw;
end   

