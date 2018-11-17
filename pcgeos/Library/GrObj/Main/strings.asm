COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		strings.asm

AUTHOR:		Steve Scholl


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/21/92		Initial revision


DESCRIPTION:
		

	$Id: strings.asm,v 1.1 97/04/04 18:05:13 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



Strings segment lmem LMEM_TYPE_GENERAL

LocalDefString rotateString <"Rotate",0>
LocalDefString moveString <"Move",0>
LocalDefString resizeString <"Resize",0>
LocalDefString skewString <"Skew",0>
LocalDefString transformString <"Transform",0>
LocalDefString scaleString <"Scale",0>
LocalDefString deleteString <"Delete",0>
LocalDefString createString <"Create",0>
LocalDefString groupString <"Group",0>
LocalDefString ungroupString <"Ungroup",0>
LocalDefString lockString <"Lock Change",0>
LocalDefString depthString <"Depth Change",0>
LocalDefString areaAttrString <"Area Attribute Change",0>
LocalDefString lineAttrString <"Line Attribute Change",0>
LocalDefString attrFlagsString <"Attribute Flags Change",0>
LocalDefString pasteInsideString <"Paste Inside",0>
LocalDefString shuffleUpString <"Pull Forward",0>
LocalDefString shuffleDownString <"Push Back",0>
LocalDefString bringToFrontString <"Bring To Front",0>
LocalDefString sendToBackString <"Send To Back",0>
LocalDefString pasteString	<"Paste",0>
LocalDefString arcChangesString	<"Arc Changes",0>
LocalDefString flipString <"Flip",0>
unnamedGrObjString	chunk.char "Unnamed Graphic",0

Strings ends



ErrorStrings	segment lmem LMEM_TYPE_GENERAL

LocalDefString pasteInsideOverlapErrorString <"For Paste Inside to work correctly the object(s) you cut must overlap the object(s) within which you are trying to paste.\r\rError Code: DR-01",0>

LocalDefString convertToBitmapTooBigErrorString <"Selected object(s) are too wide to convert to a bitmap.\r\rError Code: DR-02",0>

ErrorStrings	ends
