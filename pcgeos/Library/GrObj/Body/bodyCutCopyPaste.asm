COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		graphicBodyCutCopyPaste.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
	GrObjBodyPaste	Handles MSG_META_CLIPBOARD_PASTE
    INT GBInteralPaste		Handles pasting into existing objects
    INT GBExternalPaste		Handles pasting to new objects
    INT GBPasteText		Handles pasting of TIF_TEXT format
    INT GBPasteTextLow		Handles pasting of TIF_TEXT format
    INT GBPasteGString		Paste TIF_GRAPHICS_STRING from clipboard
    INT GBPasteGStringLow	Paste object(s) from a any gstring type
    INT	GBPasteGrObjGString	Paste all GrObj objects from a GrObj gstring
    INT GBPasteGrObjGStringSingle Paste one GrObj object from GrObj gstring
    INT	GBPasteBitmap		
    INT	GBCreateAttrGState	Creates gstate with null clip region

	GrObjBodyCopy		Handles MSG_META_CLIPBOARD_COPY
    INT	GBCopyText		Copy to TIF_TEXT format
    INT GBCopyGStringToClipboard Copy to TIF_GRAPHICS_STRING format


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:

	$Id: bodyCutCopyPaste.asm,v 1.1 97/04/04 18:08:07 newdeal Exp $
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
