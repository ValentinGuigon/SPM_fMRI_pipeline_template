## Basic set-up 
import gl
import sys
print(sys.version)
print(gl.version())
gl.resetdefaults()

## Open background image
gl.loadimage('C:/Users/vguigon/Downloads/MRIcroGL/Resources/standard/spm152.nii')

#Smoothing
gl.overlayloadsmooth(1)

## Set color bar options 
gl.colorbarposition(2)
gl.colorbarsize(0.05)
gl.colorbarposition(0)

## Color = White
gl.backcolor(255, 255, 255)

## Open overlays
gl.overlayload('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Figure 6 - antmoney -- antctrl/Antmoney-antctrl_Ant4amygL1_001unc_05FDR.ROIs.hdr')
gl.overlayload('C:/Users/vguigon/Dropbox (Personal)/Neuroeconomics Lab/SEX-MONEY/Article/Annexes et Figures/fMRI figures (MRICROGL)/Spheres P5 Neurosynth/L_amygdala1_neurosynth1_5mm_-18_-2_-12.nii')

## Set overlay display parameters; 1 indicates 1st overlay
gl.colorname(1,"5winter")
gl.minmax(1, 0, 2)
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
gl.cutout(0.6, 0.5, 0.3, 0.0, 1.0, 1.0)
## 1st digit says what portion of brain is cut from left to right
## 2nd digit says what portion of brain is cut from anterior to posterior
## 3rd digit says what portion of brain is cut from superior to inferior
### ? If 4th 5th and 6th digit start with 1, 1t 2nd and 3rd digit tell what portion if left uncut ?
## 4th digit to start from left (1.0 = start from right)
## 5th digit to start from posterior (1.0 = start from anterior)
## 4th digit to start from inferior(1.0 = start from superior)

## A = axial slices; S = sagittal; C = coronal ## semicolon separates rows
## L+ = labels ; -L (or leave it blank)= no labels 
## H 0.2 = horizontal overlap (closeness of slices); - or + sets the direction of overlap ; ## V -0.8 = vertical overlap
### Add rendered brain in mosaic slices :
## S X R O = sagittal rendered brain with lines to indicate reference slices. 
## S R = sagittal render ## This asks for a rendered brain to serve as the reference; alternatively, you can delete the R and instead you’ll just get a slice as the reference
## X = puts reference lines through the brain at the locations of your selected slices. If you delete the X, you get rid of these purple reference lines.
## 0 = slice 0 is the reference
