function [signal_data, data_legend, t] = createDataMatrix(raw_data, data_start, ...
    framerate, t_window, t_parameters)
% createDataMatrix cleans up raw imported data and returns key variables
%   Implements any raw_data parameters from "Ca_Pipeline_Main.m"
%   and outputs a new matrix, legend, and time vector for the imported data
% INPUTS:
%   - raw_data: cell array generated from readFile() function
%   - data_start: NUM parameter, [1ST ROW WITH F VALUES, 1ST COL WITH F VALUES]
%   - framerate: NUM, self-explanatory parameter
%   - t_constraint: true/false BOOLEAN, looking at data from specific time-window?
%   - t_parameters: CELL ARRAY, {unit, [start time-window, end time-window]}
%           - unit for window values: 's' (seconds) or 'f' (frame #)
%           - start and end time-windows: NUM (corresponding with above unit)         
% OUTPUTS:
%   - data: (M x N) array, where (M = F values @ frame in row M; 
%           N = all F values for cell in column N)
%   - cell_legend: cell array containing all non-flourescent value info 
%           from .xlsx (i.e. genotype, cell ID, cell number, cluster partitions)
%   - t: time vector based on sampling rate, start and end time parameters.
%           If t_constraint=false, t is calculated based on total number of
%           frames and sampling rate

% ~~~~~~~~~~~~~~~~~~~~~~~~~~~~CODE SECTION~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% CREATE DATA LEGEND
%   - cell_legend: cell array containing all non-flourescent value info 
%     from .xlsx (i.e. genotype, cell ID, cell number, cluster partitions)
data_legend = raw_data(1:data_start(1)-1,data_start(2):end); 
    
% CREATE DATA MATRIX (contains flourescence traces)
%   - data: (MxN) array, M=F values @ frame M;  N=full trace for cell #N
data = cell2mat(raw_data(data_start(1):end,data_start(2):end)); %cell2mat converts cell array to matrix

% IMPLEMENT DATA PARAMETERS
% Frequency
Fs=1/framerate; % Frequency is 1/framerate (should be 1/10hz)
% Cut data to fit time window/constraint
if t_window && t_parameters{1} == 's'
    data = data((t_parameters{2}(1,1)*framerate):(t_parameters{2}(1,2)*framerate), :);
    t_end = t_parameters{2}(1,2);
    disp('time window (s)= true')
elseif t_window && t_parameters{1} == 'f'
    data = data(t_parameters{2}(1,1):t_parameters{2}(1,2)*framerate, :);
    t_end = t_parameters{2}(1,2);
    disp('time window (frame #) = true')   
else
    t_end = (length(data(:,1)))*Fs;
    disp('time window = false')
end

% Deal with NaN values (some traces are shorter than others)
%   - finds shortest trace
%   - clips all traces to shortest trace length (removes data from end)
%   - redefines/modifies data matrix
min_len = size(data,1); % Setting temporary min length as longest trace
for i=1:size(data,2)    % For # of traces
    nonan_len = length(data(:,i))-sum(isnan(data(:,i))); % Length of trace
                                                         % excluding NaNs
    if nonan_len < min_len      % If current trace noNaN length < min_length
        min_len = nonan_len;    % New min_len is nonan_len
        warning(['Data contains NaN values. If there time_constraints '...
            '= false, traces may be different lengths. If time_'...
            'constraints =true, consider changing "time_end" var so '...
            'constraint window accomodates the minumum length trace: '...
             num2str(min_len) ' frames']);  
    end
end

% Create time vector for plotting and analysis
t = ([Fs:Fs:t_end]'); % time variable based on Fs
signal_data = cell(1, size(data,2));

for i=1:size(data,2)
    signal_data{i}(:,1) = data(:,i);
    signal_data{i}(:,2) = t;
end


end