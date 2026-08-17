
/////////////////// This macro uses 2 Ilastik models to segment spines and PSD95 puncta in 2D images.




/*
 * First we create a control panel where the User can set the difefrent settings.
 * Then we run the selected Ilastik models to segment our images.
 * Then we save the resulting images.
 */


Dialog.create("Control panel");

Dialog.addMessage("This Macro is created to run Ilastik models on images with dendritic and PSD signal.");

Dialog.addMessage("Image type information", 16, 'black');
Dialog.addMessage("Your images will be identified based on the provided postfix");


Dialog.addString("Image postfix (with extension)", ".czi", 10);	// FIRST STRING IS THE IMAGE POSTFIX, ".CZI" IS THE DEFAULT.

Dialog.addMessage("Channel information", 16, 'black');
Dialog.addMessage("Dendritic channel will be used for dendritic spine segmentation, while \nPSD channel will be used for PSD segmentation.");

Dialog.addNumber("Dendritic channel number", 1);				// FIRST NUMBER IS THE DENDRITIC CHANNEL, DEFAULT VALUE 2 - MODIFY THE DEFAULT BY TYPING ANOTHER NUMBER IF YOU NEED.
Dialog.addNumber("PSD channel number", 3);						// SECOND NUMBER IS THE PSD CHANNEL


Dialog.addMessage("Ilastik settings", 16, 'black');
Dialog.addMessage("Add the number of label which corresponds to each structure.\nSpines and PSD spots will be identified by these provided numbers. ");

Dialog.addNumber("Number of class for Foreground", 1);				// THIRD NUMBER IS THE CLASS ID FOR FOREGROUND
Dialog.addNumber("Number of class for Spines", 1);					// FOURTH NUMBER IS THE CLASS ID FOR PSD
Dialog.addNumber("Number of class for PSD", 1);						// FIFTH NUMBER IS THE CLASS ID FOR PSD


Ilastik_type_choices_Pixelclass = newArray("Pixel classification", "Autocontext");
Ilastik_type_choices_Autocontext = newArray("Autocontext", "Pixel classification");

Dialog.addMessage("Add the titles of the different Ilastik files used");

Dialog.addString("Foreground-background segmentation", "Foreground-pixelclas", 20);	// SECOND STRING IS THE FOREGROUND MODEL
Dialog.addChoice("Model type", Ilastik_type_choices_Pixelclass);						// FIRST CHOICE IS THE FOREGROUND MODEL
Dialog.addMessage("");


Dialog.addString("Spines segmentation", "Spines_density_autocontext", 20);						// THIRD STRING IS THE SPINES MODEL
Dialog.addChoice("Model type", Ilastik_type_choices_Autocontext);						// SECOND CHOICE IS THE SPINES MODEL
Dialog.addMessage("");


Dialog.addString("PSD segmentation", "Shank2-pixelclassification", 20);								// FOURTH STRING IS THE PSD MODEL
Dialog.addChoice("Model type", Ilastik_type_choices_Pixelclass);						// THIRD CHOICE IS THE PSD MODEL
Dialog.addMessage("");




Dialog.show();


///////////////////


Dendrite_Channel = Dialog.getNumber();
PSD_Channel = Dialog.getNumber();

Foreground_class = Dialog.getNumber();
Spine_class = Dialog.getNumber();
PSD_class = Dialog.getNumber();


Image_postfix = Dialog.getString();

Foreground_model_title = Dialog.getString();
Spines_model_title = Dialog.getString();
PSD_model_title = Dialog.getString();

Foreground_model_type = Dialog.getChoice();
Spines_model_type = Dialog.getChoice();
PSD_model_type = Dialog.getChoice();


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

    
    Spines_segmented_2D = replace(Currentfile, Image_postfix, "_Spines_segmented_2D.tif");
    PSD_segmented_2D = replace(Currentfile, Image_postfix, "_PSD_segmented_2D.tif");
	
	getDimensions(width, height, channels, slices, frames);
	
	
// Be careful to duplicate the correct channels and enlarge the images to separate touching objects
// Also, store the original scaling of the images as they are lost during segmentation.
	
	if (slices>0) {

	run("Z Project...", "projection=[Max Intensity]");
	
	}
	
	rename("SingleSlice");
	
	
	run("Duplicate...", "title=PSD duplicate channels="+PSD_Channel+"");
	
	selectImage("SingleSlice");
	run("Duplicate...", "title=GFP duplicate channels="+Dendrite_Channel+"");

	close(Currentfile);
	close("MAX_"+Currentfile+"");
	close("SingleSlice");



/////////////////// Run 3 Ilastik networks on the images: 
/////////////////// First to segment the background, then identify the spines, then the PSD signal

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
    

// Second Ilastik run, to segment the spines on the already segmented Foreground signal.
// The returned image is a 8bit color-coded image where pixel values ("colors") correspond to classes. 1 is 'Spine' \ 2 is 'Shaft' \ 3 is 'Edge' \ 4 is 'Background'
	
	if (Spines_model_type == "Pixel classification") {

	run("Run Pixel Classification Prediction", "projectfilename=["+Ilastik_Directory+"\\"+Spines_model_title+".ilp] inputimage=Cell pixelclassificationtype=Segmentation");
	
	}
	
	else {
	run("Run Autocontext Prediction", "projectfilename=["+Ilastik_Directory+"\\"+Spines_model_title+".ilp] inputimage=Cell autocontextpredictiontype=Segmentation");
	
	}
	
	rename("Spines_segmented_2D");
	
	save(directory + File.separator + Spines_segmented_2D);
	
	close(Spines_segmented_2D);
	


// Third Ilastik run to segment PSD signal.


	if (PSD_model_type == "Pixel classification") {

	run("Run Pixel Classification Prediction", "projectfilename=["+Ilastik_Directory+"\\"+PSD_model_title+".ilp] inputimage=PSD pixelclassificationtype=Segmentation");
	
		}
		
	else {
	run("Run Autocontext Prediction", "projectfilename=["+Ilastik_Directory+"\\"+PSD_model_title+".ilp] inputimage=PSD autocontextpredictiontype=Segmentation");
	
	}		
	
	
	setOption("BlackBackground", true);
	setThreshold(PSD_class, PSD_class);											
	run("Convert to Mask", "method=Default background=Dark black");

	rename("PSD_segmented_2D");
	
	save(directory + File.separator + PSD_segmented_2D);

	close(PSD_segmented_2D);
	
	close("*");
    }
}
