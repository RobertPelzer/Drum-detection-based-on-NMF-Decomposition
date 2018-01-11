function [  ] = get_plots( currentItem, p )
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Name: get_plots
% 
%   execute plot functions:     plot audio mix
%                               plot onset detection
%                               plot nmf matrixes (Vhat, gain, basis)
%   
%
% Input:
%   currentItem: current item container
%   p: parameter container
%
% Output: nothing
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% plot audio mix
if(p.plot.mix || p.plot.all)
    fig = figure('position', [250, 300, 500, 120]);
    sig = currentItem.audio_MIX;
    tAxis = [1:length(sig)]/currentItem.fs;
    plot(tAxis,sig,'color',[0.5 0.5 0.5],'Linewidth',0.6);
    title('Mix Audiofile')
    xlabel('time [s]');
    ylabel('amplitude');
    set(gca,'xtick',[]);
    set(gca,'ytick',[]);
    axis([0 3 -0.8 0.8]);
    
    if(p.plot.save)
        set(gcf,'PaperPositionMode','auto');
        print(fig,'plots\mix','-dpng','-r300');
    end
end

% plot onset detection
if(p.plot.onsets || p.plot.all)
    fig = figure('position', [10, 500, 400, 400]);
    for k = 2:p.numTrackTypes
        subplot(p.numInstruments,1,k-1);
        hold on

        text(-0.7,0.5,...
            'Onsets',...
            'HorizontalAlignment','center',... 
            'BackgroundColor',[1 0 0]);
        
        text(-1,-0.5,...
            'GT',...
            'HorizontalAlignment','center',... 
            'BackgroundColor',[0 1 0]);

        onsets = [];
        % plot found onsets
        if isfield(currentItem.CUS_onsets,([p.trackTypes{k}]))
          onsets = currentItem.CUS_onsets.([p.trackTypes{k}]);

          % draw each onset
          for h = 1:length(onsets)
            plot([onsets(h) onsets(h)],[0 0.8],'r','Linewidth',2);
          end
        end


        % plot ground truth onsets    
        if isfield(currentItem.GT_onsets,([p.trackTypes{k}]))
          onsets = currentItem.GT_onsets.([p.trackTypes{k}]);
          % draw each onset
          for h = 1:length(onsets)
            plot([onsets(h) onsets(h)],[-0.8 0],'g','Linewidth',2);
          end
        end

        title({['instrument: ',p.trackTypes{k}]});
        xlabel('time [s]');
        set(gca, 'YTick', []);
        axis([0 8 -1 1]);
        hold off

        drawnow;
    end
    if(p.plot.save)
        set(gcf,'PaperPositionMode','auto');
        print(fig,'plots\onsets','-dpng','-r300');
    end
end

