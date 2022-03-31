function dose_response_linearFit(inData,cluster, cluster2Plot,xValues,in_plotFit,yTitle, xTitle, xTitleMod)
%UNTITLED5 Summary of this function goes here
%   inData: sweeps_Sorted matrix
%   cluster2Plot: cluster_hits{clusterCol}, index with cluster hits for
%       cluster of interest
%   xValues: forceSteps_Sorted
%   yTitle: y-axis title

[num_Cells] = size(cluster2Plot,1);
[num_Figs] = ceil(num_Cells/30);

[sz] = 35;
% [c] = linspace(1,10,5); %*130 removed
[c] = linspace(1,10,4); %*130 removed

[plot_Dims] = zeros(num_Figs, 2);
for i=1:num_Figs
    plot_Dims(i,2)=5;
    if i==num_Figs
        plot_Dims(i,1)=ceil(rem(267,30)/5);
    else
       plot_Dims(i,1)=6; 
    end
end

% plotStats = zeros(6,2); %*130 removed
plotStats = zeros(5,2); %*130 removed
[figureCount] = 1;

figure;
t=tiledlayout(plot_Dims(figureCount,1), plot_Dims(figureCount,2));
t.Title.String = ['Cluster ' cluster ' ' xTitle ' Force-Response ' xTitleMod ];
t.Title.FontWeight = 'bold';
t.Title.FontSize=18;



% plotOutput = zeros(6,num_Cells);  %*130 removed
plotOutput = zeros(5,num_Cells);  %*130 removed
[tileCount] = 1;


for i=1:size(cluster2Plot, 1)
    if mod(i-1,30)==0 && i~=1
        figureCount=figureCount+1;
        
        figure; 
        t=tiledlayout(plot_Dims(figureCount,1), plot_Dims(figureCount,2));
        t.Title.String = ['Cluster ' cluster ' AUC Force-Response'];
        t.Title.FontWeight = 'bold';
        t.Title.FontSize=18;
        tileCount=1;
    end


    yData= inData(:,cluster2Plot(i));

    plotOutput(1,i)=cluster2Plot(i);
%     plotOutput(2:6, i)=yData; %*130 removed
    plotOutput(2:5,i)=yData; %*130 removed
    
    plotFitOutput=in_plotFit{4,i}(1,1:4);
    fit_x = in_plotFit{1,i}(1,1);
    fit_n = in_plotFit{1,i}(1,2);
    mean_rsq = in_plotFit{11,i}(1,1);
%     string =  ['y = ' num2str(fit_x) 'x + ' num2str(fit_n) '   R2=' num2str(mean_rsq)];
    string =  ['R^2=' num2str(mean_rsq)];

    nexttile(tileCount)

    scatter(xValues, yData, sz, c, 'filled');
    % scatter(xValues, yData, 'filled');
    % scatter(xValues, yData);
    hold on;
    line(xValues, yData);
%     line(xValues,plotFitOutput);
    plot(xValues,plotFitOutput, 'k');
    text(0.05,0.9,string, 'Units','Normalized');
    title(['Cell #' num2str(cluster2Plot(i))])        
    if xValues(1,1)~=1
        xlabel('Force (mN)')
    else
        xlabel('Stim #')
    end
    ylabel(yTitle)
    % ylim([0 5000])
    
    tileCount=tileCount+1;

end

plotStats(:,1) = mean(plotOutput, 2);
plotStats(:,2) = std(plotOutput,0,2)/sqrt(num_Cells);

figure;
hold on;
for i=1:size(plotOutput, 2)
%     plot(xValues, plotOutput(2:5,i), '-o', 'Color', '#8CC1DD'); %*130 removed
    scatter(xValues, plotOutput(2:5,i), sz, [0.01,0.58,0.83], 'filled'); %*130 removed
    line(xValues, plotOutput(2:5,i));% line(xValues, plotOutput(2:6,i))

end

% errorbar(xValues, plotStats(2:6, 1), plotStats(2:6, 2), 'Color','#FF8C00', 'LineWidth', 2); %*130 removed
% plot(xValues, plotStats(2:6, 1), 'LineWidth',2, 'Color', '#FFA600'); %*130 removed
errorbar(xValues, plotStats(2:5, 1), plotStats(2:5, 2), 'Color', '#FF8C00', 'LineWidth', 2); %*130 removed
plot(xValues, plotStats(2:5, 1), 'LineWidth',2, 'Color', '#FFA600'); %*130 removed

title(['Cluster ' cluster ' ' xTitle ' Force-Response ' xTitleMod], 'FontSize', 18, 'FontWeight', 'bold'); 
ylabel(yTitle)

% If data is sorted by force, set x axis limits
if xValues(1,1)~=1
    xlim([80 450])
    xlabel('Force (mN)')
else
%     xticks([0, 1, 2, 3, 4, 5]) %*130 removed
%     xticklabels({'0' '1 (130)','2 (290)','3 (90)','4 (195)','5 (440)'}) %*130 removed
    xticks([0, 1, 2, 3, 4]) %*130 removed
    xticklabels({'0','2 (290)','3 (90)','4 (195)','5 (440)'}) %*130 removed
    xlabel('Stimulus number')
end
            

end

