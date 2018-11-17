
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:        PC GEOS
MODULE:         Brother NIKE 56-jet print driver
FILE:           nike56Strings.asm

AUTHOR:         Dave Durran

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/94          Initial revision


DESCRIPTION:
        This file contains the Strings used in the driver


        $Id: nike56Strings.asm,v 1.1 97/04/18 11:55:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

customStringsUI	segment	lmem	LMEM_TYPE_GENERAL

TimeoutText	chunk.char "The printing operation has timed out.  Click OK to cancel the job, and try the operation again.",0

PaperJamText	chunk.char "The paper has jammed and the operation cannot continue.  First, clear the paper path.  Then click OK to cancel the job, and try the operation again.",0

InsertPaperText	chunk.char "There is no paper in the printer.  Insert a sheet of paper and click OK.",0

PaperRunOutText	chunk.char "The paper you have inserted in the printer does not match the actual document size.  This has caused the paper to run out while printing your document.  Click OK to cancel this page, and be sure to load the proper size paper for your document when you try the operation again.",0

SomeErrorText	chunk.char "An error occurred during printing.  Click OK to try the operation again.",0

FatalErrorText	chunk.char "An error occurred during printing.  Click OK to cancel the print job and try the operation again.",0

ChangeCartridgeText chunk.char "Insert a new ink cartridge.  Click OK when you are ready to continue.",0

ErrorHomingText	chunk.char "The system was unable to find the home position for the printhead.  Click OK to cancel the print job and try the operation again.",0

ErrOKTriggerMoniker	chunk	VisMoniker
	VisMoniker <
		<		; VM_type
		    0,			; VMT_MONIKER_LIST
		    0,			; VMT_GSTRING
		    DAR_NORMAL,		; VMT_GS_ASPECT_RATIO
		    DC_TEXT		; VMT_GS_COLOR
		>,
		0		; VM_width
	>
	VisMonikerText <
		VMO_NO_MNEMONIC			; VMT_mnemonicOffset
	>
	LocalDefNLString <"OK", 0>
ErrOKTriggerMoniker	endc

ErrCancelTriggerMoniker	chunk	VisMoniker
	VisMoniker <
		<		; VM_type
		    0,			; VMT_MONIKER_LIST
		    0,			; VMT_GSTRING
		    DAR_NORMAL,		; VMT_GS_ASPECT_RATIO
		    DC_TEXT		; VMT_GS_COLOR
		>,
		0		; VM_width
	>
	VisMonikerText <
		VMO_CANCEL			; VMT_mnemonicOffset
	>
	LocalDefNLString <"Cancel", 0>
ErrCancelTriggerMoniker	endc

customStringsUI	ends
