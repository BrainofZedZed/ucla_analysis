import imagej
import numpy as np
from pathlib import Path

def process_tiff_files(file_paths, slice_number, output_path):
    # Start an ImageJ instance
    ij = imagej.init()  # Assumes FIJI is installed and accessible

    # Initialize a list to store slice pixel values from all files
    slices = []

    for file_path in file_paths:
        # Open the TIFF file
        imp = ij.io().open(str(file_path))

        # Reslice with default parameters
        ij.py.run_macro("Reslice [/]", imp)
        resliced = ij.py.run_macro("run(\"Reslice\");", imp)

        # Convert the result to a NumPy array
        resliced_np = ij.py.to_numpy(resliced.getImage())

        # Extract the desired slice (adjusting for zero-based indexing)
        if slice_number < 1 or slice_number > resliced_np.shape[0]:
            raise ValueError(f"Slice number {slice_number} is out of range for file: {file_path}")
        slice_data = resliced_np[slice_number - 1, :, :]

        slices.append(slice_data)

    # Sum the matrices
    summed_matrix = np.sum(slices, axis=0)

    # Save the summed matrix as a TIFF file
    output_file = Path(output_path) / "summed_matrix.tif"
    ij.io().save(ij.dataset().create(summed_matrix), str(output_file))

    # Display the summed matrix
    print("Summed matrix:")
    print(summed_matrix)
    print(f"Saved summed matrix to: {output_file}")

# Define inputs
file_paths = [
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ216B\deeptrace_analysis\240510_ZZ216B_488_08-50-04\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ215\deeptrace_analysis\240509_ZZ215_488_15-10-53\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ293\deeptrace_analysis\241111_ZZ293_08x_488_09-48-51\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
    "C:\Users\boba4\Box\Zach_repo\Projects\Remote_memory\PL-TeA wholebrain\ZZ294\deeptrace_analysis\241111_ZZ294_08x_488_11-38-16\refined_model__zz_axon_20240708_nb8_st3_at15.tiff",
]
slice_number = 5  # Replace with your slice number
output_path = "/path/to/output"  # Replace with your desired output directory

# Run the processing function
process_tiff_files(file_paths, slice_number, output_path)
