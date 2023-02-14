# vvvvv EDIT THIS LINE HERE VVVVVVV
path = r"C:\Users\Zach\Desktop\ms_vid_concat_test"  # define path to directory above any My_V4_Miniscope dirs you want to concat
# ^^^^^ EDIT THIS LINE HERE ^^^^^^ and then run

#%%  imports
import glob  # used to search for files
import ntpath # alternative to os.path that is OS agnostic
import natsort # for function natsorted

#%%  create output
path_wc = path + "\**\My_V4_Miniscope" # add search area:  ** indicates any number of subdir
cam_dirs = glob.glob(path_wc, recursive = True) # get all subdirectories with My_WebCam

# for each cam_dir, get list of all avi files
out_full = ''  # initialize final output 
final_out = ''
for j in range(len(cam_dirs)):  # loop through each dir
    i_dir = cam_dirs[j]
    avi_files = glob.glob(i_dir + "/*.avi")  # go through dir and get paths of all avi files
    
    filenames = [None] * len(avi_files)  # create an empty list of size avi_files
    for i in range(len(avi_files)):  # loop through the size of avi_files
        if len(ntpath.basename(avi_files[i])) > 6:
            continue
        filenames[i] = ntpath.basename(avi_files[i])  # assign filename to new list
        
    filenames_sorted = natsort.natsorted(filenames) # natural language sort
    out_cat = ''  # initialize out string
    
    for x in filenames_sorted:
        out_cat = out_cat + x + '|'  # create string with bar between all names
    
    out_cat = out_cat[:-1] # remove last bar
    out_cat = 'ffmpeg -i "concat:' + out_cat + '"' + ' -c copy temp.avi \nffmpeg -i temp.avi -c:v libx264 -preset fast -crf 17 -c:a copy concat_ms.avi\n'  # put into ffmpeg command
    cd_line = 'cd ' + "\"" + i_dir + "\"" + '\n'
    del_line1 = 'del /f concat_ms.avi\n'
    del_line2 = 'del /f temp.avi\n\n'
    label_line = 'ffmpeg -i concat_ms.avi -vf "drawtext=fontfile=Arial.ttf: text=\'%{frame_num}\': start_number=1: x=(w-tw)/2: y=h-(2*lh): fontcolor=black: fontsize=18: box=1: boxcolor=white: boxborderw=5" -vcodec libx264 -preset fast -crf 17 -c:a copy concat_ms_labelled.avi\n'
    out_full = cd_line + out_cat + label_line + del_line1 + del_line2
    final_out = final_out+out_full
    
#%% save
with open('concat_and_label_ms_vids.txt', 'w') as f:
    f.write(final_out)
