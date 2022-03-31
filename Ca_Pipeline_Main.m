%% OVERVIEW
%
% 1. Imports raw AOI traces from .xlsx file into "data" (matrix)
%       - readFile() function outputs raw data into "raw_data" matrix
% 2. Uses customized input parameters to reformat raw data
%       - inputs: raw_data, sampling framerate, time window of interest
%       - outputs: data (data) and time vector (t) within specified
%       parameters. Also checks and corrects for NaN values.
% 3. Detrends all time series from "data" array
%       - detrendData() function outputs traces that have been detrended
%       with the specified (N) order polynomial. Uses Matlab's "detrend()"
% 4. Outputs an array containing indices for each hierarchal cluster group
%       - outputs: "cluster_index" array, where each array column {1,col}
%       contains indices for a separate cluster group
% ...5, 6, ...
%

%% 0. SETUP ENVIRONMENT
% Adding general path and figure settings for pipeline

% SAVE/LOCATE program filepath
% This will locate the path that this script is in and save as "path" var
p = fileparts(which('Ca_Pipeline_Main.m'));

% Alternatively, you can write the path manually below
% p = '/Users/...';
                                  
% Set figure window style and clear workspace
addpath(genpath(p)); 
set(0,'DefaultFigureWindowStyle','normal');
close all;
clear all; 

%% 1. IMPORT .xlsx FILE (containing raw trace data)
% Call readFile function and select raw data file (must be .xls)
raw_data = readFile();

%% 2. TRACE DETAILS (change these before running)
% Before processing the traces, there are some details that will help this
% program read them. This code block will separate the raw traces from
% any text or other information that came from the excel or csv file.

%~~~~~~~~~~~~~~~~~~~~~ EDIT THE VARIABLES BELOW ~~~~~~~~~~~~~~~~~~~~~~~~~ 
% 2A. RAW DATA START/END
% Open and refer to the "raw_data" variable from your workspace:
start_row = 10;     % The first row with raw F values
start_col = 2;      % The first column with raw F values

% 2B. SAMPLE FRAMERATE
framerate = 10;     % Hz 
                           
% 2C. TIME WINDOW
t_window = true; % Analyzing the whole trace (false) or only portion of it (true)?
    % E.g. the full traces we analyzed contained F responses to both pressure & brush stimuli. 
    % For smoother detrending, we divided each trace into a  "pressure time-window" and a "brush 
    % time-window" to process and analyze separately.
    
    % If t_window=true, change the following. Otherwise leave it as is (it will be ignored)
    t_unit = 's';       % Will you be specifying the window in seconds ('s') or by frame number (f)
    start_window = 0.1; % At what time or frame does your time window start?
    end_window = 350;   % When does it end?
    % (Note: window start cannot be 0, because first sample is taken at 0.1s or frame 1)
%~~~~~~~~~~~~~~~~~~~~~~~~~~~ END ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Condensing parameters:
data_start = [start_row, start_col]; 
t_parameters = {t_unit,[start_window, end_window]}; 

% This function will filter the raw_data through the parameters:
[data, cell_legend, t] = createDataMatrix(raw_data, data_start,...
    framerate, t_window, t_parameters);

%Clear extra variables from workspace
clear start_row start_col t_unit start_window end_window t_window; 

%% 3. Detrend data
% Detrend traces with an n order polynomial

%~~~~~~~~~~~~~~~~~~~~~~~~~~ EDIT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
detrend_order = 2; % Polynomial order to detrend with 
%~~~~~~~~~~~~~~~~~~~~~~~~~~~ END ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Detrend function:
data_detrend = detrendData(data, detrend_order);


%% 4. Create index with cells grouped by hierarchal cluster
% Scans through the hierarchal levels in 'cell_legend{}'and outputs the array
%   'cluster_index{}' which indexes which cluster group each cell is in.
%   Used for visualizing & exporting data according to cluster group later.
%   The values in this array correspond to the column# for each cell or
%   trace
%   *(Note: This code is specifically formatted to the (Moayedi et al.,2022)
%   clustering method, which uses a 2-level hierarchal clustering system.
%   All 1st level cluster groups can be condensed into their 1st level
%   cluster groups except for Cluster 1, which is divided into two subgroups
%   based on their 2nd hierarchal level.)

