COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Bitmap
FILE:		bitmapGeneric.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/89		Initial version

DESCRIPTION:
	This file contains desktop bitmaps for generic files/folders.

	$Id: cbitmapGeneric.asm,v 1.1 97/04/04 15:00:05 newdeal Exp $

------------------------------------------------------------------------------@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		bitmaps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	desktop bitmaps

CALLED BY:	

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;
; these are accessed in FolderCode, so put them there
;
FolderCode segment	resource

folderIconBitmap	label	word
	word	TEXT_ICON_WIDTH
	word	TEXT_ICON_HEIGHT
	byte	0, BMF_MONO
	byte	00011110b, 00000000b
	byte	00100001b, 11111000b
	byte	00101110b, 00000100b
	byte	00100000b, 00000100b
	byte	00100000b, 00000100b
	byte	00100000b, 00000100b
	byte	00100000b, 00000100b
	byte	00100000b, 00000100b
	byte	00011111b, 11111000b
ForceRef folderIconBitmap
if _FXIP
folderIconBitmapEnd	label	byte
ForceRef folderIconBitmapEnd
endif

fileIconBitmap	label	word
	word	TEXT_ICON_WIDTH
	word	TEXT_ICON_HEIGHT
	byte	0, BMF_MONO
	byte	00000111b, 11110000b
	byte	00000100b, 00010000b
	byte	00000101b, 11010000b
	byte	00000100b, 00010000b
	byte	00000101b, 11010000b
	byte	00000100b, 00010000b
	byte	00000101b, 11010000b
	byte	00000100b, 00010000b
	byte	00000111b, 11110000b
ForceRef fileIconBitmap
if _FXIP
fileIconBitmapEnd	label	byte
ForceRef fileIconBitmap
endif

FolderCode ends



;
; these are accessed from Tree and Folder
;
DragIconResource segment resource

folderIconRegion	word	0, 0, DRAG_REGION_WIDTH, DRAG_REGION_HEIGHT
			word	-1, EOREGREC
			word	0, 2, 7, EOREGREC
			word	1, 1, 1, 8, 8, EOREGREC
			word	2, 0, 0, 9, 17, EOREGREC
			word	3, 0, 0, 2, 8, 18, 18, EOREGREC
			word	4, 0, 0, 18, 19, EOREGREC
			word	13, 0, 0, 18, 19, EOREGREC
			word	14, 1, 19, EOREGREC
			word	15, 2, 18, EOREGREC
			word	EOREGREC
ForceRef folderIconRegion

fileIconRegion	word	0, 0, DRAG_REGION_WIDTH, DRAG_REGION_HEIGHT
		word	-1, EOREGREC
if 0
		word	0, 0, 14, EOREGREC
		word	1, 0, 0, 13, 13, 15, 15, EOREGREC
		word	2, 0, 0, 13, 13, 16, 16, EOREGREC
		word	3, 0, 0, 13, 13, 17, 17, EOREGREC
		word	4, 0, 0, 13, 13, 18, 18, EOREGREC
		word	5, 0, 0, 13, 13, 19, 19, EOREGREC
		word	6, 0, 0, 13, 20, EOREGREC
		word	7, 0, 0, 19, 20, EOREGREC
		word	14, 0, 0, 19, 20, EOREGREC
		word	15, 0, 20, EOREGREC
		word	16, 1, 20, EOREGREC
else
		word	0, 3, 14, EOREGREC
		word	1, 3, 3, 14, 15, EOREGREC
if 0
		word	2, 3, 3, 5, 12, 14, 15, EOREGREC
		word	3, 3, 3, 14, 15, EOREGREC
		word	4, 3, 3, 5, 12, 14, 15, EOREGREC
		word	5, 3, 3, 14, 15, EOREGREC
		word	6, 3, 3, 5, 12, 14, 15, EOREGREC
		word	7, 3, 3, 14, 15, EOREGREC
		word	8, 3, 3, 5, 12, 14, 15, EOREGREC
		word	9, 3, 3, 14, 15, EOREGREC
		word	10, 3, 3, 5, 12, 14, 15, EOREGREC
		word	11, 3, 3, 14, 15, EOREGREC
		word	12, 3, 3, 5, 12, 14, 15, EOREGREC
