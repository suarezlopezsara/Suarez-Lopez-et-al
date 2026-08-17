//// -- This macro is to analyze spine and total protrusion density based on previously segmented images


/* First we create a control panel where the User can identify the previously acquired images.
 *  Then we create a composite images
 *  Then we analyse the image in the ROIs given by the user.
 */

setForegroundColor(255, 255, 255);			// Here we just make sure that the foreground and background colors are set right before we do anything.
setBackgroundColor(0, 0, 0);

Dialog.create("Control panel");

Dialog.addMessage("This Macro is created to analyze spine density in images with dendritic and PSD signal.\nPlease make sure that your images have corresponding .zip ROI files with identical names!");

Dialog.addMessage("Image type information", 16, 'black');
Dialog.addMessage("Your images and ROIs will be identified based on the provided postfixes");

Dialog.addString("Original Image postfix (with extension)", ".czi", 10);								// FIRST STRING IS THE ORIGINAL IMAGE POSTFIX

Dialog.addString("Segmented spines image postfix (with extension)", "_Spines_segmented_2D.tif", 30);	// SECOND STRING IS THE SEGMENTED SPINES IMAGE POSTFIX
Dialog.addString("Segmented PSD spots image postfix (with extension)", "_PSD_segmented_2D.tif", 30);	// THIRD STRING IS THE PSD SPOTS IMAGE POSTFIX

Dialog.addString("ROI postfix (with extension)", ".zip", 10);											// FOURTH STRING IS THE ROI POSTFIX



Dialog.addMessage("Size filtering information", 16, 'black');
Dialog.addMessage("Spines will be size-filtered according to the provided values");


Dialog.addNumber("Spine area minimum [micron^2]", 0.1);			// SIXTH NUMBER IS THE PERCENTILE BOTTOM
Dialog.addNumber("Spine area maximum [micron^2]", 5);			// SEVENTH NUMBER IS THE PERCENTILE TOP
Dialog.addNumber("PSD area minimum [micron^2]", 0.01);			// SEVENTH NUMBER IS THE PERCENTILE TOP



Dialog.addMessage("Ilastik settings", 16, 'black');
Dialog.addMessage("Add the number of label which corresponds to the different structures.");


Dialog.addNumber("Number of class for Spines", 1);													// FOURTH NUMBER IS THE CLASSIFICATION OF SPINES	
Dialog.addNumber("Number of class for Shaft", 2);													// FIFTH NUMBER IS THE CLASS ID FOR SHAFT	

Dialog.show();

//////////////

Image_postfix = Dialog.getString();

Spines_segmented_postfix = Dialog.getString();
PSD_segmented_postfix = Dialog.getString();
ROI_postfix = Dialog.getString();


Spine_area_minimum = Dialog.getNumber();
Spine_area_maximum = Dialog.getNumber();
PSD_area_minimum = Dialog.getNumber();


Spine_class = Dialog.getNumber();
Shaft_class = Dialog.getNumber();




/* After the user entered the relevant answers, we run the script.
 *  
 *  
 */




directory = getDirectory("Folder with the images");
filelist = getFileList(directory);


//initiate the master array here as empty arrays

FilenameArray_Master = newArray(0);
BranchLengthArray_Master = newArray(0);
PSD_containing_spine_densityArray_Master = newArray(0);
Spine_densityArray_Master = newArray(0);
Spine_Number_Master = newArray(0);

//////////////////////////////////////////////////////// -- Defining the filenames and pathways



// Start a for loop to go through all images