%~~~~~~~~~~~~~~~~~~~~~~~~~~ EDIT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Refer to cell_legend{} variable in workspace:
level1_row = 6; %Row with 1st hierarchal level values
level2_row = 7; %Row with 2nd hierarchal level values
%~~~~~~~~~~~~~~~~~~~~~~~~~~~ END ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Flattening cluster info into 1-D matrix
cl1 = cell_legend(level1_row, :); 
cl2 = cell_legend(level2_row, :);
cl_mat(1,:) = cell2mat(cl1);
cl_mat(2,:) = cell2mat(cl2);

% Assigning each cluster group its own array cell in cluster_index{}
cluster_index{1} = find(cl_mat(1,:)==1 & ... % - cluster_index{1} = Cluster 1_1&2 
    (cl_mat(2,:)==1 | cl_mat(2,:)==2))';
cluster_index{2} = find(cl_mat(1,:)==1 & ... % - cluster_index{2} = Cluster 1_3&4
    (cl_mat(2,:)==3 | cl_mat(2,:)==4))';
cluster_index{3} = find(cl_mat(1,:)==2)';    % - cluster_index{3} = Cluster 2
cluster_index{4} = find(cl_mat(1,:)==3)';    % - cluster_index{4} = Cluster 3
cluster_index{5} = find(cl_mat(1,:)==4)';    % - cluster_index{5} = Cluster 4

clear cl1 cl2 cl_mat level1_row level2_row;


%% 4. Save current data to a file

% Enter name of file to save as
filename = strcat('full_trace_data','.mat');

% Enter all workspace variables you want to save
save(filename,'data','data_detrend','detrend_order', 'cell_legend','framerate', 'cluster_index');

%% 4. Prepping for peri-event plot
% Define timestamps and create matrix to later input to PE sweepset

timestamps = [60:60:355]; %Time stamps for pressure data (starting at 60ss
                      % 1 stim every 60 seconds, up until 355s)
sweep_window = 40; %(seconds) How long should one side of your stim-response
                   % window be? e.g. 40: sweeps will include data from -40s
                   % to +40s surrounding each stimulus time-stamp

% For running through pe_Plot handle
[sweeps_plot_input] = create_peInput(data_detrend, timestamps, sweep_window, framerate);



%% 5. Create peri-event plot

sweeps_plot=pe_Plot(sweeps_plot_input,'axes','auto');


%% 6. Create sweeps{} cell array to hold all analyzed data for all cells

% Running through some settings so that the data we want is populated
% within the peri-event object
sweeps_plot.baseline_settings.subtracted=true;
sweeps_plot.settings.smoothed_span=3;
sweeps_plot.settings.smoothed=true; 


%Column legend for cell array data
sweeps_legend = {'x','detrended','baselines','normalized','smoothed'};
% sweep_colLegend = {'x','detrended','baselines','normalized','smoothed','max peak', 'steady-state'};
% - col 1: sweep time data
% - col 2: original F values (detrended)
% - col 3: baseline values
% - col 4: normalized sweeps (baseline subtracted)
% - col 5: smoothed normalized sweeps
% - col 6: max peak values
% - col 7: steady-state values

%Creating cell array to store all peri-event sweep data
sweeps = {};

%Assigning column legend to first row
for i = 1:length(sweeps_legend)
    sweeps{1,i}=sweeps_legend{i};
end    
    
for i = 1:size(sweeps_plot.data,3) %For number of sweeps 
    sweeps{i+1,1}=sweeps_plot.x_data(1,:); %time window/sweep
    sweeps{i+1,2}=sweeps_plot.original_data(:,:,i); %original detrended sweep
    sweeps{i+1,3}=sweeps_plot.baseline_data(:,:,i); %baseline data
    sweeps{i+1,4}=sweeps_plot.normalized_data(:,:,i); %normalized data
    sweeps{i+1,5}=sweeps_plot.smoothed_data(:,:,i); %normalized data      
end






%% 7. MAX PEAK vs. STEADY-STATE PEAK ANALYSIS
% Analysis of max peak and steady-state ndF/F sweep values in "sweeps"
% variable

% Sweeps output is a 3xN matrix
%   - N: number of cells
%   - Row 1: Max positive peak value
%   - Row 2: Max negative peak value
%   - 0 or 1, where 0 indicates a negative going peak, 1 indicates a
%   positive going peak (taken from absolute neg or pos peak values)

x=sweeps{2,1};

%~~~~~~~~~~~~~~~~~~~~~~~~~~ EDIT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% Define pre/peri/post and pre-post ranges
% Values are in seconds
indices_pre = (x>=-5) & (x<=0);         % pre-stimulus window (-5 to 0s)
indices_peri = (x>=0) & (x<=10);        % peri-stimulus window (0 to 10s)
indices_post = (x>=10) & (x<=20);       % post-stimulus window (10 to 20s)

