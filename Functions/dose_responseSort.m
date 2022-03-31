function [out_dataSorted,out_forceSteps] = dose_responseSort(in_sweeps, in_sweepsCol,in_row, in_forceSteps,in_sortByForce)
% Sorts force-response data from sweeps{} array by force level
%   in_sweeps: sweeps{} array with all data
%   in_sweepsCol: column of interest from sweeps{} (7=AUC, 9=peaks)
%   in_forceSteps: 1x5 matrix with force steps listed
%
[forceSteps, forceSteps_index] = sort(in_forceSteps); 

temp_dataSorted = zeros(5,size(in_sweeps{2,in_sweepsCol},2));

    for i=1:5
        for j=1:size(in_sweeps{2,in_sweepsCol},2)
            temp_dataSorted(i,j)=in_sweeps{i+1,in_sweepsCol}(in_row,j);
        end
    end

    if in_sortByForce==1
        out_dataSorted = temp_dataSorted(forceSteps_index,:);
        out_forceSteps = forceSteps;
    else
        out_dataSorted = temp_dataSorted;
        out_forceSteps = in_forceSteps;
    end

end

