# Analysis Pipeline Manual
<div align="right">Aharoni Lab</div><br>

## Requirements:
  * [CaImAn Package](https://github.com/flatironinstitute/CaImAn) with Python for CNMF
  * [OASIS Package](https://github.com/j-friedrich/OASIS) with Python for deconvolution
  * [`Analysis_Pipeline-CaImAn.ipynb`](https://github.com/Aharoni-Lab/Miniscope-Analysis-Pipeline) Jupyter Notebook for running CaImAn on your data
  * [`Analysis_Pipeline-OASIS.ipynb`](https://github.com/Aharoni-Lab/Miniscope-Analysis-Pipeline) Jupyter Notebook for running OASIS on your data
## Steps:
1. Download and install all packages according to the installation guides on their respective Github. For CaImAn, I used the [Conda installer](https://caiman.readthedocs.io/en/master/Installation.html#package-based-process). Make sure the demo files run (`demo_pipeline_cnmfE.ipynb` for CaImAn, `Demo.ipynb` for OASIS). (I recall running into difficulties [setting up caimanmanager](https://caiman.readthedocs.io/en/master/Installation.html#setting-up-caimanmanager). You may skip this if you have neural recording data since you may just run the data through `Analysis_Pipeline-CaImAn.ipynb`)<br>
<!---
2. (Optional) Run NormCorre to generate the motion-corrected video. 
    * Either write and run your own script with the NormCorre functions, or ...
    * You can run demo_1p.m or demo_1p.mlx, but you must modify them a bit to concatenate raw videos and save the motion corrected video result.<br>
        * To concatenate the raw videos, replace the **"download data and convert to single prevision"** section with:
            ```
            name = {'list.avi', 'of.avi', 'videos.avi'};

            Yf = read_file(name{1});
            for i = 2:length(name)
                Yf =cat(3, Yf, read_file(name{i}));
            end

            Yf = single(Yf);
            [d1,d2,T] = size(Yf);
            ```
        * Add the following lines at the end of the script to save the motion corrected video:
            ```
            % Save the motion corrected video
            
            VidObj = VideoWriter('video_name.avi', 'Uncompressed AVI');  % Set your file name and video compression
            VidObj.FrameRate = 15;  % Set your frame rate
            open(VidObj);

            % For piecewise-correction:
            % for f = 1:size(Mpr, 3)

            % For rigid-correction:
            for f = 1:size(Mr, 3)
                writeVideo(VidObj, mat2gray(Mr(:,:,f)));
            end
            
            close(VidObj);
            ```
    #####  - In my personal experience, the rigid shift performs almost as well as the piecewise shift, with a much shorter computation time.
    #####  - There is a memory issue, which has to be solved via memory mapping. Work in progress.
    #####  - If you cannot motion correct all videos at once, do it in smaller chunks. We can try to concatenate motion corrected videos in the next section.
--->
2. Activate the CaImAn Conda environment and open `Analysis_Pipeline-CaImAn.ipynb`. If you followed the Conda installation guide, this Jupyter Notebook does not necessarily have to sit inside the CaImAn folder. So, for ease of use, you can put it in the same directory as `Analysis_Pipeline-OASIS.ipynb`. Now, look inside `Analysis_Pipeline-CaImAn.ipynb`.
    * **"Select file(s) to be processed"** section:
        * Enter the list of the paths to the videos. Keep it chronological.
    * **"Set up some parameters"** section:
        * Set the motion correction step parameters. These depend on each video. I tried to set *use_cuda=True* flag to use the GPU for speed, but have not been successful yet after a few days of debugging.
        * The following at the end of the cell allows you to view all the motion correction parameters:
            ```python
            for k, v in opts.motion.items():
            print(k, ":", v)
            ```
    * **"Parameter setting for CNMF-E"** section:
        * Set p=2
        * The output in this cell is where you can see all the parameters. You may change them with:
            ```python
            opts.change_params(params_dict={'key1': val1, 'key2': val2, ... , 'key_n': val_n})
            ```
    * **"Component evaluation"** section:
        * You can manipulate min_SNR and r_values_min to filter out cells with subpar temporal/spatial signal quality.
    * **Save the demixed cells' raw traces**:
        * The deconvolution step in CaImAn performs quite poorly, and lacks room for quick parameter adjustments. To circumvent this, we instead grab the raw trace of each demixed cell that CNMF spotted and run it through a seperate OASIS package.
        * The **"Save raw traces"** cell following the **"Stop cluster"** section saves the raw traces of all the cells that passed the spatial/temporal filters set in the **"Component evaluation"** section. It also saves the entire `cnm.estimates` object for recovering the actual cell indices later on.

3. Open `Analysis_Pipeline-OASIS.ipynb`.
    * Follow the instructions on the Jupyter Notebook.
        * In step 1, (**"Import All Libraries"**) make sure to set the `path.append('path/to/OASIS')` to be able to run OASIS from this notebook. 
    * This notebook takes in the `raw_fluorescence.obj` file generated from `Analysis_Pipeline-OASIS.ipynb`.
    * It has pre-optimized a few parameters, such as using l1-norm sparsity constraint, and modeling with AR(2) autoregressive process. If you want to find out why I fixed on to these values, look at [Deconvolution Tests.ipynb](https://github.com/Aharoni-Lab/Miniscope-Analysis-Pipeline).
    * However, it steps the user through determining one critical parameter, g. The parameter g is related to the rise and the decay time of the fluorescence. It generates a few constraints for the g's so that deconvolution will work effectively, and allows the user to choose what g value they see fit within these constraints.
    * It should output a Pandas dataframe containing deconvolved information of the cells, including the cell ID, the raw trace, the denoised trace, the deconvolved trace, the deconvolution paramters, etc.
4. Run neural activity analysis in combination with the behavioral data.
5. The cell indices from `Analysis_Pipeline-OASIS.ipynb` can eventually be matched with the original cell indices generated in `Analysis-Pipeline-CaImAn.ipynb` once you load `estimates.obj` and look at `cnm.estimates.idx_components`.