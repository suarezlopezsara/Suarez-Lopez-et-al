//This macro measures the Shank2 area in mushroom spine ROIs, using a sub-stack .tif file generated with the dendrite segmentation macro
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
	    
	    selectWindow("C3-" + title_wo_ext + "_Projected_image.tif");
	    rename(title_wo_ext + "GFP");
	    
	    selectWindow("C4-" + title_wo_ext + "_Projected_image.tif");
	    rename("Shank2");
	    run("Duplicate...", " ");
	    rename("Shank2_2");
	    //Open a previously generated ROI file with the spines that were analyzed by the SpineCounter Fiji PlugIn, to identify which ones are the mushroom spines
	    roiManager("open", input_path + title_wo_ext + ".zip");
	    selectWindow(title_wo_ext + "GFP");
	    roiManager("show all");
	    //Manually outline each mushroom spine and add each ROI to the ROI manager. Once finished combine all ROIs into one
	    waitForUser;
	    
	    save_name = output_path + title_wo_ext + "_Spines.zip";	print(save_name);
		roiManager("Save", save_name);
	    selectWindow("Shank2");
	    run("Duplicate...", " ");
	    //Enhance contrast in the duplicated image to better visualize Shank2 signal
	    run("Enhance Contrast", "saturated=0.35");
	    //Threshold the non modifyed image
		selectWindow("Shank2");
		run("Threshold...");
		waitForUser;
	    //Convert all shank2 positive areas into a mask
	    run("Convert to Mask");
		run("Watershed");
		//selec the mushroom spines and clear everything outside to obtained only Shank2 signal inside spines
		roiManager("Select", 0);
		run("Clear Outside");
		roiManager("reset");
		run("Analyze Particles...", "size=0.01-0.90 add composite");
		
		save_name = output_path + title_wo_ext + "_Shank2.zip";	print(save_name);
		roiManager("Save", save_name);
		
		selectWindow("Shank2_2");
		roiManager("Select All");
		roiManager("Measure");
		waitForUser;

		roiManager("reset");
		run("Close All");
	}
}
		
		
	    