indices_maxPeak = (x>=0) & (x<=3);      % window to find maxpeak values in
indices_ss = (x>=8) & (x<=10);          % window to calculate steady-state values from

% Which cell array column has the smoothed data that you want to analyze?
smoothed_col = 5;

% Which new cell array columns are you putting the results into?
maxpeak_col = 6;
steadystate_col = 7;

% Number of sweeps analyzing (num sweeps in sweeps{} array)
num_sweeps = 5;
%~~~~~~~~~~~~~~~~~~~~~~~~~~~ END ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

% Preallocate space for peak data in sweeps{} array

sweeps{1,maxpeak_col}='MaxPeak';
for i=1:num_sweeps
    sweeps{i+1,maxpeak_col}=zeros(3,size(sweeps{2,smoothed_col},2));
end

% FIND MAXPEAK VALUE FOR EVERY SWEEP & EVERY CELL
%   Using smoothed, detrended & normalized sweep traces from sweeps{} array,
%   find the maximum difference from baseline that occurs in first 3 seconds
%   after stimulus onset

for i=1:size(sweeps{2,smoothed_col},2) %For each cell

    % PREALLOCATE SPACE FOR MATRIX WITH ALL Y DATA ('Y')
    % Where y is 801x5 matrix, cols are individual sweeps for that cell
    output = zeros(size(sweeps{2,smoothed_col},1),num_sweeps);

