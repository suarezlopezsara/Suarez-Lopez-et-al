# Suarez-Lopez-et-al
This repository contains the FIji Macros used for image analysis in the paper Loss of RIN1 decouples dendritic spine structure from synaptic strength and impairs hippocampal long-term depression

Created and used in Fiji (v. 1.54f; Java 1.8.0_322 (64-bit) - https://imagej.net/software/fiji/

## Included Macros

1. Dendrite segmentation.ijm
Creates a mask for the segmentation of dendrites usign 2 Ilastik string models.
- Input: original .czi files from the dendrites
- Output: a .tif file with 2 channels corresponding to dendrite and background and a .tif file with a sub-stack of the selected z-planes containing the original channels. 

2. Surface_GluA1_fluorescence_quantification
Measures GluA1 fluorescence intensity inside the dendrite ROI. Uses the dendrite segementation from the previous macro to create the dendrite ROI and the sub-stack to measure fluorescence intensity.

3. GluA1_in_Shank2_positive_areas.ijm
Measures fluorescence intensity of GluA1 inside a ROI generated from thresholding Shank2 signal. Uses the dendrite mask from the first macro to create the dendrite ROI, as well as the sub-stack. 





