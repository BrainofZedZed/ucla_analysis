
% Uses Matlab's built in video player (implay) to view and log timepoints
% through keyboard short cuts
% ​
% Script requires the Image Processing Toolbox to be installed
% ​
% Note: The Video Controller window must be selected to function
% ​
% Play: Space Bar
% Skip X frames forward: Right Arrow
% Skip X frames backwards: Left Aarrow
% Increase X frames for skipping: Up Arrow
% Decrease X frames for skipping: Down Arrow
% ​
% Keys 1 - 5 will log a timepoint into a unique array corresponding to the
% key. Ex of usage: Press 1 every trial start, 2 every trial end, 3 for a
% behavioral timepoint of interest during trial, etc.
% ​
% SHIFT + Keys 1 - 5: Will remove last timepoint recorded in that key-type
% ​
% CTRL + E: Export current set of timepoints as an excel file
% ​
% Aarron Phensy - Sohal Lab - November 2021
%Initiates Program by requesting user to load a video 



filterSpec = getFilterSpec(VideoReader.getFileFormats());
[file,path] = uigetfile(filterSpec);
%Loads video with default MATLAB Player (requires Image Processing Toolbox)
testVid = implay([path file]);
testVid.Parent.Position = [100 100 800 800];
controls = testVid.DataSource.Controls;
%Take manual control over implay
%Create the GUI Video Controller
vcFig = uifigure('Name','Video Controller'); %Primary container
vcFig.Position = [1000 500 600 200]; %Set Size of Video Controller GUI

%Initiate UI User Data - this cell matrix will contain all of the dynamic
%info. 1 - 5 key arrays are defined
vcFig.UserData{1,1} = 80; %Default FF/Rewind # frames / skip
vcFig.UserData{2,1} = '1'; %start
vcFig.UserData{3,1} = '2'; %choice
vcFig.UserData{4,1} = '3'; %vte?
vcFig.UserData{5,1} = '4'; %Bjump
vcFig.UserData{6,1} = '5'; %noB
vcFig.UserData{7,1} = '6'; %HVR
vcFig.UserData{8,1} = '7'; %LVR
vcFig.UserData{9,1} = '8'; %LED ON
vcFig.UserData{2,2} = double.empty();

%Create GUI components in vcFig
txt = sprintf('1 : *0 : \n2 : *0 : \n3 : *0 : \n4 : *0 : \n5 : *0 : \n6 : *0 : \n7 : *0 : \n8 : *0 : ');
uitextarea(vcFig,'Value',txt,'Position',[50 50 400 100],'Editable','off','Tag','TimeText');
uilabel(vcFig,'Text',sprintf('Frame-Skip Rate: %d',vcFig.UserData{1,1}),'Position',[50 150 200 50],'Tag','SkipLbl');

%Finally set a keyboard listener to vcFig to give user control over implay
set(vcFig,'KeyPressFcn',{@controlListener,controls});



function controlListener(src,event,ctrl)
    
   skframes = src.UserData{1,1}; %Grabs the current # frames / skip
      
   if isempty(event.Modifier) %No modifying key is pressed (shift, ctrl, etc)
       switch event.Key
           case 'space'
               ctrl.playPause;
           case 'rightarrow'
               ctrl.fFwd(skframes);
           case 'leftarrow'
               ctrl.rewind(skframes);
           case 'uparrow'
               src.UserData{1,1} = skframes *2;
           case 'downarrow'
               if skframes <= 1 %Minimum #skip frames is 5
                   src.UserData{1,1} = 1;
               else
                   src.UserData{1,1} = floor(skframes / 2);
               end
           
           %User adds frame # to specific key-array
           case '1'
               src.UserData{2,2}(end+1) = ctrl.CurrentFrame;
           case '2'
               src.UserData{3,2}(end+1) = ctrl.CurrentFrame;
           case '3'
               src.UserData{4,2}(end+1) = ctrl.CurrentFrame;
           case '4'
               src.UserData{5,2}(end+1) = ctrl.CurrentFrame;
           case '5'
               src.UserData{6,2}(end+1) = ctrl.CurrentFrame;
           case '6'
               src.UserData{7,2}(end+1) = ctrl.CurrentFrame;
           case '7'
               src.UserData{8,2}(end+1) = ctrl.CurrentFrame;
           case '8'
               src.UserData{9,2}(end+1) = ctrl.CurrentFrame;
           otherwise
           
       end
       
   elseif strcmp(event.Modifier{:},'shift') %Shift is held with key
       
       %Shift + Key # deletes latest entry
       switch event.Key
           case '1' 
               src.UserData{2,2}(end) = [];
           case '2'
               src.UserData{3,2}(end) = [];
           case '3'
               src.UserData{4,2}(end) = [];
           case '4'
               src.UserData{5,2}(end) = [];
           case '5'
               src.UserData{6,2}(end) = [];
           case '6'
               src.UserData{7,2}(end) = [];
           case '7'
               src.UserData{8,2}(end) = [];
           case '8'
               src.UserData{9,2}(end) = [];
           otherwise
       end
       
   elseif strcmp(event.Modifier{:},'control') %Ctrl is held with key
       
       %Ctrl + e exports data to an excel file
       switch event.Key
           case 'e' 
               
               %Converts User Data format to a evenly sized double matrix
               t=src.UserData{2,2};
               for i=2:size(src.UserData,1)-1
                   row = src.UserData{i+1,2};
                   t = [t, NaN(size(t,1), max(length(t),length(row))-length(t))];
                   row = [row, NaN(size(row,1), max(length(row),length(t))-length(row))];
                   t = [t;row];
               end
               
               %Prepare a unique default file name
               defFileName = sprintf('videxp%s.xlsx',datestr(now,'mmddyy-HHMMSS'));
               
               %Have user select location and save
               [f,p] = uiputfile(defFileName);
               writematrix(t,[p f]);
               
           otherwise
       end
   end
   
   %Update text field content based on current timepoint data
   txt = '';
   for i=2:size(src.UserData,1)
       if size(src.UserData{i,2},2) < 10
           txt = [txt,sprintf('%d : *%d : %s\n',i-1,size(src.UserData{i,2},2),num2str(src.UserData{i,2}))];
       else
           txt = [txt,sprintf('%d : *%d : ... %s\n',i-1,size(src.UserData{i,2},2),num2str(src.UserData{i,2} (end-9:end)))];
       end
   end
      
   %Update GUI
   chldrn = get(src,'Children');
   for i=1:length(chldrn)
       if strcmp(chldrn(i,1).Tag,'TimeText')
           chldrn(i,1).Value = txt;
       end
       if strcmp(chldrn(i,1).Tag,'SkipLbl')
           chldrn(i,1).Text = sprintf('Frame-Skip Rate: %d',src.UserData{1,1});
       end
   end
   
   refresh(src); %refreshes figure
   
end


%Call help matlabshared.scopes.source.PlaybackControlsTimer
%CurrentFrameNumber = testVid.DataSource.Controls.CurrentFrame
%delete(get(temp,'Children'));
%refresh(temp);