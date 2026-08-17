//This macro measures GluA1 fluorescence intensity inside a dendrite ROI

//First the thing to get the file path for imput and output images

input_path = getDirectory("folder with input images");
output_path = getDirectory("folder where OP are saved");print(output_path);
file_list = getFileList(input_path);


for(i = 0; i < file_list.length; i++) {print(file_list[i]);
	if (endsWith(file_list[i], ".czi")) {

	   	
	   	run("Bio-Formats Importer", "open=" + input_path + file_list[i] +" autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");	
		title=getTitle();
		title_wo_ext = substring(title, 0, lengthOf(title)-4);	
	    image_id = getImageID();
	  
//Open the segmented dendrite obtained by Dendrite segmentation macro		
	    open(input_path + title_wo_ext + "_Spines_segmented_2D.tif");
	    rename("Shaft");
	
		//Add the dendrite area to the roiManager to generate the dendrite mask
		setTool("wand");
		waitForUser;
		roiManager("Add");
		roiManager("Select", 0);
		roiManager("Rename", title_wo_ext + "_Shaft");
		close("Shaft");
	
	//Open the sub-stack file generated with the dendrite segmentation macro
	 	open(input_path + title_wo_ext + "_Projected_image.tif");
	    rename("Channel");
	    run("Split Channels");
	    //Selec the channel correspondign to GluA1 signal
	    selectImage("C1-Channel");
	    run("Subtract Background...", "rolling=50");
	    
	    roiManager("Select", 0);
	    
	    run("Measure");
	    
	    roiManager("reset");
		
		run("Close All");

	}
}