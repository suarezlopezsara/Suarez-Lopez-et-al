//This macro was created to measure GluA1 fluorescence intensity in Shank2 positive areas


//Classic for image opening
input_path = getDirectory("folder with input images");
output_path = getDirectory("folder where OP are saved");print(output_path);
file_list = getFileList(input_path);

for(i = 0; i < file_list.length; i++) {print(file_list[i]);
	if (endsWith(file_list[i], ".czi")) {

	   	
	   	run("Bio-Formats Importer", "open=" + input_path + file_list[i] +" autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");	
		title=getTitle();
		title_wo_ext = substring(title, 0, lengthOf(title)-4);	
	    image_id = getImageID();
	    
	    run("Close All");
	    
	    open(input_path + title_wo_ext + "_Projected_image.tif");
	    run("Split Channels");
	    
//Rename each channel as the corresponding protein signal	
	    selectWindow("C1-" + title_wo_ext + "_Projected_image.tif");
	    rename(title_wo_ext + "_GluA1");
	    run("Duplicate...", " ");
	    rename(title_wo_ext + "_GluA1_2");
	    selectWindow("C3-" + title_wo_ext + "_Projected_image.tif");
	    rename(title_wo_ext + "_Shank2");
//Open a binary mask to outline the dendrite ROI
	    open(input_path + title_wo_ext + "_Spines_segmented_2D.tif");
	    setTool("wand");
	    
		waitForUser;
		
		roiManager("Add");
		
		
		selectWindow(title_wo_ext + "_Shank2");
		run("Duplicate...", " ");
		run("Enhance Contrast", "saturated=0.35");
		selectWindow(title_wo_ext + "_Shank2");
		run("Threshold...");
		//Adapt threshold to account for differences in fluorescence intensity
		waitForUser;

		run("Convert to Mask");
		run("Watershed");
		//Delete Shank2 signal outside the dendrite
		roiManager("Select", 0);
		run("Clear Outside");
		roiManager("reset");
		run("Analyze Particles...", "size=0.01-0.90 add composite");
		
		save(output_path + title_wo_ext + "_Shank2_mask.tif");
		selectWindow(title_wo_ext + "_GluA1_2");
		run("Subtract Background...", "rolling=50");
		roiManager("Select All");
		roiManager("Measure");
		save_name = output_path + title_wo_ext + "_Shank2.zip";	print(save_name);
		roiManager("Save", save_name);
		
		roiManager("reset");
		run("Close All");
	}
}
		
		
		
		
