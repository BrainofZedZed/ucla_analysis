// ImageJ Macro for adding specific slices from multiple TIFF files
// Processes multiple slice numbers and saves each summed result

// D28 file paths
file1 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ212\\deeptrace_analysis\\240509_ZZ212_488_11-07-21\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
file2 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ213\\deeptrace_analysis\\240509_ZZ213_488_13-10-03\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
file3 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ251\\deeptrace_analysis\\240829_ZZ251_08x_488_09-15-59\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
file4 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ252\\deeptrace_analysis\\240829_ZZ252_08x_488_12-17-11\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";

// D1 file paths
//file1 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ217\\deeptrace_analysis\\240510_ZZ217_488_10-57-10\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
//file2 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ218\\deeptrace_analysis\\240510_ZZ218_488_13-24-29\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
//file3 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ219\\deeptrace_analysis\\240510_ZZ219_488_15-31-43\\refined_model___weights001_nb8_st3_at15.tiff";
//file4 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ254\\deeptrace_analysis\\240829_ZZ254_08x_488_10-45-30\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff"";


// PLTeA File paths
//file1 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ216B\\deeptrace_analysis\\240510_ZZ216B_488_08-50-04\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
//file2 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ215\\deeptrace_analysis\\240509_ZZ215_488_15-10-53\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
//file3 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ293\\deeptrace_analysis\\241111_ZZ293_08x_488_09-48-51\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";
//file4 = "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\ZZ294\\deeptrace_analysis\\241111_ZZ294_08x_488_11-38-16\\refined_model__zz_axon_20240708_nb8_st3_at15.tiff";

// Array of slice numbers to process
sliceNumbers = newArray(351, 600, 880, 900);

// Process each slice number
for (s = 0; s < sliceNumbers.length; s++) {
    currentSlice = sliceNumbers[s];
    
    // Open and process first file
    open(file1);
    run("Reslice [/]...");
    setSlice(currentSlice);
    run("Duplicate...", "title=sum");

    // Process second file
    open(file2);
    run("Reslice [/]...");
    setSlice(currentSlice);
    run("Duplicate...", "title=temp");
    imageCalculator("Add create", "sum","temp");
    selectWindow("temp");
    close();
    selectWindow("Result of sum");
    rename("sum");

    // Process third file
    open(file3);
    run("Reslice [/]...");
    setSlice(currentSlice);
    run("Duplicate...", "title=temp");
    imageCalculator("Add create", "sum","temp");
    selectWindow("temp");
    close();
    selectWindow("Result of sum");
    rename("sum");

    // Process fourth file
    open(file4);
    run("Reslice [/]...");
    setSlice(currentSlice);
    run("Duplicate...", "title=temp");
    imageCalculator("Add create", "sum","temp");
    selectWindow("temp");
    close();
    selectWindow("Result of sum");
    rename("sum");

    // Save result with slice number in filename
    selectWindow("sum");
    saveAs("Tiff", "C:\\Users\\boba4\\Box\\Zach_repo\\Projects\\Remote_memory\\PL-TeA wholebrain\\batch\\d28\\images\\summed_matrix_slice" + currentSlice + ".tif");

    // Clean up before processing next slice
    run("Close All");
}