% plot nmf matrixes
if(p.plot.nmf || p.plot.all)
    % plot instrument spectrograms
    fig = figure('position', [750, 250, 500, 400]);
    for k = 1:p.numInstruments
      subplot(p.numInstruments,1,(p.numInstruments-(k-1)))
      imagesc(log(1+currentItem.nmfV{k}*20));axis xy
      colormap(hot);
      title(['Spectrogram of ', p.trackTypes{k}]);
      xlabel('time [s]');
      ylabel('frequency [Hz]');
      set(gca,'xtick',[]);
      set(gca,'ytick',[]);
    end
    
    if(p.plot.save)
        set(gcf,'PaperPositionMode','auto');
        print(fig,'plots\spectroInstruments','-dpng','-r300');
    end
    
    % plot mixture spectrogram Vhat
    fig = figure('position', [750, 10, 500, 130]);
    imagesc(log(1+currentItem.mixSpectrum*20));axis xy
    colormap(hot);
    title('Spectrogram of MIX');
    xlabel('time [s]');
    ylabel('frequency [Hz]');
    set(gca,'xtick',[]);
    set(gca,'ytick',[]);
    
    if(p.plot.save)
        set(gcf,'PaperPositionMode','auto');
        print(fig,'plots\spectroMix','-dpng','-r300');
    end

    % plot basis functions W, if basis functions are averaged
    if(p.trainSetMode == 2)
        trainSet = [p.trainSetMean.KD; p.trainSetMean.SD; p.trainSetMean.HH]';

        fig = figure('position', [10, 10, 200, 400]);
        imagesc(log(1+trainSet*20));
        axis xy;
        colormap(hot);
        title('basis functions W');
        xlabel('KD        SD         HH');
        ylabel('frequency [Hz]');
        set(gca,'xtick',[]);
        set(gca,'ytick',[]);
        
        if(p.plot.save)
            set(gcf,'PaperPositionMode','auto');
            print(fig,'plots\spectroW','-dpng','-r300');
        end
        
        fig = figure('position', [10, 20, 200, 400]); 
        imagesc(log(1+currentItem.Winit*300));
        axis xy;
        colormap(hot);
        title('basis functions Winit');
        xlabel('KD        SD         HH');
        ylabel('frequency [Hz]');
        set(gca,'xtick',[]);
        set(gca,'ytick',[]);
        
        if(p.plot.save)
            set(gcf,'PaperPositionMode','auto');
            print(fig,'plots\spectroWinit','-dpng','-r300');
        end
    end

    % plot gain functions H
    fig = figure('position', [250, 10, 450, 200]);
    imagesc(log(1+currentItem.H));
    colormap(hot);
    title('gains H');
    ylabel('HH        SD         KD');
    xlabel('time [s]');
    set(gca,'xtick',[]);
    set(gca,'ytick',[]);
    
    if(p.plot.save)
        set(gcf,'PaperPositionMode','auto');
        print(fig,'plots\spectroH','-dpng','-r300');
    end
    
    % plot basis functions W
    if(p.trainSetMode ~= 2)
        fig = figure('position', [10, 10, 200, 400]); 
        imagesc(log(1+currentItem.W*300));
        axis xy;
        colormap(hot);
        title('basis functions W');
        xlabel('KD        SD         HH');
        ylabel('frequency [Hz]');
        set(gca,'xtick',[]);
        set(gca,'ytick',[]);
        
        if(p.plot.save)
            set(gcf,'PaperPositionMode','auto');
            print(fig,'plots\spectroW','-dpng','-r300');
        end
        
        fig = figure('position', [10, 20, 200, 400]); 
        imagesc(log(1+currentItem.Winit*300));
        axis xy;
        colormap(hot);
        title('basis functions Winit');
        xlabel('KD        SD         HH');
        ylabel('frequency [Hz]');
        set(gca,'xtick',[]);
        set(gca,'ytick',[]);
        
        if(p.plot.save)
            set(gcf,'PaperPositionMode','auto');
            print(fig,'plots\spectroWinit','-dpng','-r300');
        end
    end
end

if(p.plot.novCurve || p.plot.all)
    for k = 1:p.numInstruments
        fig = figure('position', [700, 600, 500, 300]);
        Sample_per_Frame = floor(length(currentItem.audio_MIX)/currentItem.numFrames);
        Zeit = Sample_per_Frame/currentItem.fs.*linspace(1,length(currentItem.T(k, :)),length(currentItem.T(k, :)));
        plot(Zeit,currentItem.T(k, :),'red','Linewidth',1.5);
        hold on;
        plot(Zeit,currentItem.D(k, :),'blue','Linewidth',1.5);
        hold off;
        title(['Novelty Curve and threshold of ', p.instruments{k}]);
        axis([0 4 0 1]);
        xlabel('time [s]');
        ylabel('amplitude');
        legend('threshold','novelty curve','Location','southoutside','Orientation','horizontal');
    
        if(p.plot.save)
            set(gcf,'PaperPositionMode','auto');
            print(fig,['plots\novCurve_', p.instruments{k}],'-dpng','-r300');
        end
    end
end
end

