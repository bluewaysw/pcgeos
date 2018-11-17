COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Last Words
FILE:		lastwords.asm

AUTHOR:		Adam de Boor, Apr  28, 1991

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial revision

DESCRIPTION:
	This is a specific screen-saver library to move a message around on the
	screen.
	

	$Id: lastwords.asm,v 1.1 97/04/04 16:48:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include type.def
include geos.def
include geosmacro.def
include errorcheck.def
include library.def
include localmem.def
include graphics.def
include gstring.def
include win.def
include	geode.def
include object.def
include event.def
include metaClass.def
include processClass.def
include	geodeBuild.def
include thread.def
include timer.def
include initfile.def
include fontEnum.def
include vm.def
include timedate.def
include localization.def
include system.def
ACCESS_FILE_STRUC	= 1
include fileStruc.def

UseLib	ui.def
UseLib	options.def
UseLib	saver.def

;
; THIS MUST BE FIRST OR UserFontCreateList WILL DIE
;
idata	segment
bogus	hptr	handle dgroup
idata	ends

include	coreBlock.def

include character.def

;==============================================================================
;
;		  PUBLIC DECLARATION OF ENTRY POINTS
;
;==============================================================================

global	LWStart:far
global	LWStop:far
global	LWFetchUI:far
global	LWFetchHelp:far
global	LWSaveState:far
global	LWRestoreState:far
global	LWSaveOptions:far

global	LWDraw:far
global	LWUpdateFontSample:far

global	LWSetFont:far
global	LWSetListFont:far
global	LWSetSize:far
global	LWSetAngleRandom:far
global	LWSetColor:far
global	LWSetSpeed:far
global	LWSetMotion:far
global	LWSetFormat:far
global	LWPasteGraphic:far

;==============================================================================
;
;		       CONSTANTS AND DATA TYPES
;
;==============================================================================
GASP_CHOKE_WHEEZE					enum	FatalErrors

LW_MAX_MENU_FONTS	equ	MAX_MENU_FONTS
LW_MAX_FONTS	equ	MAX_FONTS

LW_MAX_LENGTH	equ	64	; 64 chars max in the message.
LW_GSTRING_BLOCK_SIZE equ 8192	; size for each VM block of the gstring
					;  we may draw. Why 8k? Why not?

;
; The different speeds we support, in ticks between moving the message
;
LW_SLUG_SPEED	equ	120
LW_SLOW_SPEED	equ	60
LW_MEDIUM_SPEED	equ	30
LW_FAST_SPEED	equ	10

LWMotionType	etype	word
    LWMT_BOUNCE		enum	LWMotionType
    LWMT_RANDOM		enum	LWMotionType

LWFormatType	etype	word, 0, 2
    LWFT_TEXT		enum	LWFormatType
    LWFT_GRAPHIC		enum	LWFormatType
    LWFT_TIME		enum	LWFormatType
    LWFT_DATE		enum	LWFormatType

DATE_FORMAT	=	DTF_LONG_CONDENSED
TIME_FORMAT	=	DTF_HMS

LW_DELTA_BASE	equ	5	; Move at least 5 pixels each time
LW_DELTA_MAX	equ	16	; but at most 21...

;
; The definition of a LWStruct, in case we ever need more than one of them
;
LWStruct	struc
    LWS_x		SaverVector
    LWS_y		SaverVector
    LWS_lastAngle	WWFixed
    LWS_lastColor	Colors
    LWS_drawn		byte		0
LWStruct	ends

LWPasteFlags record
    LWPF_TRANSFER_IS_GRAPHIC:1	; set if transfer item is graphical
    LWPF_HAVE_DOCUMENT:1		; set if we've got a document open
LWPasteFlags end

;==============================================================================
;
;			     LWClass
;
;==============================================================================

LWClass	class	SaverClass
;
; The state we save to our parent's state file on shutdown.
;
			public
    LWCI_fontID		FontIDs	FONT_URW_ROMAN	; Font to use
    LWCI_size		word	24*8		; Pointsize of same
    LWCI_angle		sword	0		; Angle at which to draw it.
    						; -1 => random
    LWCI_color		Colors	-1		; Color in which to draw it.
    						; -1 => random
    LWCI_motion		LWMotionType LWMT_BOUNCE
    LWCI_speed		word	LW_MEDIUM_SPEED
    LWCI_format		LWFormatType LWFT_TEXT
LWClass	endc

;==============================================================================
;
;		     Document format definitions.
;
;==============================================================================
LWDocumentMap0	struc	; protocol 1.0 map definition
    LWDM0_block		word		; starting VM block of gstring
    LWDM0_width		word		; width of graphic
    LWDM0_height	word		; height of graphic
LWDocumentMap0	ends

LWDocumentMap	struc
    LWDM_block		word		; starting VM block of gstring
    LWDM_width		word		; width of graphic
    LWDM_height		word		; height of graphic
    LWDM_options	LWInstance
    LWDM_text		char	LW_MAX_LENGTH+1 dup(?)
LWDocumentMap	ends

LW_DOCUMENT_PROTOCOL_MAJOR	equ	1
LW_DOCUMENT_PROTOCOL_MINOR	equ	1

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	lastwords.rdef

idata	segment
mapData	LWDocumentMap	<>
idata	ends

udata	segment

;
; Data describing the message we move around.
;
msg		LWStruct

msgText		char	LW_MAX_LENGTH+1 dup(?)

;
; Current window and gstate to use for drawing.
;
curWindow	hptr.Window
curGState	hptr.GState

;
; Timer we started for drawing a new line
;
curTimer	hptr.HandleTimer
curTimerID	word

;
; Duplicated options block, for fetching the message to display.
;
optionsBlock	hptr
shortFontsChunk	word
longFontsChunk	word

;
; Block holding the App DC
; 
appDocBlock	hptr
docFile		hptr.HandleFile
docObj		optr

;
; Graphic being drawn
; 
gstringHandle	hptr

;
; Flags to determine whether pasting is possible.
;
pflags	LWPasteFlags	<>

udata	ends

idata	segment

;
; Declare the class record for our auxiliary process class.
;
LWClass	mask CLASSF_NEVER_SAVED

;
; Format of data actually being drawn -- may be different from LWCI_format if
; no gstring is in the graphicFile.
; 
drawFormat	LWFormatType	LWFT_TEXT

startProcs	nptr	LWStartText,
			LWStartGraphic,
			LWStartTime,
			LWStartDate

stopProcs	nptr	LWStopText,
			LWStopGraphic,
			LWStopText,
			LWStopText

idata	ends

;==============================================================================
;
;		   EXTERNAL WELL-DEFINED INTERFACE
;
;==============================================================================

LWInitExit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a single LWStruct

CALLED BY:	LWStart
PASS:		ax	= left edge
		bx	= top edge
		cx	= right edge
		dx	= bottom edge
		es:di	= LWStruct to initialize
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWInit	proc	near
		uses	dx
		.enter

		DoPush	ax, cx		; save x borders

		mov	cx, bx		; cx <- ymin
		mov	ax, SVRT_RANDOM
		mov	bx, (LW_DELTA_BASE shl 8) or LW_DELTA_MAX

		add	di, offset LWS_y
		call	SaverVectorInit

		DoPopRV	cx, dx		; recover X borders
		add	di, offset LWS_x - offset LWS_y
		call	SaverVectorInit

		sub	di, offset LWS_x
		mov	ax, ds:[mapData.LWDM_options].LWCI_angle
		mov	es:[di].LWS_lastAngle.WWF_int, ax

		mov	es:[di].LWS_drawn, 0		; signal none drawn

		.leave
		ret
LWInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWLoadGString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the gstring stored in the passed file.

CALLED BY:	LWStartGraphic, LWPasteGraphic
PASS:		ds	= dgroup
		bx	= VM file handle
