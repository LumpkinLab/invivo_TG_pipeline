classdef pe_Plot < handle    
    % TO DO: 
    % property validations
    
    properties (SetObservable)
        % Data
        x_data              % X-axis vector (time)
        data                % Holds active data (data currently being used)
        original_data       % Stores data that was originally sent to this object
        baseline_data       % Stores all baseline values that are subtracted for normalization
        normalized_data     % Stores all normalized data
        smoothed_data       % Stores all smoothed data
        % Settings
        settings
        plot_settings       % stores any parameters for the figure plot
        baseline_settings   % Stores any dialogue box input from baseline parameter prompt
        % Other
        sampling_frequency  % Hz
        handles             % Figure handles
        num_cells           % Number of cells
        num_sweeps          % Number of sweeps
        num_samples         % Number of samples in x_data series
        active_sweep        % Sweep that is highlighted (active)
        active_cell         % Cell that is being plotted (active)
        
        
    end
    
    properties (Dependent, SetObservable)
        dyn_data           % Dynamic data (for plotting)
    end
    
    methods
        
        function obj = pe_Plot(varargin)
            % SET INPUT AS DATA PROPERTY
            data=varargin{1};

            % REFORMAT INPUT
            obj.x_data=round(data(:,1,1)', 4); %Grabbing x_data vector (x-axis) from input
            obj.data=data(:,:,2:end); % Removing x_data vector (:,:,1) from actual data
            obj.original_data = obj.data; % Adding data to original_data property so it can be retrieved later
            
            % SET SAMPLING FREQUENCY
            % Sampling frequency automatically calculated based off of mean difference between sample values in obj.x_data
            obj.sampling_frequency=mean(diff(obj.x_data)); 
                                
            % SET DEFAULT ACTIVE SWEEP & CELL
            obj.active_sweep=1;
            obj.active_cell=1;
             
            % ASSIGNING OBJECT PROPERTY VALUES  
            %   Plot settings
            obj.plot_settings.Y_label='F';          % Y axis units
            obj.plot_settings.figure_title='Stimulus-response traces'; % Figure title
            obj.plot_settings.axes=true;             % Auto-scaling axes?  
            %   Baseline settings     
            obj.baseline_settings.subtracted=false; % Plotting baseline-subtracted (normalized) data?
            obj.baseline_settings.got_all=false;    % Have all baseline values been calculated and stored?
            %   Other settings
            obj.settings.smoothed=false;            % Plotting smoothed data? 
            obj.settings.smoothed_span=0;           % Smoothing span (# frames)
            obj.settings.figure_clicked=false;      % For handle
            %   Data dimension properties
            obj.num_samples=size(obj.data,1);       % Length of trace
            obj.num_cells=size(obj.data,2);         % Number of cells 
            obj.num_sweeps=size(obj.data,3);        % Number of sweeps
           
            % Changes property settings if other variable arguments were included when calling object
            if nargin>1     
                for i=2:2:nargin
                    switch varargin{i}
                        case 'title'
                            obj.plot_settings.figure_title = varargin{i+1};
                            disp('Figure title set')
                        case 'axes'
                            if varargin{i+1}=='auto'
                                disp("Axes set to 'auto'")
                                obj.plot_settings.axes=1;
                            else
                                disp("Axes set to 'manual'")
                                obj.plot_settings.axes=0;
                            end
                        case 'baseline subtract'
                            if varargin{i+1}==1
                                obj.baseline_settings.subtracted=1;
                                disp("Data has been normalized to baseline. Without a 'baseline window' argument, baseline defaults to -5 to 0.1s.")
                            else
                                obj.baseline_settings.subtracted=0;
                                disp('Baseline has not been subtracted')
                            end
                        case 'baseline window'
                            if size(varargin{i+1})==[1,2]
                                disp(['Baseline window set: ' num2str(varargin{i+1}(1,1)) ' to ' num2str(varargin{i+1}(1,2)) 's'])
                                obj.baseline_settings.start=(varargin{i+1}(1,1)*1000);
                                obj.baseline_settings.end=(varargin{i+1}(1,2)*1000);
                            else
                                warning('Baseline window should be a 1x2 matrix: [start x_data (s), end x_data (s)]')
                            end
                        case 'framerate'
                            if varargin{i+1}>1
                                obj.sampling_frequency=1/varargin{i+1};
                            else
                                disp('Unlikely framerate: should be >1 (Hz).')
                            end
                        case 'sampling frequency'
                            if varargin{i+1}<1
                                obj.sampling_frequency=varargin{i+1};
                            else
                                disp('Unlikely sampling frequency: should be <1.')
                            end
                        otherwise
                            warning("Unknown 'pe_Plot' input argument. Check spelling or input argument options.")
                    end
                end
                    
            end
            
            % If sweep x_data-window is long enough, set default baseline to -5:-0.1s
            if obj.x_data(1)< -5 %
                obj.baseline_settings.start=-5;  
                obj.baseline_settings.end=-0.1; % Window stops here to account for manual stimuli that may have been applied early
            else
                warning('Trace lengths are too short for default baseline window (-5 to -0.1s). Right click on plot to change the baseline window.');
            end
            
            obj.fig_handles()
        end
        
        function fig_handles(obj, varargin)            
            % CREATE & CUSTOMIZE FIGURE
            obj.handles.figure=figure(); % Create handle for figure() function

            % SET FIGURE HANDLES
            set(obj.handles.figure,'Name',char(obj.plot_settings.figure_title)); 
            set(obj.handles.figure,'Numbertitle','off'); % Cut 'Figure #' before title
            hold on
             
            % SET AXES HANDLES
            xlabel('time (s)')
            ylabel(obj.plot_settings.Y_label)
            if obj.plot_settings.axes==true
                axis auto
            else
                % Set Y axis limits: the min and max F values from ALL cells
                floor=min(min(min(obj.data(:,:,:)))); 
                roof=max(max(max(obj.data(:,:,:))));
                y_dif=0.1*(roof-floor); % Difference between the floor and roof
                axis([obj.x_data(1) obj.x_data(end) floor-y_dif roof+y_dif])
            end     
            haxes=findobj(obj.handles.figure,'type','axes');
            obj.handles.axes=haxes;
               
            % SET DROPDOWN MENU HANDLES (right click on figure)
            obj.handles.drop_down.menu=uicontextmenu;
            obj.handles.drop_down.m1=uimenu(obj.handles.drop_down.menu,'Label','smooth by', 'Callback', @obj.dropdown_clicked); 
            obj.handles.drop_down.m2=uimenu(obj.handles.drop_down.menu,'Label','subtract baseline','Callback',@obj.dropdown_clicked); %*328 changing callback
            obj.handles.drop_down.m3=uimenu(obj.handles.drop_down.menu,'Label','change baseline window','Callback',@obj.dropdown_clicked);                        
            haxes.UIContextMenu=obj.handles.drop_down.menu;
            
            % PLOT SWEEPS
            obj.handles.all_sweeps=plot(obj.x_data,squeeze(obj.data(:,1,:)),'Color','#00A6EA','visible','on');
            obj.handles.active_sweep=plot(obj.x_data,obj.data(:,1,obj.active_sweep),'r');  % Plot the active sweep (in red)
 
            % ANNOTATE ACTIVE CELL
            obj.handles.cell_text=annotation(...
                'textbox',[0.45 1 0.2 0],...
                'FontSize', 22,...
                'LineStyle', 'none',...
                'String','Cell 1')
             
            % ADD LISTENERS
            addlistener(obj,'settings','PostSet',@obj.update_fig);
            addlistener(obj,'active_cell','PostSet',@obj.update_fig);
            addlistener(obj,'baseline_settings','PostSet',@obj.update_fig);
              
            % APP HANDLE
            setappdata(obj.handles.figure,'object',obj)
             
            % SET CALLBACKS
            set(obj.handles.figure,'keypressfcn',@obj.key_stroke);
            set(obj.handles.figure,'WindowButtonUPFcN',@obj.figure_clicked);
            set(obj.handles.figure,'WindowButtonDownFcn',@(src,ev)notify(obj,'mouse_click'))

        end
        
        function change_sweep(obj, next_sweep)
            % Changes active sweep and updates plot
            this_cell=obj.active_cell;
            obj.active_sweep=next_sweep;
            set(obj.handles.active_sweep,'YData',obj.data(:,this_cell,obj.active_sweep));
        end
                
        function get_baselines(obj)
            % Calculates baseline values for all traces then uses them to
            % normalize all traces
            [~, start_baseline] = find(obj.x_data<(obj.baseline_settings.start+1) & obj.x_data>(obj.baseline_settings.start-1));
            [~, end_baseline] = find(obj.x_data<(obj.baseline_settings.end+1) & obj.x_data>(obj.baseline_settings.end-1));
            temp_baseline_data=mean(obj.original_data(start_baseline:end_baseline,:,:),1);
            
            % Store baseline values in baseline_data property
            obj.baseline_data=repmat(temp_baseline_data,length(obj.data(:,:,1)),1);
            
            % Normalize traces to baseline and store in normalized_data property 
            obj.normalized_data=rdivide((obj.original_data-obj.baseline_data),obj.baseline_data);
            
            % This data has now been stored, so don't need to run this function again
            obj.baseline_settings.got_all=true;
        end
        
        function baseline_subtract(obj)
            % Updates whether or not baseline has been subtracted
            obj.baseline_settings.subtracted =~ obj.baseline_settings.subtracted;
        end
        
        function smooth_trace(obj, span)
            % Smooth the data using a moving average filter, with inputed span
            if span==0 
               obj.settings.smoothed=false;
               disp('Smoothing undone')
            elseif span>=3
               obj.settings.smoothed_span=span;
               obj.settings.smoothed=true; 
               disp(['Sweeps smoothed by: ' num2str(span) ' frames']);
            else
               warning('Span must be >=3 and an odd integer.')
               obj.settings.smoothed=false;
            end
        end    
        
        function dyn_data=get.dyn_data(obj)

            this_cell=obj.active_cell;
            
            % Was the baseline subtracted?
            if obj.baseline_settings.subtracted
                % Calculate baselines if haven't already
                if obj.baseline_settings.got_all==0
                    obj.get_baselines() 
                end
                dyn_data = obj.normalized_data;
            else
                dyn_data=obj.original_data;
            end
            
            % Have sweeps been smoothed?
            input=obj.settings.smoothed_span;
            if obj.settings.smoothed==true
                [dim1, dim2, dim3] = size(dyn_data);
                temp_data = zeros(dim1,dim2,dim3);
                for i=1:dim3
                    for j=1:dim2
                        temp_data(:,j,i)=smooth(dyn_data(:,j,i),input);
                    end
                end
                obj.smoothed_data=temp_data;
                dyn_data = temp_data;
            end
        end
    end
    
    %%%%%%%%%%%%%%%%%%%%%% Callbacks & other functions%%%%%%%%%%%%%%%%%%%%%%%%%
    
    methods (Access = private)
        
        function key_stroke(obj, src, ~)
            % Use the arrow keys to flip through cells and sweeps
            
            key_input=double(get(obj.handles.figure,'CurrentCharacter')); % Convert keystroke to input
            
            switch key_input
                case 29 % Right arrow will move to next cell
                    if obj.active_cell==obj.num_cells
                        obj.active_cell=1;
                    else
                        obj.active_cell=obj.active_cell+1;
                    end
                case 28 % Left arrow will return to previous cell
                    if obj.active_cell==1
                        obj.active_cell=obj.num_cells;
                    else
                        obj.active_cell=obj.active_cell-1;
                    end
                case 30 % Up arrow will highlight next sweep
                    if obj.active_sweep~=obj.num_sweeps
                        change_sweep(obj,obj.active_sweep+1);
                    else
                        disp('do nothing up')
                    end
                        
                case 31 % Down arrow will highlight previous sweep
                    if obj.active_sweep~=1
                        change_sweep(obj,obj.active_sweep-1);
                    else
                        disp('do nothing down')
                    end
                %- Add more cases here, can find case # by uncommenting:         
            end
        end
      
        function dropdown_clicked(obj, src, evt)
            % Update figure based on which dropdowndown item is clicked
            switch src.Label
                case 'smooth by' % Uses moving average filter, input the span
                    user_input = dlgPrompt('smooth by');
                    if user_input
                        obj.smooth_trace(user_input);
                        set(obj.handles.drop_down.m1,'label','undo smooth')
                    end
                case 'undo smooth'
                    obj.smooth_trace(0);
                    set(obj.handles.drop_down.m1,'label','smooth by')
                case 'subtract baseline'
                    % Will normalize data (subtract baseline from rest of sweep)
                    obj.baseline_subtract();
                    set(obj.handles.drop_down.m2,'label','undo subtract baseline')
                    disp('Sweeps normalized to baseline')
                case 'undo subtract baseline'
                    obj.baseline_subtract();
                    set(obj.handles.drop_down.m2,'label','subtract baseline')
                    disp('Normalization undone')
                case 'change baseline window'
                    disp('change baseline window')
                    % Clicking this menu item will prompt user for start & end x_data (s)
                    user_input = dlgPrompt('baseline window');
                    obj.baseline_settings.start = user_input(1,1);
                    obj.baseline_settings.end = user_input(1,2);   
                    disp(['Using manually inputed x_data-window: ' ...        
                        num2str(obj.baseline_settings.start) 's to '...
                        num2str(obj.baseline_settings.end) 's']);
                    obj.baseline_settings.got_all=false;
                    disp('baseline_settings.got_all reset to false. Re-submit subtract baseline request to refresh.')
                    if obj.baseline_settings.subtracted==1
                        set(obj.handles.drop_down.m2,'label','subtract baseline')
                        obj.baseline_settings.subtracted=false;
                    end
            end
        end
        
        function figure_clicked(obj,src, evt)
            % Update figure when it is clicked on
            obj.settings.figure_clicked=true;
            set(obj.handles.figure,'WindowButtonMotionFcN','')
        end
        
        function update_fig(obj, evt, ~)
            % Figure will update when listener callbacks occur
            this_cell=obj.active_cell;
            this_sweep=obj.active_sweep;
            
            switch evt.Name % Based on the which event was called     
                case {'settings', 'active_cell', 'baseline_settings'}
                    % When subsets of these properties are changed, the dynamic data and figure will be updated
                    
                    % Assign the dynamic data to data
                    obj.data=obj.dyn_data;
                    
                    % Change cell number annotation
                    obj.handles.cell_text.String=['Cell ' num2str(this_cell)];
                    
                    % Updating figure to show active cell sweeps
                    set(obj.handles.active_sweep,'YData',obj.data(:,this_cell,this_sweep));
                    for i=1:length(obj.handles.all_sweeps)
                        set(obj.handles.all_sweeps(i),'YData',squeeze(obj.data(:,this_cell,i)));
                    end
                    
                    
            end
            
            % Depending on whether the data has been normalized, the Y axis units will change
            if obj.baseline_settings.subtracted==true
                obj.plot_settings.Y_label = 'deltaF/F';
                obj.handles.axes.YLabel.String=obj.plot_settings.Y_label;
            else
                obj.plot_settings.Y_label = 'F';
                obj.handles.axes.YLabel.String=obj.plot_settings.Y_label;
            end
             
        end
        
    end
     
    events
        sweep_change      % When sweep is changed
        baseline_change   % When baseline is changed
        mouse_click       % When the figure is clicked on
    end    
    
end

