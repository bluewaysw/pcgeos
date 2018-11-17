COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Graphics
FILE:		graphicsPatternHatch.asm

AUTHOR:		Don Reeves, Mar 19, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/19/92		Initial revision

DESCRIPTION:
	Contains the definitions of the system hatch patterns.

	$Id: graphicsPatternHatch.asm,v 1.1 97/04/05 01:13:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SystemBitmapsAndHatches	segment	lmem LMEM_TYPE_GENERAL, mask LMF_IN_RESOURCE


StartPatterns	<(SystemBitmap + SystemHatch)>

;--- Bitmaps ---


;--- Hatches ---

DefPattern	HatchVertical
MakeHatch	HatchVertical, 1, TRUE
		MakeHatchLine	<0.0>,<0.0>, <0.0>,<4.0>, <90.0>, \
				<0,CF_SAME,0,0>, 0
EndHatch	HatchVertical


DefPattern	HatchHorizontal
MakeHatch	HatchHorizontal, 1, TRUE
		MakeHatchLine	<0.0>,<0.0>, <0.0>,<4.0>, <0.0>, \
				<0,CF_SAME,0,0>, 0
EndHatch	HatchHorizontal


DefPattern	Hatch45Degree
MakeHatch	Hatch45Degree, 1, TRUE
		MakeHatchLine	<0.0>,<0.0>, <0.0>,<4.0>, <45.0>, \
				<0,CF_SAME,0,0>, 0
EndHatch	Hatch45Degree


DefPattern	Hatch135Degree
MakeHatch	Hatch135Degree, 1, TRUE
		MakeHatchLine	<0.0>,<0.0>, <0.0>,<4.0>, <135.0>, \
				<0,CF_SAME,0,0>, 0
EndHatch	Hatch135Degree

DefPattern	HatchBrick
MakeHatch	HatchBrick, 2, TRUE
		MakeHatchLine	<0.0>,<0.0>, <0.0>,<4.0>, <0.0>, \
				<0,CF_SAME,0,0>, 0
		MakeHatchLine	<0.0>,<0.0>, <4.0>,<4.0>, <90.0>, \
				<0,CF_SAME,0,0>, 1
				MakeHatchDash	<4.0>, <4.0>
EndHatch	HatchBrick
						
DefPattern	HatchBrickSlanted
MakeHatch	HatchBrickSlanted, 2, TRUE
		MakeHatchLine	<0.0>,<0.0>, <0.0>,<4.0>, <45.0>, \
				<0,CF_SAME,0,0>, 0
		MakeHatchLine	<0.0>,<0.0>, <4.0>,<4.0>, <135.0>, \
				<0,CF_SAME,0,0>, 1
				MakeHatchDash	<4.0>, <4.0>
EndHatch	HatchBrickSlanted


EndPatterns

SystemBitmapsAndHatches	ends
