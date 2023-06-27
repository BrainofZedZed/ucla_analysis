function varargout = msDeleteROI(varargin)
% MSDELETEROI MATLAB code for msDeleteROI.fig
%      MSDELETEROI, by itself, creates a new MSDELETEROI or raises the existing
%      singleton*.
%
%      H = MSDELETEROI returns the handle to a new MSDELETEROI or the handle to
%      the existing singleton*.
%
%      MSDELETEROI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MSDELETEROI.M with the given input arguments.
%
%      MSDELETEROI('Property','Value',...) creates a new MSDELETEROI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before msDeleteROI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to msDeleteROI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help msDeleteROI

% Last Modified by GUIDE v2.5 24-Jun-2019 14:57:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @msDeleteROI_OpeningFcn, ...
                   'gui_OutputFcn',  @msDeleteROI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before msDeleteROI is made visible.
function msDeleteROI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to msDeleteROI (see VARARGIN)

% Choose default command line output for msDeleteROI
handles.output = hObject;

% % % % Update handles structure
% % % guidata(hObject, handles);
handles = initialize_parameters(hObject, handles);
if length(varargin) > 1
    ms_filename = varargin{1};
    handles.ms_filename = ms_filename;
    set(handles.ms_filename_txt,'string',ms_filename);
    %loads the full version of neuron struct, i.e. neuronFull.mat
    neuron_filename = varargin{2};
    handles.neuron_filename = neuron_filename;
    set(handles.neuron_filename_txt,'string',neuron_filename);
    %loads the video file
    video_filename = varargin{3};
    handles.video_filename = video_filename;
    set(handles.video_filename_txt,'string',video_filename);
else
    handles = get_vid_and_folders(hObject, handles);
end

% % % % Update handles structure
% % % guidata(hObject, handles);

handles = load_data_to_GUI(hObject, handles);
if (handles.fast_mode == 0)
   handles = update_display(hObject, handles);
else 
    update_roi_display(handles);
end
% set(gcf, 'units','normalized','outerposition',[0 0 1 1]);
% Update handles structure
guidata(hObject, handles);


% UIWAIT makes msDeleteROI wait for user response (see UIRESUME)
uiwait(handles.figure1);

function handles = initialize_parameters(hObject, handles)
%Fast mode selection
handles.fast_mode = 1;%1 = fast mode: 
%first show only ROIs and trace, then the rest of the GUI after it's finished

%display
handles.chosen_roi_id = 1;
handles.roi_gal_sorting = 'ascend';%how to sort the ROIs in the gellary according to roi_score
handles.display_mode = 1;%1 = mean frame, 2 = roi gallery, 3 = roi video
handles.sort_mode = 1;%1 = original, 2 = sorted by score
handles.mean_frame_clim = [0 1];
handles.roi_gal_clim = [0 0.3]; %imagesc clim
handles.enable_neuron_order = 0;%do not enable changing sort method
handles.pxl_th = 0.35; %segment=roi contour TH
handles.seg_color = [1 0 0];
handles.roi_transparency = 0.3;
handles.roi_compactness = 0.6;

handles.selected_marker_size = 2;
handles.marker_color_on = [1 0 0];
handles.deleted_marker_size = 10;
handles.del_marker_color = [1 0 1];
handles.del_marker_size = 200; 
handles.del_line_width = 2;
handles.del_marker_linewidth = 5;
handles.marker_color_selected = [0 1 1];
handles.marker_color_edge = [0 0 0];
handles.empty_gal_roi = 1;
handles.main_axes_colormap = gray;

%video parameters
handles.vid_win_size_proportion = 0.1; %=10% of win size, proportion of ROI video size out of total frame size
handles.vid_win_duration = 10; %in seconds (5sec before, and 5sec after chosen time point), duration of the video to be loaded.
handles.vid_fps_factor = 3;%fast play option (1 = normal speed)
handles.get_timePoint_flag = 0;
handles.roi_axes_colormap = gray;


handles.ctrl_pressed = 0;

handles.mouse_select = 0;

handles.main_axes_multi_select_h = {};
handles.main_axes_del_roi_h = {};
handles.main_axes_del_roi_seg_h = [];

handles.main_axes_mouse_select_h = {};

handles.plot_ca_clean_trace = 1;
handles.plot_ca_raw_trace = 1;
handles.plot_ca_trace_spk = 0;




function handles = get_vid_and_folders(hObject, handles)

curr_path = cd();
handles.curr_path = curr_path;

%load ms file: for video data
fprintf('Choose ms file to analyze\n');
[ms_file_filename, ms_file_path] = uigetfile('*.mat','Choose ms file to analyze');
ms_filename = [ms_file_path ms_file_filename];
set(handles.ms_filename_txt,'string',ms_filename);
handles.ms_filename = ms_filename;
%load neuron structure file: CNMF data
fprintf('Choose neuronFull struct file to analyze\n');
[neuron_file_filename, neuron_file_path] = uigetfile('*.mat','Choose neuron struct file to analyze');
neuron_filename = [neuron_file_path neuron_file_filename];
set(handles.neuron_filename_txt,'string',neuron_filename);
handles.neuron_filename = neuron_filename;
%load motion corrected video
fprintf('Choose motion corrected video file to analyze\n');
[video_file_filename, video_file_path] = uigetfile('*.avi','Choose motion corrected video file to analyze');
video_filename = [video_file_path video_file_filename];
set(handles.video_filename_txt,'string',video_filename);
handles.video_filename = video_filename;

% Update handles structure
guidata(hObject, handles);

function handles = load_data_to_GUI(hObject, handles)
f = waitbar(0,'Loading ms file');
%load ms
tmp = load(handles.ms_filename);
% handles.ms = tmp.ms;
fnm = fieldnames(tmp);
handles.ms = eval(['tmp.' fnm{1}]);
clear tmp fnm

waitbar(.33,f,'Loading neuron file');

%load neuron
tmp = load(handles.neuron_filename);
% neuron_struct = tmp.ms;
fnm = fieldnames(tmp);
neuron_struct = eval(['tmp.' fnm{1}]);

waitbar(.66,f,'Loading video file');

%load video
tmp = VideoReader(handles.video_filename);
handles.videoObj = tmp;
% handles.video_mat = zeros(tmp.Height,tmp.Width,floor(tmp.Duration*tmp.FrameRate));
% k = 1;
% while hasFrame(tmp)
%     handles.video_mat(:,:,k) = readFrame(tmp);
%     k = k+1;
% end

% Prealocate for ROI video
handles.video_fps = tmp.FrameRate;
handles.ROI_vid_half_width = floor(tmp.Width*handles.vid_win_size_proportion/2);
handles.ROI_vid_half_height = floor(tmp.Height*handles.vid_win_size_proportion/2);
handles.ROI_vid_half_frame_duration = floor(handles.vid_win_duration*tmp.FrameRate/2);
handles.ROI_video = zeros(2*handles.ROI_vid_half_width,2*handles.ROI_vid_half_height,2*handles.ROI_vid_half_frame_duration);


