function [detr_data] = detrendData(data, poly_num)
% Detrends inputed data based on the polynomial order input

num_cells = size(data,2);       % number of cels
detr_data = cell(1,num_cells);  % preallocate space for vargOut
t = data{1}(:,2);               % time vector

% Detrend each trace using the polynomial input vargIn
for i=1:num_cells
    this_cell = data{i}(:,1);
    detr_data{i}(:,1) = detrend(this_cell(:,1),poly_num)+mean(this_cell(:,1));
    detr_data{i}(:,2) = t;
end

