D:
cd D:\miniscope_cohort2\data\D0\ZZ072\My_WebCam\
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi|31.avi|32.avi|33.avi|34.avi|35.avi|36.avi|37.avi|38.avi|39.avi|40.avi|41.avi|42.avi|43.avi|44.avi" -c copy temp.mp4 
ffmpeg -i temp.mp4 -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.mp4 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D0\ZZ073\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi|31.avi|32.avi|33.avi|34.avi|35.avi|36.avi|37.avi|38.avi|39.avi|40.avi|41.avi|concat_behavior.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D0\ZZ074_NS\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi|31.avi|32.avi|33.avi|34.avi|35.avi|36.avi|37.avi|38.avi|39.avi|40.avi|41.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D1_same\ZZ072\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D1_same\ZZ073\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D1_same\ZZ074_NS\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D28_alt\ZZ072_D28_alt\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi|31.avi|32.avi|33.avi|34.avi|35.avi|36.avi|37.avi|38.avi|39.avi|40.avi|41.avi|42.avi|43.avi|44.avi|45.avi|46.avi|47.avi|48.avi|ZZ072_D28_alt_beh.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D28_alt\ZZ073_D30_altredo\ZZ073_D30_altredo\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi|31.avi|32.avi|33.avi|34.avi|35.avi|36.avi|37.avi|38.avi|39.avi|40.avi|41.avi|42.avi|43.avi|44.avi|45.avi|46.avi|47.avi|48.avi|49.avi|50.avi|51.avi|52.avi|ZZ073_D30_altredo_beh.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D28_alt\ZZ074_NS_D28_alt\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi|31.avi|32.avi|33.avi|34.avi|35.avi|36.avi|37.avi|38.avi|39.avi|40.avi|ZZ074_D28_alt_beh.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D29_same\ZZ072\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi|31.avi|32.avi|33.avi|34.avi|35.avi|36.avi|37.avi|38.avi|39.avi|40.avi|41.avi|42.avi|43.avi|ZZ072_D29_same_beh.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D29_same\ZZ073\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi|31.avi|32.avi|33.avi|34.avi|35.avi|36.avi|37.avi|38.avi|39.avi|40.avi|41.avi|42.avi|43.avi|44.avi|45.avi|ZZ073_D29_same_beh.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D29_same\ZZ074_NS\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi|30.avi|31.avi|32.avi|33.avi|34.avi|35.avi|36.avi|37.avi|38.avi|39.avi|40.avi|ZZ072_D29_same_beh.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D2_alt\ZZ072\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D2_alt\ZZ073\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi|29.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi

D:
cd D:\miniscope_cohort2\data\D2_alt\ZZ074_NS\My_WebCam
ffmpeg -i "concat:0.avi|1.avi|2.avi|3.avi|4.avi|5.avi|6.avi|7.avi|8.avi|9.avi|10.avi|11.avi|12.avi|13.avi|14.avi|15.avi|16.avi|17.avi|18.avi|19.avi|20.avi|21.avi|22.avi|23.avi|24.avi|25.avi|26.avi|27.avi|28.avi" -c copy temp.avi 
ffmpeg -i temp.avi -c:v libx264 -preset slow -crf 17 -c:a copy concat_beh.avi 
del /f temp.avi