% Pull traces from sweeps array for analysis
  

    for j=1:num_sweeps %For each sweep
        output(:,j) = sweeps{j+1,smoothed_col}(:,i); 
    % FIND MAX POSITIVE PEAK (maximum positive change from baseline) 
    % maxPeak_positive: Max positive peak (from normalized sweep trace)
    % maxPeak_positive_index: Max positive peak index (frame # in peri-stimulus window)
    % Note: Final maxPeak_positive_index should not be <401 (stim onset)
        [maxPeak_pos, maxPeak_pos_index] = max(output(indices_maxPeak,j)); %Time window is first 3 seconds of peri-stimulus time
        maxPeak_pos_index = maxPeak_pos_index+find(indices_peri,1)-1; %Peak index correction (adding pre-stimulus time to re-orient index within full sweep trace

    % FIND MAX NEGATIVE PEAK (max negative change from baseline)
    % eg_pkmax: max peak normalized value
    % eg_pkindex: max peak index (frame in time)
    % Note: eg_pkindex should not be <401 (stim onset)  
        [maxPeak_neg, maxPeak_neg_index] = min(output(indices_maxPeak,j));
        maxPeak_neg_index = maxPeak_neg_index+400;


    % COMPARE MAX and MIN peaks & PLOT peak w/largest ABSOLUTE VALUE
        if abs(maxPeak_neg)>abs(maxPeak_pos)
            neg_going = 1; % negative going?=TRUE
            sweeps{j+1,maxpeak_col}(1,i) = maxPeak_neg;
            sweeps{j+1,maxpeak_col}(2,i) = maxPeak_neg_index;
            sweeps{j+1,maxpeak_col}(3,i) = x(maxPeak_neg_index);
        else 
            neg_going = 0; % negative going?=FALSE
            sweeps{j+1,maxpeak_col}(1,i) = maxPeak_pos;
            sweeps{j+1,maxpeak_col}(2,i) = maxPeak_pos_index;
            sweeps{j+1,maxpeak_col}(3,i) = x(maxPeak_pos_index);
        end
                
    end
end


% FIND STEADY-STATE VALUES FOR ALL CELLS
%   Using the smoothed traces from the sweeps{} array, calculate mean
%   'steady-state' value using steady-state indices

% Preallocate space for ss data in sweeps{} array
sweeps{1,steadystate_col}='Steady-state';
for i=1:num_sweeps
    sweeps{i+1,steadystate_col}=zeros(1,size(sweeps{2,smoothed_col},2));
end

for i=1:size(sweeps{2,smoothed_col},2) % For number of cells (based on # smoothed data traces)
    % Preallocate space for y matrix
    output = zeros(size(sweeps{2,smoothed_col},1),5);

    % Take the smoothed trace from sweeps array for analysis 
    for j=1:num_sweeps
        output(:,j) = sweeps{j+1,smoothed_col}(:,i); 
    
        % Find mean trace value from steady-state window indices
        temp_steadystate = mean(output(indices_ss,j));

        % Add to sweeps array
        sweeps{j+1,steadystate_col}(1,i) = temp_steadystate;
    end
    
end

    
%% 8. POPULATE INPUT MATRIX FOR FORCE-RESPONSE PLOTS
% For generating indvidual force-response subplots for each cell in cluster
% using sweeps{} array input

set(0,'DefaultFigureWindowStyle','docked') % Dock your figures for this code block

% SET ANALYSIS PARAMETERS
%~~~~~~~~~~~~~~~~~~~~~~~~~~ EDIT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
% 8A. Which values are you analyzing? Input one of the following:
data2analyze = 'peaks';     % 'peaks' or 'steady-state'

% 8B. Sort data by:
sortedBy = 1;               % stimulus order (0) or force (1)

% 8C. Define the force steps used
forceSteps = [130, 290, 90, 195, 440]; %force steps (mN) in order given
%~~~~~~~~~~~~~~~~~~~~~~~~~~~ END ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

switch data2analyze
    case 'peaks'
        sweeps_col = 6; %pulling data from sweeps{_,9} which contains peak values
        dataRow = 1;
    case 'steady-state'
        sweeps_col = 7; %pulling data from sweeps{_,1-} which contains ss values
        dataRow = 1;
    otherwise
        warning('Invalid input, should be peaks or steady-state')
end

% GRAB DATA FROM SWEEPS{} and RUN THROUGH dose_responseSort FUNCTION
% Outputs:
%   sweeps_Sorted: (M x N) matrix, where
%       M=force-response data in order of force step strength
%       N=cell# in corresponding column
%   forceSteps_Sorted: force steps in order of strength

[sweeps_Sorted, forceSteps_SortedAs] = dose_responseSort(sweeps, sweeps_col, dataRow, forceSteps, sortedBy);

if sortedBy == 1    
    sweeps_Sorted(2,:) = [];
elseif sortedBy == 0
    sweeps_Sorted(1,:) = [];
else
    warning('Check sortedBy value.')
end

%% 9. PLOT FORCE RESPONSE DATA
% For generating indvidual force-response subplots for each cell in cluster
% using sweeps{} array input

% Enter the name of the cluster group you want to plot (refer to the switch case below)
%~~~~~~~~~~~~~~~~~~~~~~~~~~ EDIT ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
cluster = '1-3&4';
%~~~~~~~~~~~~~~~~~~~~~~~~~~~ END ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

error = 0;

switch cluster
    case '1-1&2'
        cluster2Plot = cluster_index{1};
    case '1-3&4'
        cluster2Plot = cluster_index{2};
    case '2'
        cluster2Plot = cluster_index{3};
    case '3'
        cluster2Plot = cluster_index{4};
    case '4'
        cluster2Plot = cluster_index{5};
    otherwise 
        warning('Invalid cluster name.')
        error = 1;
end

if sortedBy==1
    forceSteps_Sorted = [90,195,290,440];
    xTitleMod = '';
elseif sortedBy==0
    forceSteps_Sorted = [1:4];
    disp('ahhh')
    xTitleMod = '(by stimulus number)';
else
    warning ('Error in sortedBy');
end


if error~=1
    [plotOutput, plotStats] = dose_response_subplot(sweeps_Sorted,cluster,cluster2Plot,forceSteps_Sorted, 'dFF', data2analyze, xTitleMod);
else
    disp('Check cluster name and try again.')
end

%% 10. Calculate linear fit & R^2 for all force-response (peak) curves in cluster

plotFit = {};

for i=1:size(plotOutput,2)
    y = plotOutput(2:5,i);
%     [p,S,mu] = polyfit(forceSteps_Sorted,y,1);
    [p,S] = polyfit(forceSteps_Sorted,y,1);
        plotFit{1,i}=p;
        plotFit{2,i}=S;
    [yfit, delta] = polyval(p,forceSteps_Sorted, S);
        plotFit{4,i}=yfit;
        plotFit{5,i}=delta;
    yresid = y - yfit';
    SSresid = sum(yresid.^2);
    SStotal = (length(y)-1) * var(y);
    rsq = 1 - SSresid/SStotal;
        plotFit{7,i}= yresid;
        plotFit{8,i}= SSresid;    
        plotFit{9,i}= SStotal;
        plotFit{10,i}= rsq;
        plotFit{11,i}= mean(rsq);
end

dose_response_linearFit(sweeps_Sorted,cluster,cluster2Plot,forceSteps_Sorted, plotFit,'dFF', data2analyze, xTitleMod);
    
