function [user_input] = dlgPrompt(context)
%UNTITLED7 Summary of this function goes here
%   Detailed explanation goes here

switch context
    case 'baseline window'
        prompt1 = sprintf(' Already pre-set to (-5s to 0.1s).\n Change to:\n\n Baseline start (s):');
        prompt_full = {prompt1, 'Baseline end (s):'};
        dlgtitle = 'Baseline window';
        definput = {'-5','-0.1'};
        dims = [1 40];
        temp_input=inputdlg(prompt_full,dlgtitle,dims,definput);
        
        temp_outputArg(1,1) = str2double(temp_input{1});
        temp_outputArg(1,2) = str2double(temp_input{2});
        
        user_input = temp_outputArg;
    case 'smooth by'
        prompt = {'Smooth data by span of __ frames:'};
        dlgtitle = 'Smooth span';
        definput = {'3'};
        dims = [1 40];
        temp_input=inputdlg(prompt,dlgtitle,dims,definput);
        
        user_input = str2double(temp_input);

end
        


end