for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], Image_postfix)) { 
    
    run("Bio-Formats Importer", "open=["+directory + File.separator + filelist[i]+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
    run("Select None");
    Currentfile = getTitle();
	rename("Original");

	ImageTitle = replace(Currentfile, Image_postfix, "");
    
    
// Cell_segmented_2D images have 1 value for spine, and 2 for shaft
// and PSD_segmented_2D images have 1 value for PSD

    Spines_segmented_2D = replace(Currentfile, Image_postfix, Spines_segmented_postfix);
    PSD_segmented_2D = replace(Currentfile, Image_postfix, PSD_segmented_postfix);
    
    
//The ROI file contains the selected dendrites for analysis.

    ROIfile = replace(Currentfile, Image_postfix, ROI_postfix);
    roiManager("open", directory + File.separator + ROIfile);
    

//////////////////////////////////////////////////////// -- Open the required images    
    
    open(directory + File.separator + Spines_segmented_2D);
    rename("Spines_2D");


 	open(directory + File.separator + PSD_segmented_2D);
    rename("PSD");   
    

    
//The composite image that serves as sanity check that the correct values were measured
    CompositeFile = replace(Currentfile, Image_postfix, "_composite.tif");
    ProjectedImage = replace(Currentfile, Image_postfix, "_projected.tif");
    
    
    
///////////////////////////////////////////////////////////  -- Creation of the intermediate images
    
    
 
 // Create a max-projected image that will be used for manual revision if the analysis went well
 	
 	selectImage("Original");
    getDimensions(width, height, channels, slices, frames);
    
    if (slices > 0) {

    run("Z Project...", "projection=[Max Intensity]");
    }
    
    
    getDimensions(width, height, channels, slices, frames);
	
	getPixelSize(unit, pixelWidth, pixelHeight); 

	
	
    rename("MaxImage");

          

// Create the 2D spines and shaft masks
// "Spines_2D" image is supposed to be color coaded with the following colors: 1 is for Spines, 2 is for Shaft, 3 is for Edge, 4 is for Background pixels.

	selectImage("Spines_2D");									// First the spines are extracted
	run("Duplicate...", "title=Spines");
//	setThreshold(Spine_class, Spine_class);
	setThreshold(0, Spine_class);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	
	run("Options...", "iterations=1 count=5 black do=Open");	// Use 'Open' to remove small particle noise from the image
    
    run("Duplicate...", "title=Spines_maths");
    run("Divide...", "value=255.00000 stack");
       
             
	
	
	selectImage("Spines_2D");									// Second the Shaft is extracted, then skeletionized
	run("Duplicate...", "title=Shaft");
	setThreshold(Shaft_class, Shaft_class);
	setOption("BlackBackground", true);
	run("Convert to Mask");
	
	run("Duplicate...", "title=Shaft-skeleton");
	
	run("Options...", "iterations=1 count=7 black do=Open");
	run("Skeletonize");
	save(directory + File.separator + ImageTitle + "_skeleton");
	
	
	
	selectImage("PSD");									// Third the PSD puncta are extracted
	
	run("Options...", "iterations=1 count=7 black do=Open");		
		


// Now create the images for measurements

// Discard non-GFP and spine overlapping PSD puncta	
	imageCalculator("Multiply create stack", "PSD","Spines_maths");

	rename("Spines_PSD_mask_2D");
	


// Close the images that are not necessray anymore
	close("Spines_maths");
	close("PSD_2D");
	close("Spines_2D");	
	close("Original");
	close("MAX_Original");
	
// Create a final composite image for analysis
	selectImage("Spines_PSD_mask_2D");
	run("Multiply...", "value=255.000 stack");
		
	
	run("Merge Channels...", "c1=Spines c2=Shaft-skeleton c3=Spines_PSD_mask_2D c4=PSD c5=Shaft create");
	rename("Composite");
	
	run("Properties...", "channels=5 slices=1 frames=1 pixel_width="+ pixelWidth +" pixel_height="+ pixelHeight + " voxel_depth=1 frame=0");
	Stack.setXUnit(unit);
	

	
//////////////////////////////////////////////////////////	 -- Analysis of the intermediate images
	
	
	
// Start analysis sequentially


// Get the number of selected dendrites first

roiManager("reset");

roiManager("Open", directory + File.separator + ROIfile);

LargeROINumber = roiManager("count");



// Do the analysis within the selected ROIs

	Finish = LargeROINumber - 1;
	for (b = 0; b <= Finish; b++) {		
	roiManager("reset");
	roiManager("Open", directory + File.separator + ROIfile);

	Filename = Currentfile + "_branch_"+b+"";

	FilenameArray = newArray(0);
	FilenameArray = Array.concat(FilenameArray,Filename);


	BranchLengthArray = newArray(0);
	SpineIDArray = newArray(0);

	Spine_densityArray = newArray(0);
	PSD_containing_spine_densityArray = newArray(0);
		


//First measure the branch length for the density
	
	selectImage("Composite");
	run("Select None");
	roiManager("deselect");

	
	run("Duplicate...", "title=Current duplicate");
	
	roiManager("Select", b);
	
	run("Clear Outside", "stack");
	run("Select None");
	
	Stack.setChannel(2);
	run("Create Selection");
	
	BranchPerimeter = getValue("Perim.");
	BranchLength = BranchPerimeter/2;
	BranchLengthArray = Array.concat(BranchLengthArray,BranchLength);
	
	roiManager("reset");
	
	
	run("Select None");
	
	
	Stack.setChannel(1);
	
	
	run("Analyze Particles...", "size="+Spine_area_minimum+"-"+Spine_area_maximum+" add slice");

	
	roiManager("Remove Channel Info");
	roiManager("Remove Slice Info");
	roiManager("Remove Frame Info");

// Rename spine ROIs and count spine density

	n = roiManager("count");
		
	
	if (n > 0) {

	
	Counter = 0;

	for (c = 0; c < n; c++) {
	roiManager("select", c);
	
	Stack.setChannel(3);
	IntDen_raw = getValue("IntDen raw");
	
	Pixel_number = IntDen_raw /255;
	PSD_area = Pixel_number * (pixelWidth * pixelHeight);
	
	if (PSD_area > PSD_area_minimum) {
	Counter = Counter +1;
	
	run("Select None");
	
	run("Duplicate...", "title=CurrentSpine duplicate");
	
	roiManager("select", c);
	run("Clear Outside");
	
	run("Create Selection");
	
	roiManager("add");
	
	roiManager("Remove Channel Info");
	roiManager("Remove Slice Info");
	roiManager("Remove Frame Info");	
	
	selectImage("MaxImage");
	roiManager("select", n);

	
	selectImage("MaxImage");
	roiManager("select", n);
	roiManager("rename", "PSD_"+(c+1));
	run("Add Selection...");

	
	close("CurrentSpine");
	
	roiManager("select", n);
	roiManager("delete");
	
	selectImage("Composite");
	Stack.setChannel(3);
	roiManager("select", c);
	
	
	}

	
    
    roiManager("rename", "Spine_"+(c+1));
	roiManager("update");
	
	ROI_ID = Roi.getName;
	ROI_IDArray = Array.concat(ROI_IDArray,ROI_ID);
	
	
	
	
	}
	}
	

	roiManager("deselect");
	
	roiManager("Remove Channel Info");
	roiManager("Remove Slice Info");
	roiManager("Remove Frame Info");


	roiManager("save", directory + File.separator + ImageTitle +"_Branch"+ b + ".zip");
	
	selectImage("MaxImage");
	run("From ROI Manager");
	roiManager("reset");
	

//	Analyse total spine density and PSD containing spine density

	//make new array for spine count
	Spine_Number = newArray(1);
	Spine_Number[0] = n;
	
	Spine_density = n/ BranchLength;
	Spine_densityArray = Array.concat(Spine_densityArray,Spine_density);

	
	PSD_containing_spine_density = Counter / BranchLength;
	PSD_containing_spine_densityArray = Array.concat(PSD_containing_spine_densityArray,PSD_containing_spine_density);
	

	close("Current");
	
//	Create the total spine density images and analyse total spine density	

	
	
////////////////////////////////////////////////////////////////// ---- Creation of the data tables for analysis


// add values to the master-array

FilenameArray_Master = Array.concat(FilenameArray_Master, Filename);
BranchLengthArray_Master = Array.concat(BranchLengthArray_Master, BranchLengthArray);
PSD_containing_spine_densityArray_Master = Array.concat(PSD_containing_spine_densityArray_Master, PSD_containing_spine_densityArray);
Spine_densityArray_Master = Array.concat(Spine_densityArray_Master, Spine_densityArray);
Spine_Number_Master = Array.concat(Spine_Number_Master, Spine_Number);


close("Transfected");
roiManager("reset");

}

selectImage("Composite");
save(directory + File.separator + CompositeFile);

selectImage("MaxImage");
save(directory + File.separator + ProjectedImage);

run("Close All");
    }
    
}

// Create table with the Master Arrays
Table.create("Transfected");
Table.setColumn("Filename", FilenameArray_Master);
Table.setColumn("Branch_length_um", BranchLengthArray_Master);
Table.setColumn("PSD-containing spine density", PSD_containing_spine_densityArray_Master);
Table.setColumn("Total protrusion density", Spine_densityArray_Master);
Table.setColumn("Total number of spines", Spine_Number_Master);


Table.save(directory + File.separator + "Spine_Density_numbers.csv");
	
	
	
	