clear tmp fnm
handles.neuron_struct = neuron_struct;
[d1s, d2s] = size(neuron_struct.Cn);%get dim of downsampled frame
%reshape neuron.A to get a 3D matrix
if issparse(neuron_struct.A)
    roi_mat = reshape(full(neuron_struct.A),d1s,d2s,size(neuron_struct.A,2));
else
    roi_mat = reshape(neuron_struct.A,d1s,d2s,size(neuron_struct.A,2));
end

[~,~,Nroi] = size(roi_mat);
Nrow = floor(Nroi^.5);
Ncol = ceil(Nroi/Nrow);
addMat = reshape(handles.empty_gal_roi*ones(d1s,d2s*(Ncol*Nrow-Nroi)),d1s,d2s,(Ncol*Nrow-Nroi) );
roi_mat_full = cat(3,roi_mat,addMat);

roi_centroid_mat = zeros(Nroi,2);
roi_score = zeros(Nroi,1);
gallery_roi_mat = [];
temp_roi_row = [];
gallery_roi_mat_row = 1;

waitbar(.8,f,'Calculating roi index...');

for roi_ind = 1:size(roi_mat_full,3)
    if roi_ind <= Nroi
        roi = roi_mat(:,:,roi_ind);
        [i,j] = find(roi == max(max(roi)));
        roi_centroid_mat(roi_ind,:) = [i,j];
        [X, Y] = meshgrid(1:d2s,1:d1s);
        D = sqrt((X-j).^2 + (Y-i).^2); D(i,j) = 1;
        Ds = D; Ds(Ds > 5) = 0; Ds(Ds > 0) = 1; Ds(i,j) = 1;
        Dl = D; Dl(Dl > 50) = 0; Dl(Dl > 0) = 1; Dl = Dl-Ds; Dl(i,j) = 0;
        score = 100*mean(mean(roi.*Ds))/mean(mean(roi.*Dl));
        roi_score(roi_ind,1) = score;
    end
    temp_roi_row = horzcat(temp_roi_row,roi_mat_full(:,:,roi_ind));
    if mod(roi_ind,Ncol) == 0 %end of row
       gallery_roi_mat = vertcat(gallery_roi_mat, temp_roi_row);
       gallery_roi_mat_row = gallery_roi_mat_row + 1;
       temp_roi_row = [];
    end
%     [all_roi_mat_i,all_roi_mat_j] = ind2sub([Nrow Ncol],roi_ind); 
    waitbar(.8+(roi_ind/size(roi_mat_full,3))/10,f,'Calculating roi index...');
end
%now make sorted mat of ROIs
[roi_score_sorted,sort_ind] = sort(roi_score,1,handles.roi_gal_sorting);
roi_mat_full_sorted = cat(3,roi_mat(:,:,sort_ind),addMat);
gallery_roi_mat_sorted = [];
temp_roi_row = [];
for roi_ind = 1:size(roi_mat_full_sorted,3)
    temp_roi_row = horzcat(temp_roi_row,roi_mat_full_sorted(:,:,roi_ind));
    if mod(roi_ind,Ncol) == 0 %end of row
       gallery_roi_mat_sorted = vertcat(gallery_roi_mat_sorted, temp_roi_row);
       temp_roi_row = [];
    end
    waitbar(.9+(roi_ind/size(roi_mat_full,3))/20,f,'Sorting roi index...');
