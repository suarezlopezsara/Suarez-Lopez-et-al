
/////////////////// This macro uses 2 Ilastik models to segment dendrites


/*
 * First we create a control panel where the User can set the difefrent settings.
 * Then we run the selected Ilastik models to segment our images.
 * Then we save the resulting images.
 */


Dialog.create("Control panel");

Dialog.addMessage("This Macro is created to run Ilastik models on images with dendritic and EEA1 signal.");

Dialog.addMessage("Image type information", 16, 'black');
Dialog.addMessage("Your images will be identified based on the provided postfix");


Dialog.addString("Image postfix (with extension)", ".czi", 10);	// FIRST STRING IS THE IMAGE POSTFIX, ".CZI" IS THE DEFAULT.

Dialog.addMessage("Channel information", 16, 'black');
Dialog.addMessage("Dendritic channel will be used for dendritic spine segmentation, while \nEEA1 channel will be used for EEA1 segmentation.");

Dialog.addNumber("Dendritic channel number", 3);				// FIRST NUMBER IS THE DENDRITIC CHANNEL, DEFAULT VALUE 3 - MODIFY THE DEFAULT BY TYPING ANOTHER NUMBER IF YOU NEED.



Dialog.addMessage("Ilastik settings", 16, 'black');
Dialog.addMessage("Add the number of label which corresponds to each structure.\nSpines and EEA1 spots will be identified by these provided numbers. ");

Dialog.addNumber("Number of class for Foreground", 1);				// THIRD NUMBER IS THE CLASS ID FOR FOREGROUND

					


Ilastik_type_choices_Pixelclass = newArray("Pixel classification", "Autocontext");
Ilastik_type_choices_Autocontext = newArray("Autocontext", "Pixel classification");

Dialog.addMessage("Add the titles of the different Ilastik files used");

Dialog.addString("Foreground-background segmentation", "Foreground-background_pixelclass", 20);	// SECOND STRING IS THE FOREGROUND MODEL
Dialog.addChoice("Model type", Ilastik_type_choices_Pixelclass);						// FIRST CHOICE IS THE FOREGROUND MODEL
Dialog.addMessage("");


Dialog.addString("Spines segmentation", "Shaft+spines_autocontext", 20);						// THIRD STRING IS THE AUTOCONTEXT MODEL
Dialog.addChoice("Model type", Ilastik_type_choices_Autocontext);					
Dialog.addMessage("");



Dialog.show();


///////////////////


Dendrite_Channel = Dialog.getNumber();


Foreground_class = Dialog.getNumber();
Spine_class = Dialog.getNumber();



Image_postfix = Dialog.getString();

Foreground_model_title = Dialog.getString();
Spines_model_title = Dialog.getString();


Foreground_model_type = Dialog.getChoice();
Spines_model_type = Dialog.getChoice();



/*
 * After the settings we carry out the macro.
 * Define the directory, and implement pop-up windows to define the Ilastik model locations if necessary, at the beginning.
 * 
 */

directory = getDirectory("Choose the folder with the images");
filelist = getFileList(directory);
Ilastik_Directory = getDirectory("Choose the Folder containing the Ilastik model");


/////////////////// Import the files and define the names based on the current file -
/////////////////// usually it is a post-fix which has to be matched with the post-fixes of the further Stages.
/////////////////// Define a For loop that goes throuhg the Folder given by the User previously.


for (i = 0; i < lengthOf(filelist); i++) {
    if (endsWith(filelist[i], Image_postfix)) { 

        run("Bio-Formats Importer", "open=["+directory + File.separator + filelist[i]+"] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
    
    Currentfile = getTitle();
    //Find the middle z plane of the dendrite and the one above and below, to work on the main signal and avoid background contamination
    waitForUser;
    // Select the z planes to include in the analysis
    run("Make Substack...");
    
    
   
    getDimensions(width, height, channels, slices, frames);

    
    Projected_image = replace(Currentfile, Image_postfix, "_Projected_image.tif");
    Spines_segmented_2D = replace(Currentfile, Image_postfix, "_Spines_segmented_2D.tif");


	
	if (slices>0) {

	run("Z Project...", "projection=[Sum Slices]");
	
	}
	save(directory + File.separator + Projected_image);
	
	rename("SingleSlice");

	
	selectImage("SingleSlice");
	run("Duplicate...", "title=GFP duplicate channels="+Dendrite_Channel+"");

	close(Currentfile);
	close("MAX_"+Currentfile+"");
	close("SingleSlice");



/////////////////// Run 2 Ilastik networks on the images: 
/////////////////// First to segment the background, then refine the first segmentation

// First Ilastik run, to segment the background from Cell
// The returned image is a 32bit probability map (range from 0 to 1) in different channels: C1 Foreground \ C2 edge \ C3 background

	
	if (Foreground_model_type == "Pixel classification") {

	run("Run Pixel Classification Prediction", "projectfilename=["+Ilastik_Directory+"\\"+Foreground_model_title+".ilp] inputimage=GFP pixelclassificationtype=Probabilities");
	
	}
	
	else {
	run("Run Autocontext Prediction", "projectfilename=["+Ilastik_Directory+"\\"+Foreground_model_title+".ilp] inputimage=GFP autocontextpredictiontype=Probabilities");
	
	}
    
    rename("VirtualPrediction");
	run("Duplicate...", "title=Cell duplicate channels="+Foreground_class+"");

    close("VirtualPrediction");
    

// Second Ilastik run, to refine the first cell segmentation
// The returned image is a 8bit color-coded image where pixel values ("colors") correspond to classes. 1 is 'dendrite' \ 2 is 'background'
	
	if (Spines_model_type == "Pixel classification") {

	run("Run Pixel Classification Prediction", "projectfilename=["+Ilastik_Directory+"\\"+Spines_model_title+".ilp] inputimage=Cell pixelclassificationtype=Segmentation");
	
	}
	
	else {
	run("Run Autocontext Prediction", "projectfilename=["+Ilastik_Directory+"\\"+Spines_model_title+".ilp] inputimage=Cell autocontextpredictiontype=Segmentation");
	
	}
	
	rename("Spines_segmented_2D");
	
	save(directory + File.separator + Spines_segmented_2D);
	
	close(Spines_segmented_2D);
	
	setOption("BlackBackground", true);
	
	
	run("Close All");
    }

}
