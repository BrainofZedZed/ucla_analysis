function  clabel = FastScreener(ms)
% Fast scan through all traces and label traces
% Input takes CNMFE output ms, or leave it blank, a pop out window will let
% you choose your saved ms.mat.
% Keys: a -- previous cell. d -- next cell. j -- change label. s --
% save(will save to the same directory with ms.mat if input is blank,
% otherwise will save to current working directory), file name = c_label.mat. 
% title will indicate the label of current cell, green = good, red = bad

    if nargin < 1
        [msfile, msfold] = uigetfile();
        ms = load([msfold, msfile]);
        ms = ms.ms;
    else
        msfold = pwd;
    end
    
    

    traces = zscore(ms.RawTraces);
    filttraces = zscore(ms.FiltTraces);
    if ~isfield(ms, 'cell_label')
        clabel = ones(1,size(traces,2));
    else
        clabel = ms.cell_label;
    end
    cur_c = 1;
    num_c = size(traces,2);
    fi = figure('KeyPressFcn',@KeyFcn,'Position',[100,100,800,400]);
    setappdata(fi, 'cur_c', cur_c);
    setappdata(fi, 'num_c', num_c);
    setappdata(fi, 'traces', traces);
    setappdata(fi, 'clabel', clabel);
    setappdata(fi, 'path', msfold);
    setappdata(fi, 'fitraces', filttraces);
    setappdata(fi, 'rawflag', true);
    ax = axes('Parent', fi);
    phandle = plot((1:size(traces,1))/15,traces(:,cur_c),'Parent',gca);
    set(ax, 'XLim', [1,size(traces,1)/15]);
    setappdata(fi, 'phandle', phandle);
    ctitle = title(ax, ['cell#', num2str(cur_c),'/',num2str(num_c)]);
    if clabel(cur_c) == 0
        set(ctitle, 'Color', [1,0,0]);
    else
        set(ctitle, 'Color', [0,1,0]);
    end
    setappdata(fi, 'ctitle', ctitle);
end

function KeyFcn(src, event)
    switch event.Key
        case 'a'
            ts = getappdata(src, 'traces');
            fts = getappdata(src, 'fitraces');
            c = getappdata(src, 'cur_c');
            rawflag = getappdata(src, 'rawflag');
            
            c = max(c-1, 1);
            setappdata(src, 'cur_c', c);
            clabel = getappdata(src, 'clabel');
            phandle = getappdata(src, 'phandle');
            if rawflag
                set(phandle, 'YData', ts(:,c));
            else
                set(phandle, 'Ydata', fts(:,c));
            end
            ctitle = getappdata(src, 'ctitle');
            set(ctitle, 'String', ['cell#', num2str(c),'/',num2str(getappdata(src,'num_c'))]);
            if clabel(c) == 1
                set(ctitle, 'Color', [0,1,0]);
            else
                set(ctitle, 'Color', [1,0,0]);
            end
        case 'd'
            ts = getappdata(src, 'traces');
            fts = getappdata(src, 'fitraces');
            rawflag = getappdata(src, 'rawflag');
            c = getappdata(src, 'cur_c');
            nu = getappdata(src, 'num_c');
            c = min(c+1, nu);
            setappdata(src, 'cur_c', c);
            phandle = getappdata(src, 'phandle');
            if rawflag
                set(phandle, 'YData', ts(:,c));
            else
                set(phandle, 'YData', fts(:,c));
            end
            ctitle = getappdata(src, 'ctitle');
            set(ctitle, 'String', ['cell#', num2str(c),'/',num2str(nu)]);
            clabel = getappdata(src, 'clabel');
            if clabel(c) == 1
                set(ctitle, 'Color', [0,1,0]);
            else
                set(ctitle, 'Color', [1,0,0]);
            end
        case 'j'
            c = getappdata(src, 'cur_c');
            c_label = getappdata(src, 'clabel');
            c_label(c) = setdiff([0,1], c_label(c));
            setappdata(src, 'clabel', c_label);
            tclabel_handle = getappdata(src, 'ctitle');
            if c_label(c) == 0
                set(tclabel_handle, 'Color', [1,0,0]);
            else
                set(tclabel_handle, 'Color', [0,1,0]);
            end
        case 's'
            c_label = getappdata(src, 'clabel');
            msfold = getappdata(src, 'path');
            save([msfold, 'c_label.mat'], 'c_label');
        case 'r'
            ts = getappdata(src, 'traces');
            fts = getappdata(src, 'fitraces');
            rawflag = getappdata(src, 'rawflag');
            setappdata(src, 'rawflag', ~rawflag);
            c = getappdata(src, 'cur_c');
            phandle = getappdata(src, 'phandle');
            if ~rawflag
                set(phandle, 'YData', ts(:,c));
            else
                set(phandle, 'YData', fts(:,c));
            end
            
    end
            
            
        
    end
        