endif
		word	13, 3, 3, 14, 15, EOREGREC
		word	14, 3, 15, EOREGREC
		word	15, 4, 15, EOREGREC
endif
		word	EOREGREC
ForceRef fileIconRegion

multiIconRegion		word	0, 0, DRAG_REGION_WIDTH, DRAG_REGION_HEIGHT
			word	-1, EOREGREC
if 0
			word	0, 0, 14, EOREGREC
			word	1, 0, 0, 14, 14, EOREGREC
			word	2, 0, 0, 14, 14, EOREGREC
			word	3, 0, 0, 3, 17, EOREGREC
			word	4, 0, 0, 3, 3, 17, 17, EOREGREC
			word	5, 0, 0, 3, 3, 17, 17, EOREGREC
			word	6, 0, 0, 3, 3, 6, 20, EOREGREC
			word	7, 0, 0, 3, 3, 6, 6, 20, 20, EOREGREC
			word	9, 0, 0, 3, 3, 6, 6, 20, 20, EOREGREC
			word	10, 0, 3, 6, 6, 20, 20, EOREGREC
			word	11, 3, 3, 6, 6, 20, 20, EOREGREC
			word	12, 3, 3, 6, 6, 20, 20, EOREGREC
			word	13, 3, 6, 20, 20, EOREGREC
			word	14, 6, 6, 20, 20, EOREGREC
			word	15, 6, 6, 20, 20, EOREGREC
			word	16, 6, 20, EOREGREC
else
			word	0, 9, 18, EOREGREC
			word	1, 9, 9, 18, 19, EOREGREC
			word	2, 5, 14, 18, 19, EOREGREC
			word	3, 5, 5, 14, 15, 18, 19, EOREGREC
			word	4, 1, 10, 14, 15, 18, 19, EOREGREC
			word	5, 1, 1, 10, 11, 14, 15, 18, 19, EOREGREC
			word	10, 1, 1, 10, 11, 14, 15, 18, 19, EOREGREC
			word	11, 1, 1, 10, 11, 14, 19, EOREGREC
			word	12, 1, 1, 10, 11, 14, 19, EOREGREC
			word	13, 1, 1, 10, 15, EOREGREC
			word	14, 1, 1, 10, 15, EOREGREC
			word	15, 1, 11, EOREGREC
			word	16, 2, 11, EOREGREC
endif
			word	EOREGREC
ForceRef multiIconRegion

DragIconResource ends



if _TREE_MENU
;
; these are accessed in TreeCode, so put them there
;
TreeCode segment	resource

treeIconBitmap	label	word
	word	TREE_OUTLINE_ICON_WIDTH
	word	TREE_OUTLINE_ICON_HEIGHT
	byte	0, BMF_MONO
	byte	00111111b, 11111000b
	byte	01000000b, 00000100b
	byte	01000000b, 00000100b
	byte	01000000b, 00000100b
	byte	01001111b, 11100100b
	byte	01000000b, 00000100b
	byte	01000000b, 00000100b
	byte	01000000b, 00000100b
	byte	00111111b, 11111000b
ForceRef treeIconBitmap
if _FXIP
treeIconBitmapEnd	label	byte
ForceRef treeIconBitmapEnd
endif

collapsedIconBitmap	label	word
	word	TREE_OUTLINE_ICON_WIDTH
	word	TREE_OUTLINE_ICON_HEIGHT
	byte	0, BMF_MONO
	byte	00111111b, 11111000b
	byte	01000000b, 00000100b
	byte	01000001b, 00000100b
	byte	01000001b, 00000100b
	byte	01001111b, 11100100b
	byte	01000001b, 00000100b
	byte	01000001b, 00000100b
	byte	01000000b, 00000100b
	byte	00111111b, 11111000b
ForceRef collapsedIconBitmap
if _FXIP
collapsedIconBitmapEnd	label	byte
ForceRef collapsedIconBitmapEnd
endif

TreeCode ends

endif ; _TREE_MENU