end
handles.Nroi = Nroi;
handles.Nroi_full = size(roi_mat_full,3);
handles.roi_mat = roi_mat;
handles.img_dim = [d1s, d2s];
handles.gal_dim = size(gallery_roi_mat);
handles.roi_id = [1:Nroi;sort_ind']';
handles.valid_roi_id = ones(Nroi,1);%valid = 1, deleted = 0; 

handles.roi_centroid_mat = roi_centroid_mat;
handles.roi_score = roi_score;
handles.roi_score_sorted = roi_score_sorted;
handles.gallery_roi_mat = gallery_roi_mat;
handles.gallery_roi_mat_sorted = gallery_roi_mat_sorted;


handles.dx_min = floor(d2s/2);
handles.dy_min = floor(d1s/2);

%6/10/2019 AYAL: load contours from CNMF
waitbar(.95,f,'Loading roi contours...');
handles.patch_vdata_cell = neuron_struct.get_contours(handles.roi_compactness);
close(f)
figure(gcf), axes(handles.main_axes), hold on;
imagesc(handles.neuron_struct.Cn,handles.mean_frame_clim);
xlim([0 handles.img_dim(2)])
ylim([0  handles.img_dim(1)])
text(handles.dx_min,handles.dy_min,{'Running on','Fast Mode'},'color','r',...
    'fontsize',40,'fontweight','bold','horizontalalignment','center')
set(gca,'xtick',[],'ytick',[]);


%use fast display GUI

if (handles.plot_ca_clean_trace == 1)
    set(handles.ca_clean_trace_axes,'visible','on');
end

if (handles.plot_ca_raw_trace == 1)
    set(handles.ca_raw_trace_axes,'visible','on');
    linkaxes([handles.ca_clean_trace_axes, handles.ca_raw_trace_axes],'x');
end


% Update handles structure
guidata(hObject, handles);

function handles = update_display(hObject, handles)

if (handles.fast_mode == 0)
    
    %main display
    figure(gcf), axes(handles.main_axes), hold on,
    cla
    axis ij
    colormap(handles.main_axes_colormap);
    switch handles.display_mode
        case 1 %mean frame
            xlim([0 handles.img_dim(2)])
            ylim([0  handles.img_dim(1)])
            
            imagesc(handles.neuron_struct.Cn,handles.mean_frame_clim);
            %          imagesc(imeanframe)
            shading flat
            daspect([1 1 1])
            %         colormap gray
            roi_x = handles.roi_centroid_mat(:,2);
            roi_y = handles.roi_centroid_mat(:,1);
            
            % plot roi contour AYAL 6/5/2019
            patch_vdata_cell = handles.patch_vdata_cell;
            handles.main_axes_del_roi_seg_h = [];
            Nroi=handles.Nroi;
            for roi_ind = 1:Nroi
                
                
                patch_vdata = patch_vdata_cell{roi_ind};
                %plot patch
                handles.main_axes_del_roi_seg_h(roi_ind) = ...
                    patch('Faces',[1:size(patch_vdata',1)],'Vertices',patch_vdata',...
                    'FaceColor',handles.seg_color,'FaceAlpha',handles.roi_transparency,...
                    'EdgeColor',handles.seg_color);
                if (handles.valid_roi_id(roi_ind) == 0)
                    set(handles.main_axes_del_roi_seg_h(roi_ind),'visible','off');
                end
            end
            %plot centroids of ROIs
            plot(roi_x, roi_y,...
                'o',...
                'markersize',handles.selected_marker_size,...
                'MarkerEdgeColor', handles.marker_color_edge,...
                'MarkerFaceColor', handles.marker_color_on);

            
        case 2
            %ROI gallery
            %     cla
            xlim([0 handles.gal_dim(2)])
            ylim([0  handles.gal_dim(1)])
            
            
            if (handles.sort_mode == 1) %original
                figure(gcf), axes(handles.main_axes), hold on,
                imagesc(handles.gallery_roi_mat,handles.roi_gal_clim);
                % %         chosen_roi_gal_pos = find(handles.roi_id(:,1) == chosen_roi_id);
                %         title_text = sprintf('ROI #%d (%.4f)',chosen_roi_id(1), handles.roi_score(chosen_roi_gal_pos));
            else
                figure(gcf), axes(handles.main_axes), hold on,
                imagesc(handles.gallery_roi_mat_sorted,handles.roi_gal_clim);
                % %         chosen_roi_gal_pos = find(handles.roi_id(:,2) == chosen_roi_id);
                %         title_text = sprintf('ROI #%d (%.4f)',chosen_roi_id(1), handles.roi_score_sorted(chosen_roi_gal_pos));
            end
            d1s = handles.img_dim(1);
            d2s = handles.img_dim(2);
            d1l = handles.gal_dim(1);
            d2l = handles.gal_dim(2);
            Nroi = handles.Nroi;
            Nrow = floor(Nroi^.5);
            Ncol = ceil(Nroi/Nrow);
            %add grid
            line([d2s:d2s:d2l;d2s:d2s:d2l],[zeros(1,Ncol); ones(1,Ncol)*d1l],'color',[0 0 0]);
            line([zeros(1,Nrow); ones(1,Nrow)*d2l],[d1s:d1s:d1l;d1s:d1s:d1l],'color',[0 0 0]);
            
            drawnow
               
    end
    
end
if ~isempty(handles.chosen_roi_id)
    %update DELETED
    handles = update_del_display(handles,hObject);
    %update SELECTED
    handles = update_selected_display(handles, hObject);
    %update ROI display
    update_roi_display(handles);
    
end
% Update handles structure
guidata(hObject, handles);


%SELECTED plot
function handles = update_selected_display(handles, hObject)
if (handles.fast_mode == 0)
    chosen_roi_id = handles.chosen_roi_id;
    if isempty(chosen_roi_id)
        %If nothing was selected - EXIT
        return
    end
    figure(gcf), axes(handles.main_axes), hold on,
    if (handles.mouse_select == 1)
        C = get (gca, 'CurrentPoint');
        mark = C(1,1:2);
        title(gca, ['(X,Y) = (', num2str(mark(1,1)), ', ',num2str(mark(1,2)), ')']);
        
        if isfield(handles,'main_axes_mouse_select_h')
            %delete previous graphical multi-choice
            del_cell = cellfun(@(x) intersect(get(gca,'Children'),x),handles.main_axes_mouse_select_h,'UniformOutput',0);
            cellfun(@(y) delete(y),del_cell(~isempty(del_cell)));
            drawnow
        end
        %cleat struct
        handles.main_axes_mouse_select_h = {};
        handles.main_axes_multi_select_display_mode_h = [handles.display_mode, handles.sort_mode];
        
        handles.chosen_roi_id = [];
        
        d1s = handles.img_dim(1);
        d2s = handles.img_dim(2);
        d1l = handles.gal_dim(1);
        d2l = handles.gal_dim(2);
        
        figure(gcf), axes(handles.main_axes), hold on, 
        switch handles.display_mode
            case 1
                point_vec = [handles.roi_centroid_mat(:,2) handles.roi_centroid_mat(:,1)];
                idx = knnsearch(point_vec,mark);
                if any(handles.chosen_roi_id == idx)
                    exist_ind = find(handles.chosen_roi_id == idx);
                    delete(handles.main_axes_mouse_select_h{exist_ind});
                    handles.main_axes_mouse_select_h(exist_ind) = [];
                    handles.chosen_roi_id(exist_ind) = [];
                else
                    handles.chosen_roi_id(1) = idx;
                    %update SELECTED plot
                    handles.main_axes_mouse_select_h{1} = ...
                        plot(point_vec(idx,1),point_vec(idx,2),...
                        'marker','o',...
                        'markersize',handles.selected_marker_size,...
                        'MarkerEdgeColor', handles.marker_color_edge,...
                        'MarkerFaceColor', handles.marker_color_selected);
                    % Update handles structure
                    guidata(hObject, handles);
                end
                
            case 2
                [x,y] = meshgrid([d2s/2:d2s:d2l],[d1s/2:d1s:d1l]);
                x = x'; y = y';
                point_vec = [x(:) y(:)];
                idx = min(knnsearch(point_vec,mark),handles.Nroi);
                if any(handles.chosen_roi_id == handles.roi_id(idx,handles.sort_mode))
                    exist_ind = find(handles.chosen_roi_id == handles.roi_id(idx,handles.sort_mode));
                    delete(handles.main_axes_mouse_select_h{exist_ind});
                    handles.main_axes_mouse_select_h(exist_ind) = [];
                    handles.chosen_roi_id(exist_ind) = [];
                else
 
                    Ncol = ceil(handles.Nroi/floor(handles.Nroi^.5));
                    row = ceil(idx/Ncol);
                    col = 1+mod(idx-1,Ncol);
                    handles.chosen_roi_id(1) = handles.roi_id(idx,handles.sort_mode);
                    %update SELECTED plot
                    x1 = (col-1)*d2s; %x2 = col*d2s;
                    y1 = (row-1)*d1s; %y2 = row*d1s;
                    handles.main_axes_mouse_select_h{1} = ...
                        plot(x1+handles.dx_min,y1+handles.dy_min,...
                        'marker','o',...
                        'markersize',handles.selected_marker_size,...
                        'MarkerEdgeColor', handles.marker_color_edge,...
                        'MarkerFaceColor', handles.marker_color_selected);
                    % Update handles structure
                    guidata(hObject, handles);
  
                end
            
        end
    else
        
        if isfield(handles,'main_axes_multi_select_h')
            %delete previous graphical multi-choice
            del_cell = cellfun(@(x) intersect(get(gca,'Children'),x),handles.main_axes_multi_select_h,'UniformOutput',0);
            cellfun(@(y) delete(y),del_cell(~isempty(del_cell)));
            drawnow
        end
        %clear struct
        handles.main_axes_multi_select_h = {};
        handles.main_axes_multi_select_display_mode_h = [handles.display_mode, handles.sort_mode];
        
        d1s = handles.img_dim(1);
        d2s = handles.img_dim(2);
        % % %     d1l = handles.gal_dim(1);
        % % %     d2l = handles.gal_dim(2);
        
        Nchosen_roi = length(chosen_roi_id);
        
        switch handles.display_mode
            case 1 %mean frame
                
                for chosen_roi_ind = 1:Nchosen_roi
                    point_vec = [handles.roi_centroid_mat(:,2) handles.roi_centroid_mat(:,1)];
                    idx = chosen_roi_id(chosen_roi_ind);
                    %update SELECTED plot
                    handles.main_axes_multi_select_h{chosen_roi_ind} = ...
                        plot(point_vec(idx,1),point_vec(idx,2),...
                        'marker','o',...
                        'markersize',handles.selected_marker_size,...
                        'MarkerEdgeColor', handles.marker_color_edge,...
                        'MarkerFaceColor', handles.marker_color_selected);
                end
            case 2
                for chosen_roi_ind = 1:Nchosen_roi
                    idx = find(handles.roi_id(:,handles.sort_mode) == chosen_roi_id(chosen_roi_ind));
                    %update SELECTED plot
                    Ncol = ceil(handles.Nroi/floor(handles.Nroi^.5));
                    row = ceil(idx/Ncol);
                    col = 1+mod(idx-1,Ncol);
                    
                    %update SELECTED plot
                    x1 = (col-1)*d2s; %x2 = col*d2s;
                    y1 = (row-1)*d1s;% y2 = row*d1s;
                    
                    handles.main_axes_multi_select_h{chosen_roi_ind} = ...
                        plot(x1+handles.dx_min,y1+handles.dy_min,...
                        'marker','o',...
                        'markersize',handles.selected_marker_size,...
                        'MarkerEdgeColor', handles.marker_color_edge,...
                        'MarkerFaceColor', handles.marker_color_selected);
                    
                end
            
        end
    end
    drawnow
    % Update handles structure
    guidata(hObject, handles);
end

function update_roi_display(handles)
%ROI display
figure(gcf), axes(handles.roi_axes), hold on,
set(gca,'xtick',[],'ytick',[]);
axis ij


if isempty(handles.chosen_roi_id)
    figure(gcf), axes(handles.roi_axes), cla
    figure(gcf), axes(handles.ca_raw_trace_axes), cla
    figure(gcf), axes(handles.ca_clean_trace_axes), cla
else
    
    chosen_roi_id = handles.chosen_roi_id(end);
        
    switch handles.display_mode
        case 1
            %display mode 1
            imagesc(handles.roi_mat(:,:,chosen_roi_id(end)),handles.roi_gal_clim);
            roi_score = handles.roi_score(handles.chosen_roi_id(end));
        case 2
            imagesc(handles.roi_mat(:,:,chosen_roi_id(end)),handles.roi_gal_clim);
            if (handles.sort_mode == 1)
                chosen_roi_gal_pos = find(handles.roi_id(:,1) == chosen_roi_id);
                roi_score = handles.roi_score(chosen_roi_gal_pos);
            else
                chosen_roi_gal_pos = find(handles.roi_id(:,2) == chosen_roi_id);
                roi_score = handles.roi_score_sorted(chosen_roi_gal_pos);
            end
    end
    if (handles.valid_roi_id(chosen_roi_id,1) == 0)
        [y,x] = size(handles.roi_mat(:,:,chosen_roi_id(end)));
        plot(x/2,y/2,'x',...
            'color', handles.del_marker_color,...
            'markersize',handles.del_marker_size ,...
            'linewidth', handles.del_marker_linewidth);
    end
    sort_idx = find(handles.roi_id(:,handles.sort_mode) == chosen_roi_id);
    title_text = sprintf('ROI #%d (%d) of %d (%.4f)',chosen_roi_id(end),sort_idx, handles.Nroi, roi_score);
    set(handles.roi_title_txt,'string',title_text);
    xlim([0 handles.img_dim(2)])
    ylim([0  handles.img_dim(1)])
    drawnow()
    %update Ca trace display
    update_ca_trace_display(handles);
    
end


function update_ca_trace_display(handles)
ca_trace_color = [0 0 1];
raster_bar_scale_factor = 20;
raster_color = [0 0 0];
ca_trace_linewidth = 3;

ds = handles.neuron_struct;
ms = handles.ms;
chosen_roi_id = handles.chosen_roi_id(end);

if (handles.plot_ca_raw_trace == 1)
    
    
    % RAW calcium signal + basic raster
     
    figure(gcf), axes(handles.ca_raw_trace_axes), cla, hold on,
    axis xy tight
    set(gca,'xlim',[0 max(ms.time)/1000],'ylim',1.1.*[min(ds.C_raw(chosen_roi_id,:))-1 max(ds.C_raw(chosen_roi_id,:))]);
    ca_spk_ind = find(ds.S(chosen_roi_id,:) > 0);
    raster_bar = (max(ds.C_raw(chosen_roi_id,:)) - min(ds.C_raw(chosen_roi_id,:)))/raster_bar_scale_factor;
    plot(ms.time'/1000,ds.C_raw(chosen_roi_id,:),'color',ca_trace_color);
    if (handles.plot_ca_trace_spk == 1)
        line([ms.time(ca_spk_ind)'; ms.time(ca_spk_ind)']./1000,...
            [ds.C_raw(chosen_roi_id,ca_spk_ind)- raster_bar; ds.C_raw(chosen_roi_id,ca_spk_ind)+ raster_bar],...
            'color',raster_color,...
            'linewidth',ca_trace_linewidth);
        hold off
    end
    drawnow()
end
    
% Processed calcium signal + basic raster
if (handles.plot_ca_clean_trace == 1)
    figure(gcf), axes(handles.ca_clean_trace_axes),cla , hold on,
    axis xy tight
    set(gca,'xlim',[0 max(ms.time)/1000],'ylim',1.1.*[min(ds.C(chosen_roi_id,:))-1 max(ds.C(chosen_roi_id,:))]);
    ca_spk_ind = find(ds.S(chosen_roi_id,:) > 0);
    raster_bar = (max(ds.C(chosen_roi_id,:)) - min(ds.C(chosen_roi_id,:)))/raster_bar_scale_factor;
    plot(ms.time'/1000,ds.C(chosen_roi_id,:),'color',ca_trace_color);
    if (handles.plot_ca_trace_spk == 1)
        line([ms.time(ca_spk_ind)'; ms.time(ca_spk_ind)']./1000,...
            [ds.C_raw(chosen_roi_id,ca_spk_ind)- raster_bar; ds.C(chosen_roi_id,ca_spk_ind)+ raster_bar],...
            'color',raster_color,...
            'linewidth',ca_trace_linewidth);
        hold off
    end
    drawnow()
end


% --- Outputs from this function are returned to the command line.
function varargout = msDeleteROI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
delete(handles.figure1)


% --- Executes on button press in select_btn.
function select_btn_Callback(hObject, eventdata, handles)
% hObject    handle to select_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
figure(gcf), axes(handles.main_axes), hold on,
mark = ginput(1);
d1s = handles.img_dim(1);
d2s = handles.img_dim(2);
d1l = handles.gal_dim(1);
d2l = handles.gal_dim(2);
switch handles.display_mode
    case 1
        point_vec = [handles.roi_centroid_mat(:,2) handles.roi_centroid_mat(:,1)];
        idx = knnsearch(point_vec,mark);
        handles.chosen_roi_id = idx;
        set(handles.main_axes_select_h,'x',point_vec(idx,1), 'y', point_vec(idx,2),'visible','on');
    case 2
        [x,y] = meshgrid([d2s/2:d2s:d2l],[d1s/2:d1s:d1l]);
        x = x'; y = y';
        point_vec = [x(:) y(:)];
        idx = knnsearch(point_vec,mark);
        Ncol = ceil(handles.Nroi/floor(handles.Nroi^.5));
        row = ceil(idx/Ncol);
        col = 1+mod(idx-1,Ncol);
        handles.chosen_roi_id = handles.roi_id(idx,handles.sort_mode);
        
        x1 = (col-1)*d2s; x2 = col*d2s;
        y1 = (row-1)*d1s; y2 = row*d1s;
        set(handles.main_axes_select_h(1),'x',[x1;x1],'y',[y1;y2],'visible','on' ,'color',handles.marker_color_selected);
        set(handles.main_axes_select_h(2),'x',[x2;x2],'y',[y1;y2],'visible','on','color',handles.marker_color_selected);
        set(handles.main_axes_select_h(3),'x',[x1;x2],'y',[y1;y1],'visible','on','color',handles.marker_color_selected);
        set(handles.main_axes_select_h(4),'x',[x1;x2],'y',[y2;y2],'visible','on','color',handles.marker_color_selected);
end
update_roi_display(handles);     
 % Update handles structure
guidata(hObject, handles);   

% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider


% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in select_multi_btn.
function select_multi_btn_Callback(hObject, eventdata, handles)
% hObject    handle to select_multi_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% set(handles.main_axes_select_h,'visible','off')
if isfield(handles,'main_axes_multi_select_h')
    %delete previous graphical multi-choice
    del_cell = cellfun(@(x) intersect(get(gca,'Children'),x),handles.main_axes_multi_select_h,'UniformOutput',0);
    cellfun(@(y) delete(y),del_cell(~isempty(del_cell)));
end

handles.main_axes_multi_select_h = {};
handles.main_axes_multi_select_display_mode_h = [handles.display_mode, handles.sort_mode];

% % % prev_chose_roi_id = handles.chosen_roi_id;  
handles.chosen_roi_id = [];

% beep
disp('Press LEFT mouse button to select.');
disp('Press RIGHT mouse button to stop');

d1s = handles.img_dim(1);
d2s = handles.img_dim(2);
d1l = handles.gal_dim(1);
d2l = handles.gal_dim(2);
but = 1;
roi_count = 1;

[xi, yi, but] = ginput(1);
mark = [xi, yi];
while but == 1
    figure(gcf), axes(handles.main_axes), hold on,
    
     
    switch handles.display_mode
        case 1
            point_vec = [handles.roi_centroid_mat(:,2) handles.roi_centroid_mat(:,1)];
            idx = knnsearch(point_vec,mark);
            if any(handles.chosen_roi_id == idx)
                exist_ind = find(handles.chosen_roi_id == idx);
                delete(handles.main_axes_multi_select_h{exist_ind});
                handles.main_axes_multi_select_h(exist_ind) = [];
                handles.chosen_roi_id(exist_ind) = [];
            else
                handles.chosen_roi_id(end+1) = idx;
                %update SELECTED plot
                handles.main_axes_multi_select_h{end+1} = ...
                    plot(point_vec(idx,1),point_vec(idx,2),...
                    'marker','o',...
                    'markersize',handles.selected_marker_size,...
                    'MarkerEdgeColor', handles.marker_color_edge,...
                    'MarkerFaceColor', handles.marker_color_selected);
            end
            
        case 2
            [x,y] = meshgrid([d2s/2:d2s:d2l],[d1s/2:d1s:d1l]);
            x = x'; y = y';
            point_vec = [x(:) y(:)];
            idx = min(knnsearch(point_vec,mark),handles.Nroi);
            if any(handles.chosen_roi_id == handles.roi_id(idx,handles.sort_mode))
                exist_ind = find(handles.chosen_roi_id == handles.roi_id(idx,handles.sort_mode));
                delete(handles.main_axes_multi_select_h{exist_ind});
                handles.main_axes_multi_select_h(exist_ind) = [];
                handles.chosen_roi_id(exist_ind) = [];
            else
                Ncol = ceil(handles.Nroi/floor(handles.Nroi^.5));
                row = ceil(idx/Ncol);
                col = 1+mod(idx-1,Ncol);
                handles.chosen_roi_id(end+1) = handles.roi_id(idx,handles.sort_mode);
                %update SELECTED plot
                x1 = (col-1)*d2s; x2 = col*d2s;
                y1 = (row-1)*d1s; y2 = row*d1s;
                end_ind = length(handles.main_axes_multi_select_h);
                handles.main_axes_multi_select_h{end_ind+1}(1) = ...
                    line([x1;x1],[y1;y2] ,'color',handles.marker_color_selected);
                handles.main_axes_multi_select_h{end_ind+1}(2) = ...
                    line([x2;x2],[y1;y2],'color',handles.marker_color_selected);
                handles.main_axes_multi_select_h{end_ind+1}(3) = ...
                    line([x1;x2],[y1;y1],'color',handles.marker_color_selected);
                handles.main_axes_multi_select_h{end_ind+1}(4) = ...
                    line([x1;x2],[y2;y2],'color',handles.marker_color_selected);
            end
    end
    % Update handles structure
    guidata(hObject, handles);
    
    update_roi_display(handles);
    % Update handles structure
    guidata(hObject, handles);

    roi_count = roi_count +1;
    figure(gcf), axes(handles.main_axes), hold on,
    [xi, yi, but] = ginput(1);
    mark = [xi, yi];
end
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in delete_btn.
function delete_btn_Callback(hObject, eventdata, handles)
% hObject    handle to delete_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
chosen_roi_id = handles.chosen_roi_id;
if isempty(chosen_roi_id)
    %If nothing was selected - EXIT
    disp('First SELECT and then delete ROIs');
    return
end
chosen_roi_id = handles.chosen_roi_id;
handles.valid_roi_id(chosen_roi_id,1) = 0;
% Update handles structure
handles = update_del_display(handles,hObject);
% Update handles structure
guidata(hObject, handles);



function handles = update_del_display(handles,hObject)
del_roi_id = find(handles.valid_roi_id == 0);

if isempty(del_roi_id)
    %If nothing was selected - EXIT
%     disp('NO deleted ROIs');
    return
end


if (handles.fast_mode == 0)
    figure(gcf), axes(handles.main_axes), hold on,
    %clean del graphics
    if isfield(handles,'main_axes_del_roi_h')
        %delete previous graphical multi-choice
        del_cell = cellfun(@(x) intersect(get(gca,'Children'),x),handles.main_axes_del_roi_h,'UniformOutput',0);
        cellfun(@(y) delete(y),del_cell(~isempty(del_cell)));
        
    end
    handles.main_axes_del_roi_h = {};
    
    set(handles.main_axes_del_roi_seg_h(:),'visible','on')

    
    d1s = handles.img_dim(1);
    d2s = handles.img_dim(2);
 
    Ndel_roi = length(del_roi_id);
    %update new del graphics
    switch handles.display_mode
        case 1 %mean frame
            %plot contour
            
            for del_roi_ind = 1:Ndel_roi
                point_vec = [handles.roi_centroid_mat(:,2) handles.roi_centroid_mat(:,1)];
                idx = del_roi_id(del_roi_ind);
                %update SELECTED plot
                handles.main_axes_del_roi_h{del_roi_ind} = ...
                    plot(point_vec(idx,1),point_vec(idx,2),...
                    'marker','x',...
                    'linewidth',handles.del_line_width,...
                    'markersize',handles.deleted_marker_size,...
                    'MarkerEdgeColor', handles.del_marker_color,...
                    'MarkerFaceColor', handles.del_marker_color);
                % turn off deleted patches/segments/ROIs
                set(handles.main_axes_del_roi_seg_h(idx),'visible','off')
            end
        case 2
            for del_roi_ind = 1:Ndel_roi
                idx = find(handles.roi_id(:,handles.sort_mode) == del_roi_id(del_roi_ind));
                %update DELETED ROI plot
                Ncol = ceil(handles.Nroi/floor(handles.Nroi^.5));
                row = ceil(idx/Ncol);
                col = 1+mod(idx-1,Ncol);
                
                %update DELETED plot
                x1 = (col-1)*d2s; %x2 = col*d2s;
                y1 = (row-1)*d1s; %y2 = row*d1s;
                
                handles.main_axes_del_roi_h{del_roi_ind} = ...
                    plot(x1+handles.dx_min,y1+handles.dy_min,...
                    'marker','x',...
                    'linewidth',handles.del_line_width,...
                    'markersize',handles.deleted_marker_size,...
                    'MarkerEdgeColor', handles.del_marker_color,...
                    'MarkerFaceColor', handles.del_marker_color);

            end
        
    end
end
% Update handles structure
guidata(hObject, handles);



% --- Executes when selected object is changed in img_mode_pnl.
function img_mode_pnl_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in img_mode_pnl 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
rad_btn_sel = get(get(handles.img_mode_pnl,'SelectedObject'),'Tag');
switch rad_btn_sel
    
    case 'disp_mean_frame_radbtn'
        handles.display_mode = 1;
        handles.enable_neuron_order = 0;
        set(handles.original_order_radbtn,'enable','off');
        set(handles.sorted_order_radbtn,'enable','off');
        
    case 'disp_roi_gal_radbtn'
       handles.display_mode = 2; 
       handles.enable_neuron_order = 1;
       set(handles.original_order_radbtn,'enable','on');
       set(handles.sorted_order_radbtn,'enable','on');

end



handles = update_display(hObject, handles);

% Update handles structure
guidata(hObject, handles);


% --- Executes when selected object is changed in neu_order_pnl.
function neu_order_pnl_SelectionChangeFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in neu_order_pnl 
% eventdata  structure with the following fields (see UIBUTTONGROUP)
%	EventName: string 'SelectionChanged' (read only)
%	OldValue: handle of the previously selected object or empty if none was selected
%	NewValue: handle of the currently selected object
% handles    structure with handles and user data (see GUIDATA)
rad_btn_sel = get(get(handles.neu_order_pnl,'SelectedObject'),'Tag');
switch rad_btn_sel
    
    case 'original_order_radbtn'
        handles.sort_mode = 1;
        
    case 'sorted_order_radbtn'
       handles.sort_mode = 2;
end

handles = update_display(hObject, handles);

% Update handles structure
guidata(hObject, handles);

% --- Executes on key press with focus on figure1 or any of its controls.
function figure1_WindowKeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
key_press(hObject, eventdata, handles)
% figure1_KeyPressFcn(hObject, eventdata, handles)


function key_press(hObject, eventdata, handles)
if isempty(handles.chosen_roi_id)
    handles.chosen_roi_id = 1;
else
    chosen_roi_id = handles.chosen_roi_id(end);
    new_roi_id = chosen_roi_id;
    idx = find(handles.roi_id(:,handles.sort_mode) == chosen_roi_id);
    Nroi = handles.Nroi;
    Nroi_full = handles.Nroi_full;
    Nrow = floor(Nroi_full^.5);
    Ncol = ceil(Nroi_full/Nrow);
%     row = ceil(idx/Ncol);
%     col = 1+mod(idx-1,Ncol);

    key = lower(eventdata.Key);
    switch key
        case 'rightarrow' 
            if (handles.fast_mode == 0)
                switch handles.display_mode
                    case 1 %mean frame
                        new_roi_id = 1+mod(chosen_roi_id-1,handles.Nroi) + 1;
                    case 2
                        next_idx = 1+mod(idx-1,Nroi) + 1;
                        new_roi_id = handles.roi_id(next_idx,handles.sort_mode);
                end
            else
                idx = find(handles.roi_id(:,handles.sort_mode) == chosen_roi_id);
                next_idx = 1+mod((idx+1)-1,Nroi);
                new_roi_id = handles.roi_id(next_idx,handles.sort_mode);
            end
        case 'leftarrow'
            if (handles.fast_mode == 0)
                switch handles.display_mode
                    case 1 %mean frame
                        new_roi_id = 1+mod(chosen_roi_id(end)-1,handles.Nroi) - 1;
                    case 2
                        prev_idx = 1+mod(1+mod(idx-1,Nroi) - 1 -1,Nroi);
                        new_roi_id = handles.roi_id(prev_idx,handles.sort_mode);
                end
            else
                idx = find(handles.roi_id(:,handles.sort_mode) == chosen_roi_id);
                prev_idx = 1+mod((idx-1)-1,Nroi);
                new_roi_id = handles.roi_id(prev_idx,handles.sort_mode);
            end
        case 'uparrow'
            switch handles.display_mode
                case 1 %mean frame
                    new_roi_id = 1+mod(chosen_roi_id(end)-1,handles.Nroi) + 1;
                case 2
                    prev_idx_row = 1+mod(1+mod(idx-1,Nroi) - Ncol - 1,Nroi);
                    new_roi_id = handles.roi_id(prev_idx_row,handles.sort_mode);
            end
        case 'downarrow'
            switch handles.display_mode
                case 1 %mean frame
                    new_roi_id = 1+mod(chosen_roi_id(end)-1,handles.Nroi) - 1;
                case 2
                    next_idx_row = 1+mod(1+mod(idx-1,Nroi) + Ncol-1,Nroi);
                    new_roi_id = handles.roi_id(next_idx_row,handles.sort_mode);

            end
        case 'd'
            handles.valid_roi_id(chosen_roi_id,1) = 0;
            new_roi_id = chosen_roi_id;
        case 'u'
            handles.valid_roi_id(chosen_roi_id,1) = 1;
            new_roi_id = chosen_roi_id;
        case 'n'
            idx = find(handles.roi_id(:,handles.sort_mode) == chosen_roi_id);
            next_idx = 1+mod((idx+1)-1,Nroi);
            new_roi_id = handles.roi_id(next_idx,handles.sort_mode);
        case 'p'
            idx = find(handles.roi_id(:,handles.sort_mode) == chosen_roi_id);
            prev_idx = 1+mod((idx-1)-1,Nroi);
            new_roi_id = handles.roi_id(prev_idx,handles.sort_mode);
            
    end
    handles.chosen_roi_id = new_roi_id;   
end
% Update handles structure
guidata(hObject, handles);
%update DELETED
handles = update_del_display(handles,hObject);
%update SELECTED
handles = update_selected_display(handles, hObject);
%update ROI display
update_roi_display(handles);
% Update handles structure
guidata(hObject, handles);

% --- Executes on button press in undelete_btn.
function undelete_btn_Callback(hObject, eventdata, handles)
% hObject    handle to undelete_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
chosen_roi_id = handles.chosen_roi_id;
if isempty(chosen_roi_id)
    %If nothing was selected - EXIT
    disp('First SELECT and then un-delete ROIs');
    return
end
handles.valid_roi_id(chosen_roi_id,1) = 1;
% Update handles structure
guidata(hObject, handles);
handles = update_display(hObject, handles);
% handles = update_del_display(handles,hObject);
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in save_btn.
function save_btn_Callback(hObject, eventdata, handles)
% hObject    handle to save_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%%%6/10/2019 changes to saving: save everything to neuron struct (filename
%%%neuronFull)
% ms = handles.ms;
% ms.valid_roi = handles.valid_roi_id;
valid_roi = logical(handles.valid_roi_id);
%ms struct
disp(sprintf('ms has %d valid neurons',sum(valid_roi)));
% ms_path = fileparts(handles.ms_filename);
% ms_filename = fullfile(ms_path, 'ms.mat');
% copyfile(ms_filename,fullfile(ms_path, 'ms.old'));
% save(ms_filename,'ms');
clear ms
%neuron struct
% neuron = handles.neuron_struct;
% neuron.valid_roi = handles.valid_roi_id;
% neuron.A = neuron.A(:,valid_roi);
% neuron.C = neuron.C(valid_roi,:);
% neuron.S = neuron.S(valid_roi,:);
% neuron.C_raw = neuron.C_raw(valid_roi,:);
% disp(sprintf('neuronFull has %d valid neurons',sum(valid_roi)));
neuron_path = fileparts(handles.neuron_filename);
% neuron_filename = fullfile(neuron_path, 'neuronFull.mat');
% copyfile(neuron_filename,fullfile(neuron_path, 'neuronFull.old'));
% save(neuron_filename,'neuronFull');
valids_filename = fullfile(neuron_path, 'validROIs.mat');
save(valids_filename,'valid_roi')


set(handles.main_axes,'visible','off');
set(handles.save_btn,'visible','off');
set(handles.mouse_select_tgl,'visible','off');
% % % set(handles.select_multi_btn,'visible','on');
set(handles.img_mode_pnl,'visible','off');
set(handles.neu_order_pnl,'visible','on');
figure1_CloseRequestFcn(hObject, eventdata, handles)
uiresume(handles.figure1);

% --- Executes on button press in prev_roi_btn.
function prev_roi_btn_Callback(hObject, eventdata, handles)
% hObject    handle to prev_roi_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Nroi = handles.Nroi;
chosen_roi_id = handles.chosen_roi_id(end);
idx = find(handles.roi_id(:,handles.sort_mode) == chosen_roi_id);
prev_idx = 1+mod((idx-1)-1,Nroi);
new_roi_id = handles.roi_id(prev_idx,handles.sort_mode);
handles.chosen_roi_id = new_roi_id;
% Update handles structure
guidata(hObject, handles);

update_roi_display(handles);

% --- Executes on button press in next_roi_btn.
function next_roi_btn_Callback(hObject, eventdata, handles)
% hObject    handle to next_roi_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Nroi = handles.Nroi;
chosen_roi_id = handles.chosen_roi_id(end);
idx = find(handles.roi_id(:,handles.sort_mode) == chosen_roi_id);
next_idx = 1+mod((idx+1)-1,Nroi);
new_roi_id = handles.roi_id(next_idx,handles.sort_mode);
% new_roi_id = handles.roi_id(next_idx,handles.sort_mode);
handles.chosen_roi_id = new_roi_id;
% Update handles structure
guidata(hObject, handles);

update_roi_display(handles);

% --- Executes on button press in finish_roi_btn.
function finish_roi_btn_Callback(hObject, eventdata, handles)
% hObject    handle to finish_roi_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
set(handles.main_axes,'visible','on');
set(handles.save_btn,'visible','on');
% % % set(handles.select_multi_btn,'visible','on');
set(handles.img_mode_pnl,'visible','on');
set(handles.neu_order_pnl,'visible','on');


% Update handles structure
guidata(hObject, handles);
handles.fast_mode = 0;
handles = update_display(hObject, handles);
% Update handles structure
guidata(hObject, handles);

% --- Executes on mouse press over figure background, over a disabled or
% --- inactive control, or over an axes background.
function figure1_WindowButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
C = get (gca, 'CurrentPoint');
if handles.mouse_select == 1
    % set(handles.main_axes_select_h,'visible','off')
    if isfield(handles,'main_axes_mouse_select_h')
        %delete previous graphical multi-choice
        del_cell = cellfun(@(x) intersect(get(gca,'Children'),x),handles.main_axes_mouse_select_h,'UniformOutput',0);
        cellfun(@(y) delete(y),del_cell(~isempty(del_cell)));
        drawnow
    end
    %cleat struct
    handles.main_axes_mouse_select_h = {};
    handles.main_axes_multi_select_display_mode_h = [handles.display_mode, handles.sort_mode];
    
    handles.chosen_roi_id = [];
    
    d1s = handles.img_dim(1);
    d2s = handles.img_dim(2);
    d1l = handles.gal_dim(1);
    d2l = handles.gal_dim(2);

    figure(gcf), axes(handles.main_axes), hold on,
%     C = get (gca, 'CurrentPoint');
    mark = C(1,1:2);
    title(gca, ['(X,Y) = (', num2str(mark(1,1)), ', ',num2str(mark(1,2)), ')']);
     
    switch handles.display_mode
        case 1
            point_vec = [handles.roi_centroid_mat(:,2) handles.roi_centroid_mat(:,1)];
            idx = knnsearch(point_vec,mark);
            if any(handles.chosen_roi_id == idx)
                exist_ind = find(handles.chosen_roi_id == idx);
                delete(handles.main_axes_mouse_select_h{exist_ind});
                handles.main_axes_mouse_select_h(exist_ind) = [];
                handles.chosen_roi_id(exist_ind) = [];
            else
                handles.chosen_roi_id(1) = idx;
                %update SELECTED plot
                handles.main_axes_mouse_select_h{1} = ...
                    plot(point_vec(idx,1),point_vec(idx,2),...
                    'marker','o',...
                    'markersize',handles.selected_marker_size,...
                    'MarkerEdgeColor', handles.marker_color_edge,...
                    'MarkerFaceColor', handles.marker_color_selected);
                % Update handles structure
                guidata(hObject, handles);
            end
            
        case 2
            
            
            [x,y] = meshgrid([d2s/2:d2s:d2l],[d1s/2:d1s:d1l]);
            x = x'; y = y';
            point_vec = [x(:) y(:)];
            idx = min(knnsearch(point_vec,mark),handles.Nroi);
            if any(handles.chosen_roi_id == handles.roi_id(idx,handles.sort_mode))
                exist_ind = find(handles.chosen_roi_id == handles.roi_id(idx,handles.sort_mode));
                delete(handles.main_axes_mouse_select_h{exist_ind});
                handles.main_axes_mouse_select_h(exist_ind) = [];
                handles.chosen_roi_id(exist_ind) = [];
            else
                
                               
                Ncol = ceil(handles.Nroi/floor(handles.Nroi^.5));
                row = ceil(idx/Ncol);
                col = 1+mod(idx-1,Ncol);
                handles.chosen_roi_id(1) = handles.roi_id(idx,handles.sort_mode);
                %update SELECTED plot
                x1 = (col-1)*d2s; %x2 = col*d2s;
                y1 = (row-1)*d1s; %y2 = row*d1s;
                handles.main_axes_mouse_select_h{1} = ...
                    plot(x1+handles.dx_min,y1+handles.dy_min,...
                    'marker','o',...
                    'markersize',handles.selected_marker_size,...
                    'MarkerEdgeColor', handles.marker_color_edge,...
                    'MarkerFaceColor', handles.marker_color_selected);
                % Update handles structure
                guidata(hObject, handles);
                    
            end
    end
    drawnow()
    % Update handles structure
    guidata(hObject, handles);
    
    update_roi_display(handles);
    % Update handles structure
    guidata(hObject, handles);

end

% --- Executes on button press in first_roi_btn.
function first_roi_btn_Callback(hObject, eventdata, handles)
% hObject    handle to first_roi_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
new_roi_id = handles.roi_id(1,handles.sort_mode);
% new_roi_id = handles.roi_id(next_idx,handles.sort_mode);
handles.chosen_roi_id = new_roi_id;
% Update handles structure
guidata(hObject, handles);

update_roi_display(handles);


% --- Executes on button press in last_roi_btn.
function last_roi_btn_Callback(hObject, eventdata, handles)
% hObject    handle to last_roi_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
Nroi = handles.Nroi;
new_roi_id = handles.roi_id(Nroi,handles.sort_mode);
% new_roi_id = handles.roi_id(next_idx,handles.sort_mode);
handles.chosen_roi_id = new_roi_id;
% Update handles structure
guidata(hObject, handles);

update_roi_display(handles);


% --- Executes on button press in mouse_select_tgl.
function mouse_select_tgl_Callback(hObject, eventdata, handles)
% hObject    handle to mouse_select_tgl (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of mouse_select_tgl
mouse_select = get(hObject,'Value');
if mouse_select == 1
    handles.mouse_select = 1;
else
    handles.mouse_select = 0;
    
end
 % Update handles structure
guidata(hObject, handles);   

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

delete(hObject);

% --- Executes on button press in make_roi_vid.
function make_roi_vid_Callback(hObject, eventdata, handles)
% hObject    handle to make_roi_vid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


%%%% By defining a specific window and specific timepoint
% handles.get_timePoint_flag = 1;
% guidata(hObject, handles); 
% %prompt user to define time point
% axes(handles.ca_clean_trace_axes)
% [time_point,~]=ginput(1); %place a pop up window 
% time_point = floor(time_point*handles.video_fps);
% figure(gcf), axes(handles.roi_axes), cla
% 
% %generate ROI video
% idx=handles.chosen_roi_id;
% roi_x = handles.roi_centroid_mat(idx,2);
% roi_y = handles.roi_centroid_mat(idx,1);
% half_width = handles.ROI_vid_half_width;
% half_height = handles.ROI_vid_half_height;
% half_time = handles.ROI_vid_half_frame_duration;
% 
% x_idx = roi_x - half_width:roi_x + half_width;
% y_idx = roi_y - half_height:roi_y + half_height;
% t_idx = time_point - half_time:time_point + half_time;
% % handles.ROI_video = handles.video_mat(y_idx,x_idx,t_idx);
% handles.ROI_video = readFrame(handles.videoObj);
% handles.ROI_video = handles.ROI_video(y_idx,x_idx);
% 
% %Plot 1st frame ROI video in roi_axes
% axes(handles.roi_axes)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% Generating video
fps=handles.video_fps;
fps_factor=handles.vid_fps_factor;%fast play option (1 = normal speed)

idx=handles.chosen_roi_id;
videofig(handles.videoObj.NumberOfFrames, @(frm) redraw(frm, handles.videoObj,idx,handles,fps),floor(fps*fps_factor));
redraw(1, handles.videoObj,idx,handles,fps);



% Update handles structure
guidata(hObject, handles); 
update_roi_display(handles);

handles.get_timePoint_flag = 0;
guidata(hObject, handles); 

%%% Draw video
function redraw(frame,videoObj,idx,handles,fps)
    tmp=videoObj.read(frame);
    imshow(tmp)
    patch_vdata_cell = handles.patch_vdata_cell;
    patch_vdata = patch_vdata_cell{idx};
    text(size(tmp,2),size(tmp,1),['Time in seconds = ' num2str((round((frame/fps)*100))/100)],...
        'color',[1 1 1],'fontsize',16,'verticalalignment','bottom','horizontalalignment','right')
    %plot patch
    handles.main_axes_del_roi_seg_h(idx) = ...
        patch('Faces',1:size(patch_vdata',1),'Vertices',patch_vdata',...
        'FaceColor',handles.seg_color,'FaceAlpha',0,...        
        'EdgeColor',handles.seg_color);
    if (handles.valid_roi_id(idx) == 0)
        set(handles.main_axes_del_roi_seg_h(idx),'visible','off');
    end


% --- Executes on mouse press over axes background.
function main_axes_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to main_axes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    
% --- Executes on key press with focus on figure1 and none of its controls.
function figure1_KeyPressFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see FIGURE)
%	Key: name of the key that was pressed, in lower case
%	Character: character interpretation of the key(s) that was pressed
%	Modifier: name(s) of the modifier key(s) (i.e., control, shift) pressed
% handles    structure with handles and user data (see GUIDATA)
% key_press(hObject, eventdata, handles)

% --- Executes on mouse press over figure background.
function figure1_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% % % disp('figure down')

% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in play_pause_btn.
function play_pause_btn_Callback(hObject, eventdata, handles)
% hObject    handle to play_pause_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of play_pause_btn


% --- Executes on button press in vid_repeat_btn.
function vid_repeat_btn_Callback(hObject, eventdata, handles)
% hObject    handle to vid_repeat_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of vid_repeat_btn


% --- Executes on button press in vid_prev_frame_btn.
function vid_prev_frame_btn_Callback(hObject, eventdata, handles)
% hObject    handle to vid_prev_frame_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in vid_next_frame_btn.
function vid_next_frame_btn_Callback(hObject, eventdata, handles)
% hObject    handle to vid_next_frame_btn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in disp_roi_vid_radbtn.
function disp_roi_vid_radbtn_Callback(hObject, eventdata, handles)
% hObject    handle to disp_roi_vid_radbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of disp_roi_vid_radbtn


% --- Executes on button press in disp_roi_gal_radbtn.
function disp_roi_gal_radbtn_Callback(hObject, eventdata, handles)
% hObject    handle to disp_roi_gal_radbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of disp_roi_gal_radbtn


% --- Executes during object deletion, before destroying properties.
function disp_roi_vid_radbtn_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to disp_roi_vid_radbtn (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
