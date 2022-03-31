function [plotOutput, plotStats] = dose_response_subplot(inData,cluster, cluster2Plot,xValues, yTitle, xTitle, xTitleMod)
% This function takes the force-response matrix data from the
% dose_responseSort() function, sorts them based on cluster group, and
% plots them

    if size(cluster2Plot,1)==0
        warning('There are no cells in this cluster group.')
        return
    end

    num_Cells = size(cluster2Plot,1);   % Number of cells
    num_Figs = ceil(num_Cells/30);      % Number of figure windows (30 subplots/window)
    plot_Dims = zeros(num_Figs, 2);     % Plot dimensions
    figureCount = 1;                    % Current figure number
    sz = 35; c = linspace(1,10,4);      % Plot colors

    % Preallocate space for both vargOuts
    plotStats = zeros(5,2);             
    plotOutput = zeros(5,num_Cells); 

    % Number of figures based on num subplots
    for i=1:num_Figs
        plot_Dims(i,2)=5;
        if i==num_Figs
            plot_Dims(i,1)=ceil(rem(267,30)/5);
        else
           plot_Dims(i,1)=6; 
        end
    end

    figure;

    % Subplot tile settings
    t=tiledlayout(plot_Dims(figureCount,1),plot_Dims(figureCount,2));
    t.Title.String = ['Cluster ' cluster ' ' xTitle ' Force-Response ' xTitleMod ];
    t.Title.FontWeight = 'bold';
    t.Title.FontSize=18;
    tileCount = 1;

    for i=1:size(cluster2Plot, 1) 
        % If there are already 30 subplots in window, make new figure
        if mod(i-1,30)==0 && i~=1   
            figureCount=figureCount+1;
            figure; 
            t=tiledlayout(plot_Dims(figureCount,1), plot_Dims(figureCount,2));
            t.Title.String = ['Cluster ' cluster ' AUC Force-Response'];
            t.Title.FontWeight = 'bold';
            t.Title.FontSize=18;
            tileCount=1;
        end

        % then
        yData= inData(:,cluster2Plot(i));
        plotOutput(1,i)=cluster2Plot(i);
        plotOutput(2:5,i)=yData;

        nexttile(tileCount)

        scatter(xValues, yData, sz, c, 'filled');
        hold on;
        line(xValues, yData);
        title(['Cell #' num2str(cluster2Plot(i))])        
        if xValues(1,1)~=1
            xlabel('Force (mN)')
        else
            xlabel('Stim #')
        end
        ylabel(yTitle)
        tileCount=tileCount+1;
    end

    plotStats(:,1) = mean(plotOutput, 2);
    plotStats(:,2) = std(plotOutput,0,2)/sqrt(num_Cells);

    figure;
    hold on;

    for i=1:size(plotOutput, 2)
        plot(xValues, plotOutput(2:5,i), '-o', 'Color', '#8CC1DD');
    end

    errorbar(xValues, plotStats(2:5, 1), plotStats(2:5, 2), 'Color', '#FF8C00', 'LineWidth', 2); 
    plot(xValues, plotStats(2:5, 1), 'LineWidth',2, 'Color', '#FFA600');
    title(['Cluster ' cluster ' ' xTitle ' Force-Response ' xTitleMod], 'FontSize', 18, 'FontWeight', 'bold'); 
    ylabel(yTitle)

    if xValues(1,1)~=1  % If data is sorted by force:
        xlim([80 450])  
        xlabel('Force (mN)')
    else % If data sorted by stimulus number
        xticks([0, 1, 2, 3, 4])
        xticklabels({'0','2 (290)','3 (90)','4 (195)','5 (440)'}) 
        xlabel('Stimulus number')
    end
            

end

