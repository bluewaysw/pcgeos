COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC/GEOS	
MODULE:		Text Library
FILE:		textEntry.asm

AUTHOR:		Vijay Menon, Sep 13, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	9/13/93   	Initial revision


DESCRIPTION:
	Library entry point routines.
		

	$Id: textEntry.asm,v 1.4 98/03/24 23:16:20 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ForceRef	TextLibraryEntry

ifdef	USE_FEP

udata	segment
	fepStrategy		fptr.far	0 ; Pointer to FEP
						  ; strategy function.
	fepDrHandle		hptr.GeodeHeader
udata	ends

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextLibraryEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Text Library Init/Deinit.

CALLED BY:	INTERNAL ()
PASS:		di	= LibraryCallType
 
RETURN:		carry	= set if error
DESTROYED:	si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		When the text library is initially loaded, check the
	INI file for FEP driver.  If one is listed, load it.  Upon
	exiting the text library, unload the FEP driver.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	VM	9/13/93    	Initial version
	eca	3/14/97   	added localized smart quotes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextInit segment resource

ifdef	USE_FEP

FEP_DRIVER_NAME_LENGTH	equ	12

fepCategory	char	"fep",0
fepDriverKey	char	"driver",0

LocalDefNLString fepDirectory	<"FEP",0>
endif	; USE_FEP

quoteCategory	char	"localization",0
quoteKey	char	"quotes",0

TextLibraryEntry	proc	far
		uses	ax,bx,cx,dx,ds,es,di,si,bp
		.enter
	; 
	; ds <- Segment address of dgroup.
	;
		segmov	ds, dgroup, ax		

	;
	; Call	appropriate routine based on LibraryCallType.
	;
		shl	di
		call	cs:[libraryEntryTable][di]
	
		.leave
		ret

libraryEntryTable	nptr.near	\
	loadFep,			; LCT_ATTACH
	unloadFep,			; LCT_DETACH
	doNothing,			; LCT_NEW_CLIENT
	doNothing,			; LCT_NEW_CLIENT_THREAD
	doNothing,			; LCT_CLIENT_THREAD_EXIT
	doNothing			; LCT_CLIENT_EXIT
.assert	length libraryEntryTable eq LibraryCallType

loadFep:
	;
	; read the quotes set in the GEOS.INI file, if any
	;
		push	ds
		segmov	ds, cs, cx
		mov	si, offset quoteCategory	;ds:si <- category
		mov	dx, offset quoteKey		;cx:dx <- key
		mov	bp, InitFileReadFlags<IFCC_INTACT, 0, 0, (size TCHAR)*4>
							;bp <- InitFileReadFlags
		segmov	es, dgroup, ax
		mov	di, offset uisqOpenSingle	;es:di <- buffer
		call	InitFileReadData
		pop	ds

ifdef	USE_FEP

	;
	; LCT_ATTACH
	; ----------
	; Check for FEP driver in the INI file.  Load any listed
	; driver and store the corresponding strategy function in
	; fepStrategy.  If no FEP driver is listed clear fepStrategy.
	;
		push	ds, bp
	;
	; Set parameters for InitFileReadString.
	;	ds:si 	= FEP category name
	;	cx:dx 	= FEP driver key name
	;	bp	= 0
	;
		segmov	ds, cs, cx
		mov	si, offset fepCategory
		mov	dx, offset fepDriverKey
		clr	bp
		call	InitFileReadString	; CF 	= 1 iff no driver
		jc	loadDone
	;
	; Switch to the FEP driver directory
	;
		push	bx, dx
		call	FilePushDir
		mov	bx, SP_SYSTEM		; bx <- StandardPath
		mov	dx, offset fepDirectory	; ds:dx <- ptr to path
		call	FileSetCurrentPath
		pop	bx, dx
		jc	popDir			; branch if error
	;
	; FEP Driver is listed.  bx = handle of driver name.
	; Load the driver and obtain a pointer to its strategy.
	;
		push	bx
		call	MemLock
		mov	ds, ax
		clr	si, ax, bx
		call	GeodeUseDriver		; Load the driver.
		jc	popExit			; branch if error.
		mov	bp, bx			; bp = driver handle
		call	GeodeInfoDriver		; Get the strategy pointer.
		pop	bx
		call	MemFree
	; 
	; Store strategy pointer in local variable (fepStrategy).
	;
		mov	ax, ds:[si].DIS_strategy.segment
		mov	si, ds:[si].DIS_strategy.offset
		segmov	ds, dgroup, bx
		mov	ds:fepStrategy.segment, ax
		mov	ds:fepStrategy.offset, si
		mov	ds:fepDrHandle, bp
	;
	; Return to whence we came
	;
popDir:
		call	FilePopDir

loadDone:
		clc
		pop	ds, bp
		retn

popExit:
		pop	bx
		call	MemFree
		jmp	popDir

unloadFep:
	;
	; LCT_DETACH
	; ----------
	; If FEP Driver is loaded, unload it.
	;
		mov	bx, ds:[fepDrHandle]
		tst	bx
		jz	doNothing
		call	GeodeFreeDriver

else	; !USE_FEP

unloadFep:

endif	; USE_FEP

doNothing:
		clc
		retn

TextLibraryEntry	endp

ForceRef	TextLibraryEntry

TextInit 	ends
