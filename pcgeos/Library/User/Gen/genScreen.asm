COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genScreenClass.asm

ROUTINES:
	Name			Description
	----			-----------
   GLB	GenScreenClass	Class that implements a field window

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

DESCRIPTION:
	This file contains routines to implement the GenScreen class.

	$Id: genScreen.asm,v 1.1 97/04/07 11:44:43 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT @CLASS DESCRIPTION-----------------------------------------------------

				GenScreenClass

Synopsis
--------

GenScreenClass Implements a screen (a root window on a display device)

------------------------------------------------------------------------------@

UserClassStructures	segment resource

	GenScreenClass

UserClassStructures	ends

BuildUncommon segment resource


COMMENT @----------------------------------------------------------------------

METHOD:		GenScreenSetVideoDriver -- MSG_GEN_SCREEN_SET_VIDEO_DRIVER
					for GenScreenClass

DESCRIPTION:	Setup instance data for a screen object

PASS:
	*ds:si - instance data (for object in GenScreen class)
	es - segment of GenScreenClass

	ax - MSG_GEN_SCREEN_SET_VIDEO_DRIVER

	bp - handle of video driver to use

RETURN:	nothing

ALLOWED TO DESTROY:
	ax, cx, dx, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

pPSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@
screenSizeCategoryStr	char	"ui", 0
tinyScreenStr		char	"tinyScreen", 0
tvScreenStr		char	"tvMode",0


GenScreenSetVideoDriver	method	dynamic GenScreenClass,
				MSG_GEN_SCREEN_SET_VIDEO_DRIVER

	mov	bx, bp			; Move video driver to use to bx

	tst	bx
	jnz	haveVideoDriver
					; Otherwise, set to default
	mov	ax, GDDT_VIDEO
	call	GeodeGetDefaultDriver	; Get default video driver
	mov	bx, ax
	tst	bx			; Make sure we've got a video driver...
	jnz	haveVideoDriver
	
	call	UserScreenNoVideoDriverError
	.unreached

haveVideoDriver:
	mov	ds:[di].GSCI_videoDriver, bx	; store video driver to use

						; have we cached the first
						; display type yet?
	segmov	es, dgroup, cx			; SH
	test	es:[uiFlags], mask UIF_HAVE_DISPLAY_TYPE
	jnz	haveDisplayType			; if so, done.


	call	GeodeInfoDriver
	push	ds, si			; VideoDeviceInfo


if FAKE_SIZE_OPTIONS
	call	FakeScreen
endif
	;
	; 10/93 - moved tiny screen check out of FakeScreen for the bullet.
	;

	mov	cx, cs
	mov	ds, cx
	mov	si, offset screenSizeCategoryStr
	mov	dx, offset tinyScreenStr
	clr	ax
	call	InitFileReadBoolean
	pop	ds, si			; VideoDeviceInfo

	tst	ax
	jz	afterTiny

	andnf	ds:[si].VDI_displayType, not mask DT_DISP_SIZE
					; store tiny size in DisplayType
	or	ds:[si].VDI_displayType, DS_TINY shl offset DT_DISP_SIZE
afterTiny:

	push	ds, si
	mov	cx, cs
	mov	ds, cx
	mov	si, offset screenSizeCategoryStr
	mov	dx, offset tvScreenStr
	clr	ax
	call	InitFileReadBoolean
	pop	ds, si			; VideoDeviceInfo

	tst	ax
	jz	afterTV

	andnf	ds:[si].VDI_displayType, not mask DT_DISP_ASPECT_RATIO
					; store tiny size in DisplayType
	or	ds:[si].VDI_displayType, DAR_TV shl offset DT_DISP_ASPECT_RATIO
afterTV:


	mov	ah, ds:[si].VDI_displayType	; fetch DisplayType, in ah
	mov	es:[uiDisplayType], ah		; Store the displayType in a
						; global variable, where we can
						; get at it.
						; Set flag -- DisplayType set.
	or	es:[uiFlags], mask UIF_HAVE_DISPLAY_TYPE

haveDisplayType:
	ret

GenScreenSetVideoDriver	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	FakeScreen

DESCRIPTION:	Check .ini file for fake screen sizes to use.  If found,
		substitute here & alter video driver table. If the
		continueSetup boolean equals true, we ignore any size.

CALLED BY:	GenScreenSetVideoDriver

PASS:		ds:si	- VideoDeviceInfo table

RETURN:		device table	- possibly altered

DESTROYED:	ax, bx, cx, dx, di, ds, si

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/22/93   	added header

------------------------------------------------------------------------------@
if FAKE_SIZE_OPTIONS

FakeScreen		proc	near
	uses	es
	.enter

	segmov	es, ds
	mov	di, si				; es:di - VideoDriverInfo

	;
	;  If we're in graphical setup, don't change the screen size.
	;

	mov	cx, cs
	mov	ds, cx
	mov	si, offset systemCategoryStr
	mov	dx, offset continueSetupStr

	clr	ax
	call	InitFileReadBoolean

	tst	ax
LONG 	jnz	done

	;
	;  Read the X and Y screen sizes, and update the
	;  VideoDriverInfo structure.
	;
	mov	si, offset screenSizeCategoryStr
	mov	dx, offset xScreenSizeStr
	call	InitFileReadInteger
	jc	afterX

	mov	es:[di].VDI_pageW, ax
afterX:

	mov	dx, offset yScreenSizeStr
	call	InitFileReadInteger
	jc	afterY

	mov	es:[di].VDI_pageH, ax
