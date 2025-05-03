## Written from MricroGL wiki : 
## https://www.nitrc.org/plugins/mwiki/index.php/mricrogl:MainPage
## And Kathleen E. Hupfeld blog : 
## https://kathleenhupfeld.com/scripting-figures-in-mricrogl/

## Commands at: https://github.com/neurolabusc/MRIcroGL10_OLD/blob/master/COMMANDS.md
## Manual here: http://www.cgl.ucsf.edu/home/meng/dicom/mricrogl-manual.pdf
## Can be loaded from Matlab (code is Python)

## Basic set-up 
import gl
import sys
print(sys.version)
print(gl.version())
gl.resetdefaults()

## Open background image
gl.loadimage('C:/Users/vguigon/Downloads/MRIcroGL/Resources/standard/spm152.nii')

## Smooth interpolation of overlay (put this line *before* your gl.overlayload('Filename') command) :
gl.overlayloadsmooth(1)
## Notes from Hupfeld: if you’re showing results that are already statistically thresholded, you probably want to turn smoothing off… That is, you likely want your results to appear exactly as they do in your SPM glass brain, with no visual alterations. if you have very very tiny clusters (e.g., k=10-15), using smooth interpolation may cause them to disappear totally from your image!

### Explanation of the above line :
## Jagged interpolation of overlay (Hupfeld: "produces bigger-looking clusters for small clusters of activations"). ## Jagged is most appropriate if your data was previously thresholded
#gl.overlayloadsmooth(0)
## If this SmoothWhenLoading item is checked, the image will be smoothed with a trilinear filter – this looks very nice (middle glass brain) and is typically appropriate if your raw data was not previously thresholded.
# gl.overlayloadsmooth(1)
## However, closer inspection of these reveals that a few tiny clusters appear. ## You can remove any clusters smaller than the specified size by calling the ‘ gl.removesmallclusters’ function from a script. You will supply the overlay index, the brightness threshold, and the minimum cluster size (in mm^3)
## See : https://www.nitrc.org/plugins/mwiki/index.php/mricrogl:MainPage#Drawing_Regions_of_Interest ## for info on cluster thresholding: how to remove small clusters depending on thresholded/non images

## Set color bar options 
gl.colorbarposition(2)
gl.colorbarsize(0.05)
## Colorbar set to non visible :
gl.colorbarposition(0)

## Color = White
gl.backcolor(255, 255, 255)
## You can not set the colorbar font/line color with Python: Change it by hand



### Figure 1

## Open overlay
gl.overlayload('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 5 - main_antsex+antmoney--antctrl/masked_vs_amyg_vmpfc_005.hdr')

## Set overlay display parameters; 1 indicates 1st overlay
gl.colorname(1,"4hot")
gl.minmax(1, 0, 5)
gl.opacity(1, 100)

### Set mosaic slices :
gl.mosaic("S H 0 -14 C H 0 -12; S H 0 10 C H 0 6;S H 0 -2 A H 0 -4");

## A = axial slices; S = sagittal; C = coronal ## semicolon separates rows
## L+ = labels ; -L (or leave it blank)= no labels 
## H 0.2 = horizontal overlap (closeness of slices); - or + sets the direction of overlap ; ## V -0.8 = vertical overlap
### Add rendered brain in mosaic slices :
## S X R O = sagittal rendered brain with lines to indicate reference slices. 
## S R = sagittal render ## This asks for a rendered brain to serve as the reference; alternatively, you can delete the R and instead you’ll just get a slice as the reference
## X = puts reference lines through the brain at the locations of your selected slices. If you delete the X, you get rid of these purple reference lines.
## 0 = slice 0 is the reference

## Save the image 
#gl.savebmp('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 5 - main_antsex+antmoney--antctrl/masked_vs_amyg_vmpfc_005.png')


## bmpzoom, to save at an even higher resolution
## "E.g., I’ve found that ~2 is too small to get nice, not-blurry images for pubs. Higher numbers, such as ~4-8 make the text (e.g., the slice and colorbar numbers) look a lot better."


## Message to continue in further images
gl.modalmessage("click OK to continue")



### Figure 2 (top left) A

## Close all open overlays.
gl.overlaycloseall()

## Open background image
gl.loadimage('C:/Users/vguigon/Downloads/MRIcroGL/Resources/standard/spm152.nii')

## Open overlays
##### CHANGE FIRST OVERLAY
gl.overlayload('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 5 - main_antsex+antmoney--antctrl/masked_vs_amyg_vmpfc_005.hdr')
gl.overlayload('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Spheres P5 Neurosynth/L_amygdala1_neurosynth1_5mm_-18_-2_-12.nii')