RETURN:		si	= gstring handle (0 if couldn't load it)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWLoadGString proc	near
		uses	es, di, cx, ax, bp
		.enter
	;
	; Fetch the parameters of the gstring.
	;
		call	VMGetMapBlock
		tst	ax
		jz	fail		; no map block => no gstring

		call	VMLock
		segmov	es, ds
		mov	ds, ax
		mov	di, offset mapData
		clr	si
		mov	cx, size mapData
		rep	movsb
		call	VMUnlock
		segmov	ds, es
		
		mov	ax, ds:[mapData].LWDM_block
		tst	ax		; no starting block => no gstring
		jz	fail
	;
	; Load up the gstring stored in the file and return its handle in si
	;
		xchg	si, ax
		mov	cl, GST_VMEM
		call	GrLoadString
done:
		.leave
		ret
fail:
		clr	si
		jmp	done
LWLoadGString endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWComputeBorders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the boundaries within which the text is allowed to
		be placed.

CALLED BY:	LWStart
PASS:		ax	= window width
		bx	= window height
		cx	= text width
		dx	= text height
		ds	= dgroup
		di	= gstate w/rotation, etc., set.
RETURN:		ax	= left edge
		bx	= top edge
		cx	= right edge
		dx	= bottom edge
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWComputeBorders	proc	near
wWidth		local	word push ax
wHeight		local	word push bx
tWidth		local	word push cx
tHeight		local	word push dx

xmin		local	sword
xmax		local	sword
ymin		local	sword
ymax		local	sword
		uses	si
		.enter

		clr	si		; (0,0) always transforms to (0,0),
		mov	ss:[xmax], si	;  so initialize min/max vars as if
		mov	ss:[ymax], si	;  we actually went through the work
		mov	ss:[xmin], si	;  of transforming the little beggar.
		mov	ss:[ymin], si
	;
	; If random, let it run wild...for now.
	;
		tst	ds:[mapData.LWDM_options].LWCI_angle
		js	computeBounds
	
	;
	; Transform the remaining three corners and compute the min and
	; max in each direction...
	;
		mov	ax, ss:[tWidth]	; upper right
		clr	bx
		call	checkMinMax
		
		mov	ax, ss:[tWidth]
		mov	bx, ss:[tHeight]
		call	checkMinMax

		clr	ax
		mov	bx, ss:[tHeight]
		call	checkMinMax
		
	;
	; Using the mins and maxes just computed, figure the borders for the
	; whole shebang.
	;
computeBounds:
		clr	ax
		mov	bx, ax
		mov	cx, ss:[wWidth]
		mov	dx, ss:[wHeight]
		
		sub	ax, ss:[xmin]
		sub	bx, ss:[ymin]
		sub	cx, ss:[xmax]
		sub	dx, ss:[ymax]
	;
	; Make sure the mins are actually less than the maxes
	;
		cmp	ax, cx
		jle	checkYBounds
		mov	cx, ax
		inc	cx		; must be at least 1 or SaverRandom will
					;  choke later on...
checkYBounds:
		cmp	bx, dx
		jle	done
		mov	dx, bx
		inc	dx		; must be at least 1...
done:
		.leave
		ret

	;
	; Subroutine to adjust mins and maxes appropriately for an untransformed
	; coordinate.
	;
	;	Pass:	(ax, bx)	= coordinate to transform
	;		di		= gstate
	;	Return:	nothing
	;	Destroyed: ax, bx
	;
checkMinMax:
		call	GrTransformCoord

		cmp	ax, ss:[xmin]
		jge	checkXMax
		mov	ss:[xmin], ax
		jmp	checkY
checkXMax:
		cmp	ax, ss:[xmax]
		jle	checkY
		mov	ss:[xmax], ax

checkY:
		cmp	bx, ss:[ymin]
		jge	checkYMax
		mov	ss:[ymin], bx
		jmp	doneCheck
checkYMax:
		cmp	bx, ss:[ymax]
		jle	doneCheck
		mov	ss:[ymax], bx
doneCheck:
		retn
LWComputeBorders	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWStartText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the screen saver for a text message.

CALLED BY:	LWStart
PASS:		ds	= dgroup
		si	= LWFT_TEXT
RETURN:		si	= LWFormatType being drawn
		cx	= width of message
		dx	= height of message
DESTROYED:	ax, bx, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWStartText proc	near
		.enter
	;
	; Fetch the text to display.
	;
		mov	cx, ds
		mov	dx, offset msgText
		mov	ax, METHOD_GET_TEXT
		mov	bx, ds:[optionsBlock]
		mov	si, offset LWText
		mov	di, mask MF_CALL
		call	ObjMessage
		call	FigureTextDimensions
		mov	si, LWFT_TEXT
		.leave
		ret
LWStartText endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureTextDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the dimensions of the text in the msgText buffer

CALLED BY:	LWStartText, LWStartTime, LWStartDate
PASS:		ds:msgText = Text to use
RETURN:		cx	   = Width of message
		dx	   = Height of message
DESTROYED:	ax, bx, di, si, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureTextDimensions	proc	near
	;
	; Figure the dimensions of the string so it doesn't go bouncing off
	; screen a lot...of course, just knowing the dimensions doesn't help;
	; we also subtract the width and height of the string from the width
	; and height of our drawing area as well...eventually.
	;
		mov	di, ds:[curGState]
		mov	si, offset msgText
		mov	cx, -1
		call	GrTextWidth
		mov	cx, dx

	;
	; Use the pointsize of the font as the height.
	;
		mov	dx, ds:[mapData.LWDM_options].LWCI_size
		shr	dx
		shr	dx
		shr	dx
		ret
FigureTextDimensions	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWStartGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the saver to use a graphic string message

CALLED BY:	LWStart
PASS:		ds	= dgroup
		si	= LWFT_GRAPHIC
RETURN:		si	= actual LWFormatType being drawn
		cx	= message width
		dx	= message height
DESTROYED:	ax, bx, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWStartGraphic proc near
		uses	es
		.enter
		mov	bx, ds:[docFile]
		tst	bx
		jz	useTextInstead
		
		call	LWLoadGString
		tst	si
		jz	useTextInstead

		mov	ds:[gstringHandle], si
	;
	; Load the parameters into registers.
	;
		mov	cx, ds:[mapData].LWDM_width
		mov	dx, ds:[mapData].LWDM_height
		mov	si, LWFT_GRAPHIC
done:
		.leave
		ret

	;
	; Graphic string didn't pan out -- just call our textual counterpart
	; to use the text message instead.
	;
useTextInstead:
		call	LWStartText
		jmp	done
LWStartGraphic endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWStartTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the saver to use the current time

CALLED BY:	LWStart
PASS:		ds	= dgroup
		si	= LWFT_TIME
RETURN:		si	= actual LWFormatType being drawn
		cx	= message width
		dx	= message height
DESTROYED:	ax, bx, di, bp

PSEUDO CODE/STRATEGY:
	Format a time string and call FigureTextDimensions

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWStartTime	proc	near
	mov	si, TIME_FORMAT		; si <- format to use
	call	GetCurrentDateTime	; Get the current date/time string

	call	FigureTextDimensions
	mov	si, LWFT_TIME
	ret
LWStartTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWStartDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the saver to use the current date

CALLED BY:	LWStart
PASS:		ds	= dgroup
		si	= LWFT_DATE
RETURN:		si	= actual LWFormatType being drawn
		cx	= message width
		dx	= message height
DESTROYED:	ax, bx, di, bp

PSEUDO CODE/STRATEGY:
	Format a time string and call FigureTextDimensions

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWStartDate	proc	near
	mov	si, DATE_FORMAT		; si <- format to use
	call	GetCurrentDateTime	; Get the current date/time string

	call	FigureTextDimensions
	mov	si, LWFT_DATE
	ret
LWStartDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	Generic screen saver library
PASS:		cx	= window handle
		dx	= window height
		si	= window width
		di	= gstate handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWStart	proc	far
		uses	ax, bx, cx, dx, ds, es
		.enter
		call	SaverInitBlank
		segmov	ds, dgroup, ax
		mov	es, ax
	;
	; Save the window and gstate we were given for later use.
	;
		mov	ds:[curWindow], cx
		mov	ds:[curGState], di

		DoPush	dx, si


	;
	; Initialize the GState to Nice Values.
	;

if 0	; The video drivers don't XOR regular characters, only region
	; ones... Sigh. -- ardeb 4/28/91

	;
	; We always draw in XOR mode for easy erasure.
	;
		mov	ax, MODE_XOR
		call	GrSetDrawMode
endif
	;
	; The font and pointsize don't change, so set them both now.
	;
		mov	cx, ds:[mapData.LWDM_options].LWCI_fontID
		mov	dx, ds:[mapData.LWDM_options].LWCI_size
		clr	ah
		shr	dx
		rcr	ah
		shr	dx
		rcr	ah
		shr	dx
		rcr	ah
		call	GrSetFont

	;
	; If the angle is constant, set it now and forget about it.
	;
		mov	dx, ds:[mapData.LWDM_options].LWCI_angle
		tst	dx
		js	getText			; => random
		clr	cx			; no fraction
		call	GrApplyRotation

getText:
		mov	si, ds:[mapData.LWDM_options].LWCI_format
		call	ds:[startProcs][si]

		DoPopRV	bx, ax
		mov	ds:[drawFormat], si
		call	LWComputeBorders

	;
	; Initialize the message.
	;
		mov	di, offset msg
		call	LWInit

	;
	; Draw the thing first. This will start up the redraw timer.
	;
		call	LWDraw

		.leave
		ret
LWStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWStopText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after displaying a text message.

CALLED BY:	LWStop
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWStopText	proc	near
		.enter
		; nothing to do here
		.leave
		ret
LWStopText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWStopGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after displaying a gstring message.

CALLED BY:	LWStop
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWStopGraphic proc near
		uses	di, dx
		.enter
	;
	; Nuke the gstring, leaving its data in the file, of course.
	;
		mov	di, ds:[gstringHandle]
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyString

		mov	ds:[gstringHandle], 0
		.leave
		ret
LWStopGraphic endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop drawing a LWStruct.

CALLED BY:	Parent library
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWStop	proc	far
		uses	ds, bx, ax
		.enter
		segmov	ds, dgroup, ax
	
	;
	; Stop the draw timer we started.
	;
		mov	bx, ds:[curTimer]
		mov	ax, ds:[curTimerID]
		call	TimerStop
	
	;
	; Finish up the drawing in whatever way is necessary.
	;
		mov	si, ds:[drawFormat]
		call	ds:[stopProcs][si]

	;
	; And mark the window and gstate as no longer existing.
	;
		clr	ax
		mov	ds:[curWindow], ax
		mov	ds:[curGState], ax

		.leave
		ret
LWStop	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWCreateFontLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the two font lists in the duplicated block.

CALLED BY:	LWFetchUI, LWRestoreState
PASS:		bx	= handle of duplicated block
		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWCreateFontLists	proc	near
		.enter
		push	bx
	;
	; Copy the short fonts list into the block as the first child of the
	; Fonts menu.
	;
		mov	cx, bx
		mov	dx, offset LWFonts
		mov	bp, CompChildFlags <0, CCO_FIRST>
		mov	bx, handle LWShortFontsList
		mov	si, offset LWShortFontsList
		mov	ax, METHOD_GEN_COPY_TREE
		mov	di, mask MF_CALL
		call	ObjMessage
		
	;
	; Set its action descriptor properly. Can only rely on generic library
	; to fill in the output after a SF_FETCH_UI when we're first loaded,
	; not when we rebuild this list after restoring from state, so we set
	; the thing explicitly here.
	; 
		mov	ax, METHOD_GEN_LIST_SET_ACTION
		mov	bx, cx
		mov	si, dx
		
		mov	cx, handle saver		; cx <- od handle
		mov	dx, enum LWSetFont		; dx <- od chunk (entry
							;  num of routine to
							;  call)
		mov	bp, METHOD_SAVER_CALL_SPECIFIC	; bp <- message
		mov	di, mask MF_CALL
		call	ObjMessage
		
	;
	; Now call UserFontCreateList to find all the useful outline fonts and
	; add them to the list we just copied in.
	;
		mov	ds:[shortFontsChunk], si	;  save for removal
		
		mov	cl, LW_MAX_MENU_FONTS
		mov	dl, mask FEF_OUTLINES or mask FEF_USEFUL
		call	UserFontCreateList
	
	;
	; Copy the long fonts list into the block as the first child of
	; the More Fonts box.
	;
		pop	cx
		mov	dx, offset LWMoreFontsBox
		mov	bp, CompChildFlags <0, CCO_FIRST>
		mov	bx, handle LWLongFontsList
		mov	si, offset LWLongFontsList
		mov	ax, METHOD_GEN_COPY_TREE
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Set its action descriptor properly. (see above)
	; 
		mov	ax, METHOD_GEN_LIST_SET_ACTION
		mov	bx, cx
		mov	si, dx
		
		mov	cx, handle saver		; cx <- od handle
		mov	dx, enum LWSetListFont	; dx <- od chunk (entry
							;  num of routine to
							;  call)
		mov	bp, METHOD_SAVER_CALL_SPECIFIC	; bp <- message
		mov	di, mask MF_CALL
		call	ObjMessage
		
	;
	; Now call UserFontCreateList to find all the outline fonts, useful
	; or not, and add them to the list we just copied in.
	;
		mov	ds:[longFontsChunk], si
		
		mov	cl, LW_MAX_FONTS
		mov	dl, mask FEF_OUTLINES
		call	UserFontCreateList
		.leave
		ret
LWCreateFontLists	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWFetchUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the tree of options that affect how this thing
		performs.

CALLED BY:	Saver library
PASS:		nothing
RETURN:		^lcx:dx	= root of option tree to add
		ax	= first entry point stored in OD's in the tree
		bx	= last entry point stored in OD's in the tree
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWFetchUI	proc	far
		uses	bp, si, di, ds
		.enter
		segmov	ds, dgroup, ax
	;
	; Duplicate the app-run block.
	;
		mov	bx, handle saver
		call	ProcInfo		; bx <- first thread of saver
		mov	si, bx			;  lib

		mov	bx, handle LWDocumentUI
		mov	ax, handle saver
		call	ObjDuplicateBlock
		
		mov	ds:[appDocBlock], bx
		mov	ah, MODIFY_OTHER
		call	MemModify		; set the thread to run the
						;  block to be the saver.
	;
	; Tell the App DC to let us know about anything important.
	;
		mov	si, offset LWAppDocumentControl
		mov	ax, METHOD_APP_DOC_CONTROL_SET_OUTPUT
		mov	cx, handle saver
		clr	dx
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Duplicate the UI-run block.
	;
		mov	bx, handle LWOptions
		mov	ax, handle saver	; owned by the saver library so
						;  it can get into a state file
		call	ObjDuplicateBlock
		mov	ds:[optionsBlock], bx

	;
	; Create lists for the available fonts.
	;
		call	LWCreateFontLists

		mov	cx, ds:[mapData.LWDM_options].LWCI_fontID
		call	LWSetFont

	;
	; Point the document controls at each other.
	;
		mov	cx, bx
		mov	dx, offset LWUIDocumentControl

		mov	bx, ds:[appDocBlock]
		mov	si, offset LWAppDocumentControl
		mov	ax, METHOD_SADC_SET_UI_DC
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		
		mov	bx, ds:[optionsBlock]
		mov	si, offset LWUIDocumentControl
	;
	; Switch the DC to our current directory (in which screen savers lie)
	;
		mov	cx, PATH_BUFFER_SIZE
		sub	sp, cx
		mov	dx, sp
		DoPush	bx,si		; save optr
		mov	si, dx
		segmov	ds, ss
		call	FileGetCurrentPath
		mov	cx, ds		; cx:dx <- path
		mov	bp, bx		; bp <- disk handle

		DoPopRV	bx,si		; recover optr
		mov	ax, METHOD_UI_DOC_CONTROL_SET_PATH
		mov	di, mask MF_CALL
		call	ObjMessage
		add	sp, PATH_BUFFER_SIZE
	;
	; Finish setting return values.
	;
		mov	cx, bx
		mov	dx, offset LWRoot
		mov	ax, enum LWSetFont		; first entry point used
							;  in OD's
		mov	bx, enum LWPasteGraphic	; last entry point used
							;  in OD's
		.leave
		ret
LWFetchUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWFetchHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the help UI

CALLED BY:	Saver library
PASS:		nothing
RETURN:		^lcx:dx	= root of UI tree to add (cx == 0 for none)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	 3/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWFetchHelp	proc	far
	.enter

	mov	bx, handle LWHelp
	mov	ax, handle saver		;ax <- owned by 'saver'
	call	ObjDuplicateBlock
	;
	; Return in ^lcx:dx
	;
	mov	cx, bx
	mov	dx, offset HelpBox

	.leave
	ret
LWFetchHelp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSaveState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add our little state block to that saved by the generic
		saver library.

CALLED BY:	SF_SAVE_STATE
PASS:		cx	= handle of block to which to append our state
		dx	= first available byte in the block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSaveState proc	far
		uses	cx, di, es, ds, si, bp
		.enter
		segmov	ds, dgroup, ax
		mov	bx, ds:[optionsBlock]
		
		DoPush	cx, dx
	;
	; Remove the short fonts list from the Fonts menu -- it'll get biffed
	; by the kernel since it's marked ignoreDirty
	;
		mov	si, ds:[shortFontsChunk]
		mov	ax, METHOD_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL
		call	ObjMessage

		mov	cx, bx
		mov	dx, si
		mov	si, offset LWFonts
		mov	ax, METHOD_REMOVE_GEN_CHILD
		mov	bp, mask CCF_MARK_DIRTY
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Do similarly for the long fonts list, but from the More Fonts box,
	; of course.
	;
		mov	si, ds:[longFontsChunk]
		mov	ax, METHOD_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL
		call	ObjMessage

		mov	cx, bx
		mov	dx, si
		mov	si, offset LWMoreFontsBox
		mov	ax, METHOD_REMOVE_GEN_CHILD
		mov	bp, mask CCF_MARK_DIRTY
		mov	di, mask MF_CALL
		call	ObjMessage

		DoPopRV	cx, dx
	;
	; Enlarge the block to hold our state information.
	;
		mov	bx, cx
		mov	ax, dx
		add	ax, size LWInstance + size word
		mov	ch, mask HAF_LOCK
		call	MemReAlloc
		jc	done
	;
	; Copy our state block to the passed offset within the block.
	;
		mov	es, ax
		mov	di, dx
		segmov	ds, dgroup, si
		mov	si, offset mapData.LWDM_options
		mov	ax, size mapData.LWDM_options
		stosw		; save the size of the saved state first
		xchg	cx, ax
		rep	movsb
	;
	; Done with the block, so unlock it.
	;
		call	MemUnlock

	;
	; Clear out appDocBlock so we know not to destroy it.
	;
		mov	ds:[appDocBlock], 0
done:
		.leave
		ret
LWSaveState endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWWriteDocumentMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a map block for the current graphics string.

CALLED BY:	LWSaveState, LWPasteGraphic, LWEntry
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWWriteDocumentMap	proc	near
		uses	ax, bx, cx, dx, es, di, si, bp
		.enter
		mov	bx, ds:[docFile]
		tst	bx
		jz	done

		call	VMGetMapBlock
		tst	ax
		jnz	haveMapBlock
	;
	; Allocate a new block for the map data.
	;
		mov	cx, size LWDocumentMap
		call	VMAlloc
		call	VMSetMapBlock
haveMapBlock:
	;
	; Lock down the map block and copy in the current map information.
	;
		call	VMLock
		mov	es, ax
		clr	di
		mov	si, offset mapData
		mov	cx, size LWDocumentMap
		rep	movsb
	;
	; Fetch the current message text as well, marking the object as clean
	; again.
	; 
		push	bp
		mov	bx, ds:[optionsBlock]
		mov	si, offset LWText
		mov	ax, METHOD_SET_CLEAN
		mov	di, mask MF_CALL
		call	ObjMessage

		mov	cx, es
		mov	dx, offset LWDM_text
		mov	di, mask  MF_CALL
		mov	ax, METHOD_GET_TEXT
		call	ObjMessage
		pop	bp

		call	VMDirty
		call	VMUnlock
done:
		.leave
		ret
LWWriteDocumentMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWReadDocumentMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read parameters from the map of our current (and only)
		document.

CALLED BY:	LWDCFileAvail, LWDCRevertPart2
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
mrdmMapOffsets	word	LWCI_size, LWCI_motion, LWCI_speed, LWCI_format
mrdmObjOffsets	word	LWSizes, LWMotion, LWSpeed,
			LWFormatList
CheckHack <length mrdmObjOffsets eq length mrdmMapOffsets>
LWReadDocumentMap proc	near
		uses	ax, bx, cx, dx, es, di, si, bp
header		local	GeosFileHeader
		.enter
		mov	bx, ds:[docFile]
EC <		tst	bx						>
EC <		ERROR_Z	GASP_CHOKE_WHEEZE				>

		push	ds
		segmov	ds, ss
		lea	dx, ss:[header]
		call	VMGetHeader
		
		cmp	ss:[header].GFH_core.GFHC_protocol.PN_minor, 
			LW_DOCUMENT_PROTOCOL_MINOR
		je	fetchMapBlock
		
	;
	; The document needs to be upgraded to contain the new options that
	; are written to the map block now. First set the document protocol
	; to match.
	; 
		mov	ss:[header].GFH_core.GFHC_protocol.PN_minor,
			LW_DOCUMENT_PROTOCOL_MINOR
		call	VMSetHeader
		call	VMGetMapBlock
		tst	ax
		jz	writeNewMap

		push	bp
		call	VMLock
	;
	; Copy out the data for the gstring into our internal variable.
	; 
		mov	ds, ax
		clr	si
		mov	di, offset mapData
		mov	cx, size LWDocumentMap0
		rep	movsb
	;
	; Now enlarge the map block to hold the new stuff.
	; 
		xchg	bx, bp
		mov	ax, size LWDocumentMap
		mov	cx, mask HAF_ZERO_INIT shl 8
		call	MemReAlloc
		xchg	bx, bp
		call	VMDirty
		call	VMUnlock
		pop	bp
writeNewMap:
		segmov	ds, es
		call	LWWriteDocumentMap
	;
	; queue a SAVE message to the document object so user can't
	; revert to old format.
	;
		push	bx
		mov	bx, ds:[appDocBlock]
		mov	si, offset LWAppDocumentControl
		mov	ax, METHOD_APP_DOC_CONTROL_SAVE_DOC
		clr	cx
		mov	dx, cx
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	bx
fetchMapBlock:
		pop	ds
	;
	; Copy the data from the map block to our internal variable.
	; 
		call	VMGetMapBlock
EC <		tst	ax						>
EC <		ERROR_Z	GASP_CHOKE_WHEEZE				>
		push	bp
		call	VMLock
		push	bp
		mov	bx, es:[optionsBlock]
		mov	ds, ax

		clr	si
		mov	di, offset mapData
		mov	cx, size mapData
		rep	movsb
	;
	; Now set up all the lists and whatnot to reflect the new options
	; that have hereby been selected. First come the easy ones: the
	; option is a word that can be passed to the list, and it'll map
	; to the correct entry.
	; 
		mov	si, offset mrdmMapOffsets
		mov	cx, length mrdmMapOffsets
basicListLoop:
		push	cx
		lodsw	cs:
		push	si
		xchg	di, ax
		mov	cx, {word}ds:[LWDM_options][di]
		mov	si, cs:[si-2+(mrdmObjOffsets-mrdmMapOffsets)]
		call	LWSetListExcl
		pop	si
		pop	cx
		loop	basicListLoop
		
	;
	; Next comes the color, which is weird because it's sometimes a word
	; value (-1 => random), but is stored as a byte.
	; 
		mov	al, ds:[LWDM_options].LWCI_color
		cbw		; deal with -1 => random
		xchg	cx, ax
		mov	si, offset LWColor
		call	LWSetListExcl
	;
	; Angle is also strange, as -1 has special meaning (=> random) and
	; we have to set two UI items based on LWCI_angle (the Random list
	; entry and the angle GenRange). When the list entry is selected, the
	; range must be disabled, and vice versa. We must pass SUPPRESS_APPLY
	; in the setting of the entry to avoid dirtying the document right
	; away when reverting, so we must do the enable/disable of the range
	; by hand...
	; 
		mov	cx, ds:[LWDM_options].LWCI_angle
		cmp	cx, -1
		je	angleRandom
		mov	si, offset LWAngleRange
		mov	ax, METHOD_RANGE_SET_VALUE
		clr	bp
		clr	di
		call	ObjMessage
		
		mov	ax, METHOD_GEN_LIST_ENTRY_DESELECT
		mov	cx, METHOD_GEN_SET_ENABLED
		jmp	setAngleList
angleRandom:
		mov	ax, METHOD_GEN_LIST_ENTRY_SELECT
		mov	cx, METHOD_GEN_SET_NOT_ENABLED

setAngleList:
		mov	si, offset LWRandomAngle
		mov	bp, mask LF_REFERENCE_ACTUAL_EXCL or \
			    mask LF_REFERENCE_USER_EXCL or \
			    mask LF_SUPPRESS_APPLY
		clr	di
		push	cx
		call	ObjMessage
		pop	ax		; ax <- enable/disable message
		mov	si, offset LWAngleRange
		mov	dl, VUM_NOW
		call	ObjMessage

handleFont:
	;
	; Penultimately, set the font lists to the ID that was stored.
	; 
		mov	cx, ds:[LWDM_options].LWCI_fontID
		mov	si, es:[shortFontsChunk]
		call	LWSetListExcl
		
		mov	si, es:[longFontsChunk]
		call	LWSetListExcl
	;
	; And finally, change the message text, in case we're in text mode,
	; marking the text object as clean so we get notified when the
	; user changes it.
	; 
		mov	ax, METHOD_SET_DIRTY	; mark object dirty first
		mov	si, offset LWText	;  so we don't get told
		clr	di			;  about our modification
		call	ObjMessage		;  of the object

		mov	dx, ds
		mov	bp, offset LWDM_text
		clr	cx
		mov	ax, METHOD_SET_TEXT
		mov	si, offset LWText
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	ax, METHOD_SET_CLEAN
		clr	di
		call	ObjMessage
		pop	bp
		call	VMUnlock
		pop	bp
	;
	; Flag document as available and update the Paste and Graphic things
	; in our UI...
	; 
		segmov	ds, es
		ornf	ds:[pflags], mask LWPF_HAVE_DOCUMENT
		call	LWSetPasteState
		.leave
		ret
LWReadDocumentMap endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetListExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the exclusive for the passed list to the one with the
		passed data in its method instance variable

CALLED BY:	INTERNAL
PASS:		^lbx:si	= list to which to send it
		cx	= value contained in entry that's to take the exclusive
RETURN:		nothing
DESTROYED:	ax, di destroyed

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetListExcl proc	near
		uses	bp
		.enter
		mov	bp, mask LF_REFERENCE_ACTUAL_EXCL or \
				mask LF_REFERENCE_USER_EXCL or \
				(LET_ENTRY_DATA shl offset LF_ENTRY_TYPE) or \
				mask LF_SUPPRESS_APPLY
		mov	ax, METHOD_GEN_LIST_SET_EXCL
		clr	di
		call	ObjMessage
		.leave
		ret
LWSetListExcl endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWRestoreState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore our little state block from that saved by the generic
		saver library.

CALLED BY:	SF_RESTORE_STATE
PASS:		cx	= handle of block from which to retrieve our state
		dx	= start of our data in the block
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWRestoreState	proc	far
		uses	cx, dx, di, es, ds, si, bp
		.enter
	;
	; Lock down the block that holds our state information.
	;
		mov	bx, cx
		call	MemLock
		jc	done
		mov	ds, ax
	;
	; Copy our state block from the passed offset within the block.
	;
		segmov	es, dgroup, di
		mov	di, offset mapData.LWDM_options
		mov	cx, size mapData.LWDM_options
		mov	si, dx

		lodsw			; make sure the state is the right
					;  size.
		cmp	ax, cx
		jne	unlock		; if not, abort the restore
		rep	movsb
	;
	; Done with the block, so unlock it.
	;
unlock:
		call	MemUnlock
	;
	; Find the options block.
	;
		call	SaverFindOptions
		jc	done
		segmov	ds, dgroup, ax
		mov	ds:[optionsBlock], cx
		mov	bx, cx
		call	LWCreateFontLists

	;
	; Locate the application document block by asking the ui DC for
	; the app DC's location.
	;
		mov	si, offset LWUIDocumentControl
		mov	ax, METHOD_SUIDC_GET_APP_DC
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	ds:[appDocBlock], cx
done:
		.leave
		ret
LWRestoreState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetPasteState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the enabled/disabled state of the Graphic and Paste
		items in our UI based on ds:[pflags]

CALLED BY:	INTERNAL
PASS:		ds	= dgroup
		pflags	= set
RETURN:		nothing
DESTROYED:	ax, cx, dx, si, di, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetPasteState proc near
		uses	bp
		.enter
	;
	; First the Paste trigger.
	;
		mov	ax, METHOD_GEN_SET_NOT_ENABLED
		test	ds:[pflags], mask LWPF_HAVE_DOCUMENT or \
					mask LWPF_TRANSFER_IS_GRAPHIC
		jz	setPaste	; neither set
		jpo	setPaste	; only one set

		; both flags set, so can paste
		mov	ax, METHOD_GEN_SET_ENABLED
setPaste:
		mov	dl, VUM_NOW
		mov	bx, ds:[optionsBlock]
		mov	si, offset LWPaste
		clr	di
		call	ObjMessage
	;
	; Now the Graphic entry, enabled only if we have a document with a
	; graphic string in it.
	;
		mov	ax, METHOD_GEN_SET_NOT_ENABLED
		test	ds:[pflags], mask LWPF_HAVE_DOCUMENT
		jz	setGraphic
		tst	ds:[mapData].LWDM_block
		jz	setGraphic
		mov	ax, METHOD_GEN_SET_ENABLED
setGraphic:
		mov	si, offset LWFormatGraphic
		mov	di, mask MF_CALL
		call	ObjMessage		; dl still VUM_NOW, since
						;  di was 0 in above call
	;
	; Re-instate Graphic as exclusive if it was disabled and is now
	; enabled...
	;
		mov	cx, ds:[mapData.LWDM_options].LWCI_format
		mov	si, offset LWFormatList
		mov	bp, mask LF_REFERENCE_ACTUAL_EXCL or \
				mask LF_REFERENCE_USER_EXCL or \
				(LET_ENTRY_DATA shl offset LF_ENTRY_TYPE) or \
				mask LF_SUPPRESS_APPLY
		mov	ax, METHOD_GEN_LIST_SET_EXCL
		clr	di
		call	ObjMessage

		.leave
		ret
LWSetPasteState endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWDCFileAttachFailed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that the previous gstring message could not be 
		reopened.

CALLED BY:	LWAppDocumentControl
PASS:		ds 	= saver's dgroup
		es 	= dgroup
		cx:dx	= document object
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWDCFileAttachFailed method LWClass, METHOD_DC_FILE_ATTACH_FAILED
		.enter
		segmov	ds, es
	;
	; Set our internal state to be text format, since we can't get the
	; previous gstring.
	;
		mov	ds:[mapData.LWDM_options].LWCI_format, LWFT_TEXT
		mov	cx, LWFT_TEXT
	;
	; Then set the format list to reflect reality. We don't want to
	; suppress the apply as we want to enable/disable things correctly.
	;
		mov	bx, ds:[optionsBlock]
		mov	si, offset LWFormatList
		mov	bp, mask LF_REFERENCE_ACTUAL_EXCL or \
				mask LF_REFERENCE_USER_EXCL or \
				(LET_ENTRY_DATA shl offset LF_ENTRY_TYPE)
		mov	ax, METHOD_GEN_LIST_SET_EXCL
		clr	di
		call	ObjMessage
	;
	; Change the state of the Paste trigger accordingly.
	;
		andnf	ds:[pflags], not mask LWPF_HAVE_DOCUMENT
		call	LWSetPasteState		
		.leave
		ret
LWDCFileAttachFailed endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWDCFileAvail
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that a gstring file is open for business.

CALLED BY:	METHOD_DC_FILE_NEW, METHOD_DC_FILE_OPEN
PASS:		ds 	= saver's dgroup
		es 	= dgroup
		^lcx:dx	= document object
		bp	= file handle
RETURN:		carry set if error
DESTROYED:	ax, cx, dx, bp, if I want

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWDCFileAvail method LWClass, METHOD_DC_FILE_NEW, METHOD_DC_FILE_OPEN
		.enter
		segmov	ds, es
		mov	ds:[docFile], bp
		mov	ds:[docObj].chunk, dx
		mov	ds:[docObj].handle, cx
		cmp	ax, METHOD_DC_FILE_NEW
		jne	setPaste
	;
	; For a new document, we must set the VMA_NOTIFY_DIRTY bit so we can
	; tell the DC the thing's dirty...
	;
		mov	bx, bp
		mov	ax, mask VMA_NOTIFY_DIRTY
		call	VMSetAttributes
		
	;
	; Write the current options out to the new file.
	; 
		mov	ds:[mapData].LWDM_block, 0	; flag no gstring yet
		call	LWWriteDocumentMap
		
	;
        ; "save" the file so that if we get a "revert" we will revert to this
        ; state. Note that the method must pass through the queue b/c our
        ; manipulations of the file will have caused a VM_FILE_DIRTY method to
        ; be queued for us, so if we just ObjMessage here, we'll set
        ; the document clean, then set it dirty when the VM_FILE_DIRTY method
        ; arrives, which isn't what we want.
	;
		mov	bx, cx
		mov	si, dx
		mov	di, mask MF_FORCE_QUEUE
		mov	ax, METHOD_DOCUMENT_SAVE
		call	ObjMessage
setPaste:
	;
	; Read everything from the map block and act on it.
	;
		call	LWReadDocumentMap

		clc	; no error
		.leave
		ret
LWDCFileAvail endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWDCFileClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the current file is going away.

CALLED BY:	METHOD_DC_FILE_CLOSE
PASS:		ds 	= saver's dgroup
		es 	= dgroup
		^lcx:dx	= document object
		bp	= file handle
RETURN:		carry set if error
DESTROYED:	ax, cx, dx, bp, if I want

PSEUDO CODE/STRATEGY:
		Note: this is not done on DC_FILE_CLOSE to prevent disabling
		the Graphic entry just because a new file is going to be
		opened.
		
		Note II: this used to be done on DC_FILE_USER_CLOSE, but that
		gets sent out *before* the check for a dirty document, so when
		the save-as or save comes in, we think we have no document
		and end up with things (like the text) not properly updated.
		The user will just have to live with the Graphic entry being
		disabled.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWDCFileClose method LWClass, METHOD_DC_FILE_CLOSE
		.enter
		segmov	ds, es
		mov	ds:[docFile], 0
		mov	ds:[docObj].handle, 0
	;
	; Disable the Graphic list entry again...
	;
		andnf	ds:[pflags], not mask LWPF_HAVE_DOCUMENT
		call	LWSetPasteState

		clc	; no error
		.leave
		ret
LWDCFileClose endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWDCRevertPart2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle the reversion of a file to a previous state.

CALLED BY:	METHOD_DC_FILE_REVERT_PART_2
PASS:		^lcx:dx	= document object
		bp	= file handle
		ds 	= saver's dgroup
		es 	= dgroup
RETURN:		carry set if error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 9/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWDCRevertPart2 method dynamic LWClass, METHOD_DC_FILE_REVERT_PART_2
		.enter
		segmov	ds, es
		call	LWReadDocumentMap
		clc
		.leave
		ret
LWDCRevertPart2 endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWDCFileSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the document up-to-date by fetching the current
		message text and writing it to the map block.

CALLED BY:	METHOD_DC_FILE_SAVE
PASS:		ds	= saver's dgroup
		es	= dgroup
		^lcx:dx	= document object
		bp	 = file handle
RETURN:		carry set if error
		ax	= zero to send a message through the queue to finish
			  the save. We always do this to deal with our
			  updating of the map block having dirtied the file.
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWDCFileSave method dynamic LWClass, METHOD_DC_FILE_SAVE, 
		  		METHOD_DC_FILE_SAVE_AS_PART_1
		.enter
	;
	; Write the map out.
	; 
		segmov	ds, es
		call	LWWriteDocumentMap
	;
	; Queue a message to finish the save/save as, please, to deal with
	; the NOTIFY_DIRTY that could well be in our queue.
	; 
		clr	ax
		.leave
		ret
LWDCFileSave endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWDCSaveAsPart2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of the new file handle for our document.

CALLED BY:	METHOD_DC_FILE_SAVE_AS_PART_2
PASS:		ds	= saver's dgroup
		es	= dgroup
		^lcx:dx	= document object
		bp	= new file handle
RETURN:		carry set if error
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWDCSaveAsPart2 method dynamic LWClass, METHOD_DC_FILE_SAVE_AS_PART_2
		.enter
	;
	; Just need to save the file handle away for later use.
	; 
 		mov	es:[docFile], bp
		clc
		.leave
		ret
LWDCSaveAsPart2 endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWTextMadeDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the message text object has been sullied by marking
		the document dirty.

CALLED BY:	METHOD_TEXT_MADE_DIRTY
PASS:		ds	= saver's dgroup
		es	= dgroup
		^lcx:dx	= dirty text object
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWTextMadeDirty method dynamic LWClass, METHOD_TEXT_MADE_DIRTY
		.enter
		
		mov	bx, es:[appDocBlock]
		mov	si, offset LWAppDocumentControl
		mov	ax, METHOD_APP_DOC_CONTROL_MARK_DIRTY
		clr	cx
		mov	dx, cx			; mark target doc dirty
		mov	di, mask MF_CALL
		call	ObjMessage
		.leave
		ret
LWTextMadeDirty endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save any extra options that need saving.

CALLED BY:	Generic saver library
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSaveOptions proc	far
		.enter
		clc
		.leave
		ret
LWSaveOptions endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for the kernel's benefit

CALLED BY:	kernel
PASS:		di	= LibraryCallTypes
		cx	= handle of client, if LCT_NEW_CLIENT or LCT_CLIENT_EXIT
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWEntry	proc	far
		uses	ds, si, cx, dx, ax, bp, es, bx
		.enter
		cmp	di, LCT_ATTACH
		jne	checkDetach
		segmov	es, dgroup, cx	; es, cx <- dgroup
	;
	; Set our auxiliary process class in the generic library.
	;
		mov	dx, offset LWClass
		call	SaverSetSpecProcClass

	;
	; Put ourselves in the transfer-notification list.
	;
		mov	bx, handle saver
		call	ProcInfo
		mov	cx, bx
		clr	dx
		call	ClipboardAddToNotificationList
done:
		.leave
		clc		; no errors
		ret
checkDetach:
		cmp	di, LCT_DETACH
		jne	done
	;
	; Remove ourselves from the transfer-notification list.
	;
		mov	bx, handle saver
		call	ProcInfo
		mov	cx, bx
		clr	dx
		call	ClipboardRemoveFromNotificationList
	;
	; Remove our process class from the generic library.
	;
		clr	cx
		mov	dx, cx
		call	SaverSetSpecProcClass
	;
	; Document was closed by generic library sending DETACH to our ui DC.
	; 
		mov	bx, ds:[appDocBlock]
		tst	bx
		jz	done

		mov	ax, METHOD_FREE_DUPLICATE
		mov	si, offset LWAppDocumentControl
		clr	di
		call	ObjMessage
		jmp	done
LWEntry	endp

ForceRef LWEntry

LWInitExit	ends

;==============================================================================
;
;		    DRAWING ROUTINES/ENTRY POINTS
;
;==============================================================================

LWCode		segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot to draw again later

CALLED BY:	LWStart, LWDraw
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LWSetTimer	proc	near
		.enter
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, ds:[mapData.LWDM_options].LWCI_speed
		mov	dx, enum LWDraw

		call	SaverStartTimer
		mov	ds:[curTimer], bx
		mov	ds:[curTimerID], ax
		.leave
		ret
LWSetTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWDrawItDude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the current text string nicely.

CALLED BY:	LWDrawOne
PASS:		ds	= dgroup
		ax	= Colors
		cx	= x coord
		dx	= y coord
		si	= angle (-1 for none)
		di	= gstate
RETURN:		nothing
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWDrawItDude proc	near
		uses	bx, si, bp
		.enter
	;
	; Set the drawing transformation back to its default.
	;
		call	GrSetDefaultTransform
	;
	; Set the color to that passed.
	;
		call	GrSetTextColor
		call	GrSetAreaColor
		push	ax
	;
	; Translate the origin to the coordinate at which to draw the text, so
	; when we rotate, the text still appears there.
	;
		mov	bx, dx
		mov	dx, cx
		clr	ax
		mov	cx, ax
		call	GrApplyTranslation
	;
	; Apply any rotation that needs applying.
	;
		tst	si
		js	rotateDone
		mov	dx, si
		clr	cx
		call	GrApplyRotation

rotateDone:
		pop	ax
		cmp	ds:[drawFormat], LWFT_GRAPHIC
		je	drawGraphic
	;
	; Draw the text at (0,0). The message is null-terminated, as you'd
	; expect.
	;
		clr	cx
		mov	ax, cx
		mov	bx, cx
		mov	si, offset msgText
		call	GrDrawText
done:
		.leave
		ret
drawGraphic:
		cmp	ax, BLACK
		je	eraseGraphic
		
	;
	; Rewind the gstring and draw it to the target at (0, 0).
	;
		mov	si, ds:[gstringHandle]
		mov	al, GSSPT_BEGINNING
		call	GrSetStringPos
		
		clr	ax
		mov	bx, ax
if 0
		; must save state to prevent default transform from shifting
		; to hell and (not) back.
		clr	bp		; draw whole thing
else
		mov	bp, mask GSC_SAVE_STATE
endif
		call	GrDrawString
		jmp	done

eraseGraphic:
	;
	; Just fill a rectangle the size of the graphic with black.
	;
		mov	ax, -2		; allow for bitmap-rotation greebles
		mov	bx, -2		; allow for bitmap-rotation greebles
		mov	cx, ds:[mapData].LWDM_width
		mov	dx, ds:[mapData].LWDM_height
		sub	cx, ax		; allow for bitmap-rotation greebles
		sub	dx, bx		; allow for bitmap-rotation greebles
		call	GrFillRect
		jmp	done
LWDrawItDude endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWDrawOne
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the message once

CALLED BY:	LWDraw
PASS:		ds:bx	= LWStruct to update
		es	= dgroup
		di	= gstate through which to draw
RETURN:		nothing
DESTROYED:	ax, dx, gstate text color

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWDrawOne	proc	near
		uses	cx, si
		.enter
		
		mov	cx, ds:[bx].LWS_x.SV_point
		mov	dx, ds:[bx].LWS_y.SV_point
		mov	si, ds:[bx].LWS_lastAngle.WWF_int
		mov	ax, BLACK
		tst	ds:[bx].LWS_drawn
		jz	setAngle

		call	LWDrawItDude
		
	;
	; Set the angle properly.
	;
setAngle:

		mov	si, es:[mapData.LWDM_options].LWCI_angle
		tst	si
		jns	checkColor

		mov	dx, 360
		call	SaverRandom
		mov	si, dx
		mov	ds:[bx].LWS_lastAngle.WWF_int, dx
		
	;
	; Choose the correct color for the next drawing.
	;
checkColor:
		clr	ax
		mov	al, es:[mapData.LWDM_options].LWCI_color
		tst	al
		jns	setColor
				CheckHack <BLACK eq 0>
		mov	dx, Colors-1
		call	SaverRandom
		inc	dx		; avoid black...
		xchg	ax, dx
setColor:
		mov	ds:[bx].LWS_lastColor, al
		push	ax		
	;
	; Figure the next position for the text string.
	;
		cmp	es:[mapData.LWDM_options].LWCI_motion, LWMT_BOUNCE
		je	update
	;
	; Not LWMT_BOUNCE, so must be LWMT_RANDOM. Randomize the vectors.
	; XXX: have a function in "saver" to do this?
	;
		mov	dx, ds:[bx].LWS_x.SV_max
		sub	dx, ds:[bx].LWS_x.SV_min
		call	SaverRandom
		add	dx, ds:[bx].LWS_x.SV_min
		mov	ds:[bx].LWS_x.SV_point, dx
		
		mov	dx, ds:[bx].LWS_y.SV_max
		sub	dx, ds:[bx].LWS_y.SV_min
		call	SaverRandom
		add	dx, ds:[bx].LWS_y.SV_min
		mov	ds:[bx].LWS_y.SV_point, dx
		jmp	drawIt

update:
	;
	; LWMT_BOUNCE: advance the vectors one step.
	;
		push	si
		lea	si, ds:[bx].LWS_x
		call	SaverVectorUpdate

		lea	si, ds:[bx].LWS_y
		call	SaverVectorUpdate
		pop	si

drawIt:
	;
	; Choose the string to draw if it's date or time.
	;
		call	ChooseStringToDraw	; Choose the text string...

		pop	ax			; recover color
		mov	cx, ds:[bx].LWS_x.SV_point
		mov	dx, ds:[bx].LWS_y.SV_point
		call	LWDrawItDude
	;
	; Flag message as drawn.
	;
		mov	ds:[bx].LWS_drawn, -1
		.leave
		ret
LWDrawOne	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next LWStruct line.

CALLED BY:	timer
PASS:		nothing
RETURN:		nothing
DESTROYED:	anything I want

PSEUDO CODE/STRATEGY:
	This routine *must* be sure there's still a gstate around, as there
	is no synchronization provided by our parent to deal with timer
	methods that have already been queued after the SAVER_STOP method
	is received.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWDraw	proc	far
		.enter
		segmov	ds, dgroup, ax
		mov	es, ax
		
		mov	di, ds:[curGState]
		tst	di
		jz	done

		mov	bx, offset msg
		call	LWDrawOne
	;
	; Set another timer to draw
	;
		call	LWSetTimer
done:
		.leave
		ret
LWDraw	endp
public	LWDraw


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseStringToDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose the string to draw if it's time/date

CALLED BY:	LWDraw
PASS:		ds	= dgroup
RETURN:		msgText	= Text to draw
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChooseStringToDraw	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	;
	; If we're doing a date or time, get the formatted string to use
	; It's hokey... There should be a table here, but I'm too lazy
	; to add one.
	;
	mov	si, TIME_FORMAT		; Assume time format
	cmp	ds:drawFormat, LWFT_TIME
	je	setString		; Branch if is time

	mov	si, DATE_FORMAT		; Assume date format
	cmp	ds:drawFormat, LWFT_DATE
	jne	gotString		; Branch if nothing special

setString:
	call	GetCurrentDateTime	; Get formatted string to use

gotString:
	.leave
	ret
ChooseStringToDraw	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a formatted date/time into msgText

CALLED BY:	LWStartDate, LWStartTime
PASS:		ds	= dgroup
		si	= DTF_* format
		es:di	= Buffer to fill
RETURN:		ds:msgText holds the formatted text
		cx	= Length of the text
DESTROYED:	ax, bx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurrentDateTime	proc	far
	call	TimerGetDateAndTime	; Get information for formatting
		;
		; ax - year (1980 through 2099)
		; bl - month (1 through 12)
		; bh - day (1 through 31)
		; cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
		; ch - hours (0 through 23)
		; dl - minutes (0 through 59)
		; dh - seconds (0 through 59)
		;
	mov	bp, offset msgText	; es:bp <- ptr to buffer
	mov	di, DR_LOCAL_FORMAT_DATE_TIME
	call	SysLocalInfo
	ret
GetCurrentDateTime	endp

LWCode	ends
;==============================================================================
;
;		    UI ACTION HANDLER ENTRY POINTS
;
;==============================================================================
LWInitExit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWUpdateFontSample
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the font displayed by the sample display

CALLED BY:	SLCallSpecific
PASS:		cx	= font ID to display
RETURN:		ds	= dgroup
DESTROYED:	ax, bx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWUpdateFontSample	proc	far
		.enter
		mov	bp, cx		; bp <- font ID
		segmov	ds, dgroup, ax
		mov	bx, ds:[optionsBlock]
		mov	si, offset LWFontSampleTextDisplay
		mov	ax, METHOD_SET_FONT
		clr	di
		call	ObjMessage
		.leave
		ret
LWUpdateFontSample	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWUpdateFontSampleInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special internal function to queue a call to
		LWUpdateFontSample to get around a death when the
		font is set in LWFetchUI and the generic library
		hasn't called its superclass yet, so no ui data are defined
		for the beast. 

CALLED BY:	LWSetListFont, LWSetFont
PASS:		cx	= font ID to display
RETURN:		nothing
DESTROYED:	ax, bx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWUpdateFontSampleInt proc near
		mov	bx, handle saver
		mov	si, enum LWUpdateFontSample
		mov	ax, METHOD_SAVER_CALL_SPECIFIC
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		ret
LWUpdateFontSampleInt endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetListFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notice a change in the More Fonts list.

CALLED BY:	?
PASS:		cx	= font ID
		bp	= ListUpdateFlags
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetListFont proc	far
		.enter
		test	bp, (mask LUF_DEFAULT_ACTION_REQUEST) shl 8
		jnz	done
		
		test	bp, (mask LUF_ACTUAL_CHANGE) shl 8
		jnz	actual
		
	;
	; Just a user-visible change, so update the font sample.
	;
		call	LWUpdateFontSampleInt
done:
		.leave
		ret
actual:
	;
	; Actual change -- record it.
	;
		FALL_THRU	LWSetFont
LWSetListFont endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the font we use for drawing messages.

CALLED BY:	LWShortFontsList, LWLongFontsList
PASS:		cx	= font ID
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetFont	proc	far
		.enter
		segmov	ds, dgroup, ax
		mov	ds:[mapData.LWDM_options].LWCI_fontID, cx
		call	LWWriteDocumentMap
		
		call	LWUpdateFontSampleInt
		
	;
	; Set both font lists to reflect reality, but don't send us a message,
	; thanks.
	;
		mov	bp, mask LF_REFERENCE_ACTUAL_EXCL or \
			    mask LF_REFERENCE_USER_EXCL or \
			    (LET_ENTRY_DATA shl offset LF_ENTRY_TYPE) or \
			    mask LF_SUPPRESS_APPLY
		mov	bx, ds:[optionsBlock]
		mov	si, ds:[longFontsChunk]
		mov	ax, METHOD_GEN_LIST_SET_EXCL
		clr	di
		call	ObjMessage
		
		mov	si, ds:[shortFontsChunk]
		clr	di
		mov	ax, METHOD_GEN_LIST_SET_EXCL
		call	ObjMessage
		.leave
		ret
LWSetFont	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the point size we'll be using.

CALLED BY:	LWSizesList, LWPointSizeDistance
PASS:		cx	= integer point size * 8
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetSize	proc	far
		.enter
		segmov	ds, dgroup, ax
		mov	ds:[mapData.LWDM_options].LWCI_size, cx
		call	LWWriteDocumentMap
	;
	; Set the sizes list to reflect reality, in case this came from
	; the custom size box, but don't notify us of any change, thanks.
	;
		mov	bp, mask LF_REFERENCE_ACTUAL_EXCL or \
			    mask LF_REFERENCE_USER_EXCL or \
			    (LET_ENTRY_DATA shl offset LF_ENTRY_TYPE) or \
			    mask LF_SUPPRESS_APPLY
		mov	bx, ds:[optionsBlock]
		mov	si, offset LWSizesList
		mov	ax, METHOD_GEN_LIST_SET_EXCL
		clr	di
		call	ObjMessage

	;
	; Do the same for the range, in case we were called from the list.
	;
		mov	ax, METHOD_RANGE_SET_VALUE
		mov	si, offset LWPointSizeRange
		clr	di
		call	ObjMessage	; XXX: this will get reset if
					;  options were saved...
		.leave
		ret
LWSetSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetAngleRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the angle at which to draw things. If that angle
		is random (cx == -1), disable the angle range.

CALLED BY:	LWAngleList, LWAngleRange
PASS:		cx	= angle. If -1:
			bp.high	= ListUpdateFlags
			bp.low	= ListEntryState
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetAngleRandom proc	far
		.enter
		segmov	ds, dgroup, ax

		cmp	cx, -1
		je	random

	;
	; If no change from current, do nothing. (Happens during revert...)
	; 
		cmp	ds:[mapData].LWDM_options.LWCI_angle, cx
		je	done

		mov	ds:[mapData.LWDM_options].LWCI_angle, cx
		call	LWWriteDocumentMap

done:
		.leave
		ret

random:
		mov	cx, bp
	;
	; Assume random angles are enabled.
	;		
		mov	bx, ds:[optionsBlock]
		mov	si, offset LWAngleRange
		mov	ax, METHOD_GEN_SET_NOT_ENABLED
		test	cl, mask LES_ACTUAL_EXCL
		mov	cx, -1
		jnz	enableDisable
	;
	; Wrong. Since randomness is disabled, fetch the current value of
	; the range and store that, instead of -1.
	;
		mov	ax, METHOD_RANGE_GET_VALUE
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	ax, METHOD_GEN_SET_ENABLED
enableDisable:
	;
	; cx = value to actually set the angle to, now we know whether
	; the Random list entry is selected or not.
	; 
		mov	ds:[mapData.LWDM_options].LWCI_angle, cx
		call	LWWriteDocumentMap
	;
	; Enable or disable the angle range, as appropriate.
	;
		mov	dl, VUM_NOW
		mov	di, mask MF_CALL
		call	ObjMessage
		jmp	done		
LWSetAngleRandom endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the color or randomness thereof

CALLED BY:	LWColor
PASS:		cx	= color index, or -1 for random
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetColor	proc	far
		.enter
		segmov	ds, dgroup, ax
		mov	ds:[mapData.LWDM_options].LWCI_color, cl
		call	LWWriteDocumentMap
		.leave
		ret
LWSetColor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetSpeed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the number of ticks between movements.

CALLED BY:	LWSpeed
PASS:		cx	= ticks (yuck)
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetSpeed proc	far
		.enter
		segmov	ds, dgroup, ax
		mov	ds:[mapData.LWDM_options].LWCI_speed, cx
		call	LWWriteDocumentMap
		.leave
		ret
LWSetSpeed endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetMotion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the type of motion the message is to undergo

CALLED BY:	LWMotion
PASS:		cx	= LWMotionTypes
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetMotion proc	far
		.enter
		segmov	ds, dgroup, ax
		mov	ds:[mapData.LWDM_options].LWCI_motion, cx
		call	LWWriteDocumentMap
		.leave
		ret
LWSetMotion endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the format of message to display, text or graphic

CALLED BY:	LWFormatList
PASS:		cx	= LWFormatTypes
		bp.low	= ListEntryState
		bp.high	= ListUpdateFlags
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWSetFormat proc	far
		.enter
	;
	; If we're being told there's no exclusive (LES_ACTUAL_EXCL is clear),
	; just ignore it, as we're probably changing files, or something.
	; 
		test	bp, mask LES_ACTUAL_EXCL
		jz	done

		segmov	ds, dgroup, ax
		mov	ds:[mapData.LWDM_options].LWCI_format, cx
		call	LWWriteDocumentMap
done:
		.leave
		ret
LWSetFormat endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWNotifyTransferItemChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that the normal transfer item has changed. If it's
		got a gstring format, we can paste it in, so enable the
		Paste trigger. If not, disable the beast.

CALLED BY:	METHOD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
PASS:		ds 	= saver's dgroup
		es 	= dgroup
		^lcx:dx	= object to enable/disable based on transfer state
			  (0 for none) (how does it know?)
RETURN:		cx	= non-zero if paste possible (?)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWNotifyTransferItemChanged method LWClass,
				 METHOD_NOTIFY_NORMAL_TRANSFER_ITEM_CHANGED
formats		local	CLIPBOARD_MAX_FORMATS dup(ClipboardItemFormats)
vmFile		local	hptr
vmBlock		local	word
numFormats	local	word
		uses	cx, es, di, si, dx, bp
		.enter
		segmov	ds, dgroup, cx	; ds <- our dgroup, not saver's
		segmov	es, ss
	;
	; Find the formats that are available from the clipboard's normal
	; transfer item.
	;
		lea	di, ss:[formats]
		push	bp
		clr	bp		; normal transfer item, please
		call	ClipboardQueryItem
		mov	cx, bp		; don't need the owner, so transfer
					;  format count to cx instead.
		pop	bp
	;
	; See if the graphics-string format is available, as that's the only
	; one we support.
	;
		mov	ss:[vmFile], bx
		mov	ss:[vmBlock], ax
		mov	ax, CIF_GRAPHICS_STRING
		jcxz	gstringNotAvail
		repne	scasw
		jne	gstringNotAvail
		ornf	ds:[pflags], mask LWPF_TRANSFER_IS_GRAPHIC
enableDisable:
		call	LWSetPasteState
	;
	; Let the clipboard know we're done with the thing.
	;
		mov	bx, ss:[vmFile]
		mov	ax, ss:[vmBlock]
		clr	cx		; normal item
		call	ClipboardDoneWithItem
		.leave
		ret
gstringNotAvail:
		andnf	ds:[pflags], not mask LWPF_TRANSFER_IS_GRAPHIC
		jmp	enableDisable
LWNotifyTransferItemChanged endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWPasteGraphic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the current graphic string from the clipboard and
		use that for our message.

CALLED BY:	LWPaste
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/30/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWPasteGraphic proc	far
formats		local	CLIPBOARD_MAX_FORMATS dup(ClipboardItemFormats)
vmFile		local	hptr
vmBlock		local	word
graphicFile	local	hptr
		uses	ds, cx, es, di, si, dx, bp
		.enter
		segmov	ds, dgroup, ax
		test	ds:[pflags], mask LWPF_HAVE_DOCUMENT or \
					mask LWPF_TRANSFER_IS_GRAPHIC
		jpe	ok		; => both or neither set
fail:
		jmp	done
ok:
		jz	fail

		segmov	es, ss
	;
	; Get the file and block for the normal transfer item.
	; XXX: I know the format I want is in there, so why do I need to
	; get the formats too?
	;
		lea	di, ss:[formats]
		push	bp
		clr	bp		; normal transfer item, please
		call	ClipboardQueryItem
		mov	cx, bp		; don't need the owner, so transfer
					;  format count to cx instead.
		pop	bp

		mov	ss:[vmFile], bx
		mov	ss:[vmBlock], ax

		mov	bx, ds:[docFile]
EC <		tst	bx						>
EC <		ERROR_Z	GASP_CHOKE_WHEEZE				>
		mov	ss:[graphicFile], bx
   
   		call	LWLoadGString
		tst	si
		jz	copyString
		
		mov	di, si
		mov	dl, GSKT_KILL_DATA
		call	GrDestroyString
		mov	ds:[mapData].LWDM_block, 0
copyString:
	;
	; Fetch the data for the gstring from the clipboard.
	;
		push	bp
		mov	bx, ss:[vmFile]
		mov	ax, ss:[vmBlock]
		mov	cx, CIF_GRAPHICS_STRING
		call	ClipboardRequestItemFormat
		pop	bp
		tst	ax		; we were lied to -- all the data for
					;  the previous string are gone, so
					;  just write out a map block with
					;  no gstring. we can handle it...
		jz	updateMapBlock
	;
	; Save the width and height for drawing.
	;
		mov	ds:[mapData].LWDM_width, cx
		mov	ds:[mapData].LWDM_height, dx
	;
	; Load the clipboard gstring into memory.
	;
		xchg	si, ax		; (1-byte inst)
		mov	cl, GST_VMEM
		call	GrLoadString
		push	si
	;
	; Allocate the initial block for our gstring.
	;
		mov	bx, ss:[graphicFile]
		mov	cx, LW_GSTRING_BLOCK_SIZE
		call	VMAlloc
		mov	ds:[mapData].LWDM_block, ax
		xchg	si, ax		; (1-byte inst)
	;
	; Create the new gstring with the block just allocated.
	;
		mov	ax, LW_GSTRING_BLOCK_SIZE
		mov	cl, GST_VMEM
		call	GrBeginString
		pop	si
	;
	; Copy the clipboard string into the new one.
	;		
		clr	cx		; just do the whole thing
		call	GrCopyString	; XXX: trim out escapes?
		; XXX: look for GS_FAULT
		call	GrEndString
	;
	; Nuke the gstring structures now -- we'll rebuild them in
	; LWStartGraphic.
	; 
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyString
	;
	; Unload the clipboard gstring, but don't destroy it.
	;
		mov	di, si
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyString

updateMapBlock:
	;
	; Tell the clipboard we're done.
	;
		mov	bx, ss:[vmFile]
		mov	ax, ss:[vmBlock]
		clr	cx		; normal item
		call	ClipboardDoneWithItem
	;
	; Write the map block out now.
	;
		call	LWWriteDocumentMap
	;
	; Enable Graphic format entry now we've a gstring.
	; 
		call	LWSetPasteState
done:
		.leave
		ret
LWPasteGraphic endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LWVMFileDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that our document is dirty and let the document control
		know it too.

CALLED BY:	METHOD_VM_FILE_DIRTY
PASS:		ds 	= saver's dgroup
		es 	= dgroup
		cx	= file handle
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LWVMFileDirty method LWClass, METHOD_VM_FILE_DIRTY
		segmov	ds, es
		mov	bx, ds:[appDocBlock]
		mov	si, offset LWAppDocumentControl
		mov	ax, METHOD_APP_DOC_CONTROL_MARK_DIRTY_BY_FILE
		clr	di
		GOTO	ObjMessage
LWVMFileDirty endp

LWInitExit	ends