afterY:

	;
	; See if there is a library which contains the hard icon UI.
	;

	mov	dx, offset hardIconsLibraryStr
	clr	bp			; allocate a block for string
	call	InitFileReadString	; ^hbx <- buffer with string in it
	jc	doneShort
	tst	cx			; cx <- string length
	jnz	haveHardIconLibrary
	tst	bx
	jz	done
	call	MemFree
doneShort:
	jmp	done

haveHardIconLibrary:
	;
	; Get the block containing the hard icon UI from the library
	; specified in the .ini file.
	;
	mov	cx, bx			; ^hcx <- block containing .ini string
	call	MemLock
	mov	ds, ax
	clr	ax, bx, si		; ds:si <- library name
					; no protocol checking
	call	GeodeUseLibrary		
	push	bx			; ^hbx <- library handle
	mov	bx, cx
	lahf
	call	MemFree			; free InitFileReadString buffer
	sahf
	pop	bx			
	jc	done			; no library was loaded

	push	bx			; save library handle
	call	AddHardIconBars
	pop	bx			; bx = library handle
	call	GeodeFreeLibrary
done:

	.leave
	ret
FakeScreen		endp

systemCategoryStr	char	"system", 0
continueSetupStr	char	"continueSetup", 0

xScreenSizeStr		char	"xScreenSize", 0
yScreenSizeStr		char	"yScreenSize", 0
hardIconsLibraryStr	char	"hardIconsLibrary", 0
numHardIconBarsStr	char	"numHardIconBars",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddHardIconBars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the hard-icon bar(s) to the UIApp.

CALLED BY:	FakeScreen

PASS:		bx = hard-icon library handle

RETURN:		nothing (adds hard-icon bars to UI).

DESTROYED:	ax, bx, cx, dx, si, di bp, ds

PSEUDO CODE/STRATEGY:

	This routine gets called if we find the category
	"hardIconsLibrary" in the INI file, so we assume
	there's at least one hard-icon bar exported by said
	library.

	To be backwards-compatible with the Zoomer & Bullet
	PC emulators, we first check for 

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	7/15/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddHardIconBars	proc	near
		.enter
	;
	;  Get the last hard-icon bar.  We have to do this one
	;  first to be backwards compatible with the Zoomer and
	;  Bullet hard-icon libraries, which have only one bar.
	;
		push	bx			; save the library handle
		clr	ax			; first (or only) bar
		call	ProcGetLibraryEntry
		call	ProcCallFixedOrMovable	; ^hbx:dx <- optr of HardIcon UI
EC <		call	ECCheckOD					>
	;
	;  Duplicate the returned resource & add it to the UI.
	;
		call	AddIconBarToUIApp
	;
	;  Get the number of icon bars.
	;
		mov	cx, cs
		mov	ds, cx
		mov	si, offset screenSizeCategoryStr	; "ui"
		mov	dx, offset numHardIconBarsStr
		call	InitFileReadInteger
		pop	bx			; restore library handle
		jc	done
		cmp	ax, 1			; only has one bar?
		jle	done			; yep; we've already done it
	;
	;  Loop as many times as there are icon bars left to
	;  add, and add them.
	;
		mov_tr	cx, ax			; cx = # bars to do
		dec	cx			; already did one
barLoop:
		mov	ax, cx			; not mov_tr! preserve count.
		call	ProcGetLibraryEntry	; go boy
		call	ProcCallFixedOrMovable	; ^hbx:dx <- optr of HardIcon UI
EC <		call	ECCheckOD					>
	;
	;  Add away.
	;
		call	AddIconBarToUIApp
		loop	barLoop
done:
		.leave
		ret
AddHardIconBars	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddIconBarToUIApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a single hard-icon interaction to the UI app.

CALLED BY:	AddHardIconBars

PASS:		bx = resource handle of icon bar to duplicate

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	7/18/94			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddIconBarToUIApp	proc	near
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	;  Duplicate the passed resource.
	;
		clr	ax, cx			; owned by this geode, run by
							; this thread
		call	ObjDuplicateResource
		mov	cx, bx			; ^hcx <- dup'ed resource
	;
	;  Add this icon bar to the UI.
	;
		pushdw	cxdx			; ^lcx:dx = hardicon interaction
		mov	bx, handle UIApp
		mov	si, offset UIApp
		mov	ax, MSG_GEN_ADD_CHILD
		mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
		clr	di
		call	ObjMessage
	;
	;  Bring it onscreen.
	;
		popdw	bxsi
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		.leave
		ret
AddIconBarToUIApp	endp


endif


COMMENT @----------------------------------------------------------------------

METHOD:		GenScreenBuild -- MSG_META_RESOLVE_VARIANT_SUPERCLASS for GenScreenClass

DESCRIPTION:	Build an object

PASS:
	*ds:si - instance data (for object in GenScreen class)
	es - segment of GenScreenClass

	ax - MSG_META_RESOLVE_VARIANT_SUPERCLASS
	cx - master offset of variant class to build

RETURN: cx:dx - class for specific UI part of object (cx = 0 for no build)

ALLOWED TO DESTROY:
	ax, bp
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

GenScreenBuild	method	GenScreenClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
					; get UI to use by querying system
					;	object
	mov	cx, GUQT_UI_FOR_SCREEN
	mov	ax, MSG_SPEC_GUP_QUERY
	call	UserCallSystem

	mov	bx, ax			; bx = handle of specific UI to use

	mov	ax, SPIR_BUILD_SCREEN
	mov	di,MSG_META_RESOLVE_VARIANT_SUPERCLASS
	call	ProcGetLibraryEntry
	GOTO	ProcCallFixedOrMovable

GenScreenBuild	endm

BuildUncommon ends

Ink	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenInitializeDisplayOrientation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine starting display orientation

CALLED BY:	
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
		Sets up initial orientation

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	5/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Ink	ends
