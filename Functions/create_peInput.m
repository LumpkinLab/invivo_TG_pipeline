function [pe_results] = create_peInput(input_data, timestamps, input_window, framerate)
% Reformats input_data data to make compatible with pe_Plot class (object) handle
%   Splits up full traces into peri-event sweeps. Each sweep contains the
%   flourescence values within the given time-window (-window through +window) 
%   surrounding a stimulus (time-stamp or stamp is time=0)

    x_data = [-input_window:(1/framerate):input_window]; % Creating time vector
    window_length = framerate*input_window; % Window length in one direction (pre or post-time-stamp)
    full_window_length = window_length*2+1;     % Full window length
    % Preallocate space for results
    temp_results = zeros(full_window_length,size(input_data,2),size(timestamps,2)+1); 
        
    % For each trace
    for i=1:size(input_data,2)
        
        % Assign x_data
        temp_results(:,i,1)=x_data;

        % For each timestamp
        for j=1:size(timestamps,2)
            [~, idx]=min(abs(timestamps(j)-input_data{i}(:,2)));
            neg_window=idx-window_length;
            pos_window=idx+window_length;
            temp_results(:,i,j+1)=input_data{i}(neg_window:pos_window,1);
        end
        
    end

    pe_results = temp_results;
            
end