## Set overlay display parameters; 1 indicates 1st overlay
gl.colorname(1,"5winter")
gl.minmax(1, 0, 5)
gl.opacity(1, 100)
gl.colorname(2,"copper")
gl.minmax(2, 0, 1)
gl.opacity(2, 100)

## Set color bar options 
gl.colorbarposition(1)
gl.colorbarsize(0.05)
gl.colorbarposition(0)
gl.backcolor(255, 255, 255)

## Cutout to show amygdala
gl.cutout(0.5, 0.5, 0.3, 0.0, 1.0, 1.0)
## 1st digit says what portion of brain is cut from left to right
## 2nd digit says what portion of brain is cut from anterior to posterior
## 3rd digit says what portion of brain is cut from superior to inferior
### ? If 4th 5th and 6th digit start with 1, 1t 2nd and 3rd digit tell what portion if left uncut ?
## 4th digit to start from left (1.0 = start from right)
## 5th digit to start from posterior (1.0 = start from anterior)
## 4th digit to start from inferior(1.0 = start from superior)

## Save the image 
#gl.savebmp('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 6 - antmoney -- antctrl/antmoney_connectivity_amygL1_vmpfc_001unc_05FDR_A.png')



### Figure 2 (top left) B

## Mosaic view
gl.mosaic("S H 0 -10");

## Save the image 
#gl.savebmp('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 6 - antmoney -- antctrl/antmoney_connectivity_amygL1_vmpfc_001unc_05FDR_B.png')


## Message to continue in further images
gl.modalmessage("click OK to continue")



### Figure 3 (bottom left) A

## Close all open overlays.
gl.overlaycloseall()

## Open background image
gl.loadimage('C:/Users/vguigon/Downloads/MRIcroGL/Resources/standard/spm152.nii')

## Open overlays
##### CHANGE FIRST OVERLAY
gl.overlayload('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 5 - main_antsex+antmoney--antctrl/masked_vs_amyg_vmpfc_005.hdr')
gl.overlayload('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Spheres P5 Neurosynth/L_amygdala1_neurosynth1_5mm_-18_-2_-12.nii')

## Set overlay display parameters; 1 indicates 1st overlay
gl.colorname(1,"5winter")
gl.minmax(1, 0, 5)
gl.opacity(1, 100)
gl.colorname(2,"copper")
gl.minmax(2, 0, 1)
gl.opacity(2, 100)

## Set color bar options 
gl.colorbarposition(1)
gl.colorbarsize(0.05)
gl.colorbarposition(0)
gl.backcolor(255, 255, 255)

## Cutout to show amygdala
gl.cutout(0.5, 0.5, 0.3, 0.0, 1.0, 1.0)

## Save the image 
#gl.savebmp('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 6 - antsex -- antctrl/antsex_connectivity_amygL1_vmpfc_001unc_05FDR_A.png')



### Figure 3 (bottom left) B

## Mosaic view
gl.mosaic("S H 0 -10");

## Save the image 
#gl.savebmp('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 6 - antsex -- antctrl/antsex_connectivity_amygL1_vmpfc_001unc_05FDR_B.png')

## Message to continue in further images
gl.modalmessage("click OK to continue")



### Figure 4 (mid right) A

## Close all open overlays.
gl.overlaycloseall()

## Open background image
gl.loadimage('C:/Users/vguigon/Downloads/MRIcroGL/Resources/standard/spm152.nii')

## Open overlays
##### CHANGE FIRST OVERLAY
gl.overlayload('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 5 - main_antsex+antmoney--antctrl/masked_vs_amyg_vmpfc_005.hdr')
gl.overlayload('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Spheres P5 Neurosynth/L_amygdala1_neurosynth1_5mm_-18_-2_-12.nii')

## Set overlay display parameters; 1 indicates 1st overlay
gl.colorname(1,"5winter")
gl.minmax(1, 0, 5)
gl.opacity(1, 100)
gl.colorname(2,"copper")
gl.minmax(2, 0, 1)
gl.opacity(2, 100)

## Set color bar options 
gl.colorbarposition(1)
gl.colorbarsize(0.05)
gl.colorbarposition(0)
gl.backcolor(255, 255, 255)

## Cutout to show amygdala
gl.cutout(0.5, 0.5, 0.3, 0.0, 1.0, 1.0)

## Save the image 
#gl.savebmp('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 6 - antsex -- antctrl/common_regions_ant_connectivity_amygL1_vmpfc_001unc_05FDR_A.png')



### Figure 4 (mid right) B

## Mosaic view
gl.mosaic("S H 0 -10");

## Save the image 
#gl.savebmp('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 6 - antsex -- antctrl/common_regions_ant_connectivity_amygL1_vmpfc_001unc_05FDR_B.png')
