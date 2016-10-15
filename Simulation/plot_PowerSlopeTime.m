   function plot_PowerSlopeTime(track,supercaps,OutputFolder, SimulationTime, TimeInterval)
            figure()
            time1 = 1:TimeInterval:SimulationTime;
            title('Power of Wheels/Supercaps and Slope as a function of Time');
            ax1 = gca; % current axes
            ax1.XColor = 'k';
            ax1.YColor = 'b';
            ax1.XLim = [0, SimulationTime];
            ax1.YLabel.String = 'Power (W)';
            ax1.YLim = [min(supercaps.PowerOut) max(supercaps.PowerOut)];
            ax1_pos = ax1.Position;
            % hLine1=line(time1,TBuff,'Color','b');
            % L{1}='(Buffer.Temp)';

            ax2 = axes('Position',ax1_pos,...
                'YAxisLocation','right',...
                'Color','none');
            ax2.YLabel.String = 'Slope';
            ax2.YLim = [min(track.Incline) max(track.Incline)];
            ax2.YColor = [1,0.3,0];
            % hLine3=line(time1,QBuff_watts,'Parent',ax2,'Color',[1,0.3,0]);
            % L{3}='(Q.Buffer)';
            xlabel('{\it Time}');
            % make legend
            legend('Location','NorthEast')
            hold on
            plot(supercaps.TimeEllapsed, supercaps.PowerOut)
%             x2 = 1:supercaps.TimeEllapsed/numel(track.Incline):numel(track.Incline);
%             plot(x2, track.Incline)
            saveas(gcf,[OutputFolder Delimiter() 'PowerSlopeTime.png'])
        end