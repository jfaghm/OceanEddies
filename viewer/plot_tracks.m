function plot_tracks( tracks_cell, tracks_names, daterefs_cell, ...
    contours, ssh, lat, lon, latlim, lonlim)
%PLOT_TRACKS Summary of this function goes here
%   Detailed explanation goes here
    COLORS = {'r' 'b' 'w' 'k' 'g' 'm' 'c' 'y'};

    hdls.fig = figure;
    set(hdls.fig, 'Units', 'normalized', 'Name', 'Timestep Controller');
    ffig = figure;
    axesm('pcarre', 'MapLatLimit', latlim, 'MapLonLimit', lonlim);
    colormapeditor;
%     worldmap(latlim, lonlim);
%     f = gca;
%     colormap('winter');
%     gfig = figure;
%     g = gca;
%     colormap(g, 'winter');

    nextPressed = false;
    prevPressed = false;
    reset = false;
    loop = false;
    done = false;
    bodiestoggle = false;
    i0 = 0;

    hdls.prev = uicontrol(hdls.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [.05, .65, .4, .2], 'String', 'Previous', 'Callback', @(x, y)(assignin('caller', 'prevPressed', true)));
    hdls.next = uicontrol(hdls.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [.5, .65, .4, .2], 'String', 'Next', 'Callback', @(x, y)(assignin('caller', 'nextPressed', true)) );
    hdls.done = uicontrol(hdls.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [.05, .4, .4, .2], 'String', 'Done', 'Callback', @(x, y)(assignin('caller', 'done', true)) );
    hdls.done = uicontrol(hdls.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [.5, .4, .4, .2], 'String', 'Show Bodies', 'Callback', @(x, y)(assignin('caller', 'bodiestoggle', true)) );
    hdls.reset = uicontrol(hdls.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [.05, .15, .4, .2], 'String', 'Reset', 'Callback', @(x, y)(assignin('caller', 'reset', true)));
    hdls.loop = uicontrol(hdls.fig, 'Style', 'pushbutton', 'Units', 'normalized', ...
        'Position', [.5, .15, .4, .2], 'String', 'Loop', 'Callback', @(x, y)(assignin('caller', 'loop', true)));

    %% Plot
    i = 1;
    leg_hdls = zeros(size(daterefs_cell));
    while ~done
        set(0, 'CurrentFigure', ffig)
        for j = 1:length(daterefs_cell)
            dateref = daterefs_cell{j};
            tracks = tracks_cell{j};
            if isempty(dateref{i})
                continue;
            end
            tidx = dateref{i}(1);
            cpos = tracks{tidx}(:,3) == i;
            leg_hdls(j) = plotm(tracks{tidx}(:,1:2), COLORS{j});
            plotm(tracks{tidx}(cpos,1:2), [COLORS{j} 's']);
            for k = 2:length(dateref{i})
                tidx = dateref{i}(k);
                cpos = tracks{tidx}(:,3) == i;
                plotm(tracks{tidx}(:,1:2), COLORS{j});
                plotm(tracks{tidx}(cpos,1:2), [COLORS{j} 's']);
            end
        end
%         copyobj(allchild(f), g);
%         h = pcolor(f, colored(:,:,i));
%         hssh = pcolor(g, ssh(:,:,i));
        slice = ssh(:,:,i);
        slice(contours(:,:,i)) = max(slice(:))+0.1*range(slice(:));
        pcolorm(lat, lon, slice);
        legend(leg_hdls, tracks_names);
%         set(h, 'EdgeColor', 'none');
%         set(hssh, 'EdgeColor', 'none');
        while ~done && ~prevPressed && ~nextPressed && ~loop && ~reset
            pause(0.1);
        end
        if prevPressed
            i = max(i-1, 1);
            prevPressed = false;
        elseif nextPressed
            i = min(i+1, size(ssh,3));
            nextPressed = false;
        elseif loop
            if i0 == 0
                i0 = i;
            end
            if i-i0 >= 26
                loop = false;
                i = i0;
                i0 = 0;
            else
                i = i + 1;
                pause(0.1);
            end
        elseif bodiestoggle
            boddiestoggle = false;
        elseif reset
            i = 1;
            reset = false;
        end
        set(0, 'CurrentFigure', ffig)
        clma();
%         delete(hdls);
%         delete(allchild(f));
%         delete(allchild(g));
    end
    close(ffig);
    close(hdls.fig);
%     close(gfig);

end

