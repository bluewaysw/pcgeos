COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		bannerPrint
FILE:		bannerPrint.asm

ROUTINES:

Name				Description
----				-----------
BannerGetDocName................Tell the spooler the name of the document
BannerPrint.....................Prep the call to BannerDraw for printer output
BannerPrintLoop.................
BannerPrintPrepareBannerDraw....Sets up variables for printing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Roger	10/10/90	Initial version, cut from banner.asm
	stevey	10/19/92	port to 2.0
	witt	11/03/93	DBCS-ized GetDosName

DESCRIPTION:
	This file contains the extra code necessary for printing.  It is
	included by banner.asm

	$Id: bannerPrint.asm,v 1.1 97/04/04 14:37:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerGetDocName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the spooler the name of the document

CALLED BY:	MSG_PRINTING_GET_DOC_NAME

PASS:		cx:dx	- PrintControl OD
		bp	- method to send back to the SpoolPrintControl
			  (MSG_SPOOL_PRINT_CONTROL_SET_DOC_NAME)
		es:	- idata segment

RETURN:		nothing
DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

	The string should be of the format "Banner message..." where
	the ... appear if the name is too long to fit within the 32 character
	limit.

	- get the banner string
	- start the copy with a "
	- copy
	- place ... if needed
	- close with a quote
	- Send it off to the spooler (via a method CALL)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	10/9/90		Initial version
	roger	10/10/90	Customized for banner
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerGetDocName	method	BannerClass,	
					MSG_PRINT_GET_DOC_NAME

	bannerName		local	FileLongName
	bannerStringStart	local	nptr	; ss: pointer
	bannerSuffixLength	local	byte
	bannerPrintPass		local	byte
	bannerEndQuote		local	word

	.enter

	;
	; we want to figure out if the banner is single height, or if double
	; height, which pass is printing (top/bottom)
	;

	clr	bannerSuffixLength		; default
	test	ds:[di].BI_specialEffects, mask SE_DOUBLE_HEIGHT
	jnz	notSingleHeight

	mov	bannerPrintPass, ONLY_PRINT_PASS
	jmp	short	passRemembered

notSingleHeight:
	;
	; fetch the length of the longest suffix and keep it because we
	; destroy the pointer to idata
	;
	mov	al, es:[longestPrintedDocNameSuffix]
	mov	bannerSuffixLength, al

	test	ds:[di].BI_bannerState, mask BS_PRINT_PASS
	jnz	bottomPass

	mov	bannerPrintPass, TOP_PRINT_PASS
	jmp	short	passRemembered

bottomPass:
	mov	bannerPrintPass, BOTTOM_PRINT_PASS

passRemembered:
	;
	; get the banner message	; sets ds, returns cx, dx also
	;
	call	BannerGetTextString	; dx = block handle, cx = length
	push	dx			; save the text block handle
	mov	bx, dx
	call	MemLock
	mov	ds, ax			; ds:0 = string
	clr	si			; ds:si = string

	;
	; set up the destination string
	;

	segmov	es, ss, ax
	lea	di, bannerName			; es:di = destination buffer
	mov	bx, di
SBCS<	add	bx, BANNER_NAME_END_QUOTE	; bx is end quote position  >
DBCS<	add	bx, BANNER_NAME_END_QUOTE*(size wchar)			    >

	;
	;  If the banner is double height then it is printed in two passes,
	;  each a separate document.  Label each document by adding (top)
	;  or (bottom) to the appropiate pass.
	;
	;  To do this, we need to leave room at the end.  Subtract the size
	;  of the suffix from the end quote position to leave the room.
	;	bx = & buffer[ (bufferLen - 2) - bannerSuffixLength ]

if DBCS_PCGEOS
	clr	ah
	mov	al, bannerSuffixLength
	shl	ax, 1			; ax <- suffix string size
	sub	bx, ax
else
	sub	bl, bannerSuffixLength
endif
	mov	bannerStringStart, di
	
	;
	; get localized version of the double quotes
	;

	push	bx, cx
	call	LocalGetQuotes		; cx = front double, dx = end double
	mov	ax, cx			; start string with front double quote
	mov	bannerEndQuote, dx
	pop	bx, cx
	LocalPutChar	esdi, ax	; put in the quote (updates es:di)

	;
	; if there isn't a string then just send ""0, skip copy
	;

	tst	cx			; string length
	jz	placeQuote

copyLoop:
	;				
	; loop to copy string to stack
	;
	LocalGetChar	ax, dssi
SBCS<	mov	{char} es:[di], al					>
DBCS<	mov	{wchar} es:[di], ax					>
	LocalCmpChar	ax, C_NULL
	je	placeQuote
	cmp	di, bx			; did we run out of room?
	je	placeEllipses
	LocalNextChar	esdi
	jmp	short	copyLoop

placeEllipses:
	mov	di, bx			; where to put ellipsis
	LocalPrevChar	esdi		; put ellipsis before end quote
SBCS<	mov	al, C_ELLIPSIS						>
DBCS<	mov	ax, C_HORIZONTAL_ELLIPSIS				>
	LocalPutChar	esdi, ax

placeQuote:
	mov	ax, bannerEndQuote
	LocalPutChar	esdi, ax
	LocalLoadChar	ax, C_NULL
	LocalPutChar	esdi, ax

	pop	bx			; pushed as dx (text block handle)
	tst	bx
	jz	noHandleToFree

	call	MemFree			; done with the banner message string

noHandleToFree:
	;
	; if this is a double height banner, append either a ' (top)' or
	; ' (bottom)' string

	mov	al, ONLY_PRINT_PASS
	cmp	al, bannerPrintPass
	je	dontAddSuffix

	LocalPrevChar	esdi			; backup over the C_NULL

	;
	; Access the strings block
	;
	mov	bx, handle BannerStrings
	call	MemLock	; lock the block
	mov	ds, ax

	mov	al, bannerPrintPass
	cmp	al, TOP_PRINT_PASS
	jne	getBottomSuffix

	mov	si, offset BannerStrings:topPostfix
	jmp	short	suffixDereferenced

getBottomSuffix:
	mov	si, offset BannerStrings:bottomPostfix

suffixDereferenced:

	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx	; byte size => cx
if DBCS_PCGEOS
	rep	movsb			; copy string *and* C_NULL
else
	dec	cx			; don't count the NULL
	rep	movsb			; move the bytes
	mov	al, C_NULL
	stosb
endif

	;
	;  Now clean up
	;
	mov	bx, handle BannerStrings; get the block handle
	call	MemUnlock		; unlock the block

dontAddSuffix:
	;
	;  Simply point to an existing string, and send it to the spooler
	;  cx:dx is the string ss:bannerName
	;

	mov	cx, ss
	mov	dx, bannerStringStart		; cx:dx = string buffer
	GetResourceHandleNS	BannerPrintControl, bx
	mov	si, offset	BannerPrintControl
	mov	di, mask MF_CALL
	mov	ax, MSG_PRINT_CONTROL_SET_DOC_NAME
	call	ObjMessage

	.leave
	ret
BannerGetDocName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WarnIfNoText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays a dialog box warning the user that s/he 
		tried to print a null-string banner.

CALLED BY:	BPrintControlVerifyPrintRequest
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	11/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WarnIfNoText	proc	near
	uses	ax,bx,si,ds
	.enter
	;
	; Bring up dialog if necessary
	;
	clr	ax
	pushdw	axax		; don't care about SDOP_helpContext
	pushdw	axax		; don't care about SDOP_customTriggers
	pushdw	axax		; don't care about SDOP_stringArg2
	pushdw	axax		; don't care about SDOP_stringArg1

	mov	bx, handle BannerStrings
	call	MemLock		; lock the resource block
	mov	ds, ax
	mov	si, offset BannerStrings:noTextWarningString
	mov	si, ds:[si]	; point to the string
	pushdw	dssi		; save SDOP_customString

	mov	bx, CustomDialogBoxFlags <
				TRUE,
				CDT_WARNING,
				GIT_NOTIFICATION,
				0
		>
	push	bx		; save SDOP_customFlags
	call	UserStandardDialog
	mov	bx, handle BannerStrings
	call	MemUnlock	; unlock the resource

	.leave
	ret
WarnIfNoText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BPrintControlVerifyPrintRequest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that there's text to print

CALLED BY:	MSG_PRINT_VERIFY_PRINT_REQUEST
PASS:		*ds:si	= BannerClass object
		ds:di	= BannerClass instance data
		ds:bx	= BannerClass object (same as *ds:si)
		es 	= segment of BannerClass
		ax	= message #

		cx:dx - OD of PrintControlClass object to reply to

RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	11/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BPrintControlVerifyPrintRequest	method dynamic BannerClass, 
					MSG_PRINT_VERIFY_PRINT_REQUEST
	uses	ax, cx
	.enter
	pushdw	cxdx			; save OD of PrintControlClass
	call	BannerGetTextString	; get the text to print
	jcxz	noText			; is length 0?

	mov	cx, TRUE		; everything's ok.
returnFlag:
	popdw	bxsi			; OD of PrintControlClass
	mov	ax, MSG_PRINT_CONTROL_VERIFY_COMPLETED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
noText:
	call	WarnIfNoText		; put up dialog box
	clr	cx			; cancel printint (FALSE)
	jmp	returnFlag

BPrintControlVerifyPrintRequest	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the print job started.

CALLED BY:	MSG_PRINT_START_PRINTING

PASS:		*ds:si	= BannerClass object
		ds:[di]	= BannerClass instance data
		cx:dx	= PrintControl to respond to
		bp	= GState to print to

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	- call BannerPrint, more or less.  I added this routine to
	break up BannerPrint a little, and get rid of the multiple
	.leave statements that were confusing me.

	- restore the instance data for displaying the banner
	- tell the spooler we're done
	- if we're printing double-height, start 2nd pass

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	When we print the banner, we destroy the info used to display
	the banner on the screen.  Once we're done printing we restore
	the instance data for displaying the banner.  The best way to
	do this is save the height of the banner and recalculate stuff
	by passing the height to BannerMaximizeTextHeight. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/28/92	initial version
	dhunter	6/26/2000	Use temporary GState to recalc instance data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerStartPrinting	method dynamic BannerClass, 
					MSG_PRINT_START_PRINTING
	.enter

	push	si			; save chunk handle of Banner object
	pushdw	cxdx			; save PrintControl OD
	mov	dx, ds:[di].BI_height	; save the height of the old data
	call	BannerPrint
	push	ax			; save # of pages

	;
	;  After printing we restore the instance data for displaying
	;  the banner on the screen.  We call BannerCalcTextWidth to
	;  initialize BI_width and BI_endSpace, and since this routine
	;  returns a mem handle (to the text string) we have to free it.
	;
	;  We would like the graphics routines called by BannerCalcTextWidth
	;  to NOT append their commands to the printer GString.  Otherwise,
	;  the spooler would print an extra page, not knowing the garbage
	;  following the final GrNewPage doesn't really render anything.
	;  Create a temporary GState and free it when we're done computing.
	;

	push	bp			 ; save printing GState
	xchg	bp, di			 ; save di in bp
	clr	di			 ; no window, please
	call	GrCreateState		 ; di <- temporary GState
	xchg	bp, di			 ; bp = GState, di recovered
	call	BannerMaximizeTextHeight ; I'm called purely for side effects.
	call	BannerCalcTextWidth	 ; Me too, but I return bx = handle.
EC <	tst	bx			 ; text string block		>
EC <	ERROR_Z	NULL_STRING_ENCOUNTERED_WHILE_PRINTING			>
	call	MemFree			 ; free text string block
	mov	di, bp			 ; di <- temporary GState
	call	GrDestroyState		 ; free temporary GState
	pop	bp			 ; restore printing GState

	;
	;  If everything went OK we tell the print control.
	;

	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	mov	cx, 1
	pop	dx			; last page => dx
	popdw	bxsi			; PrintControl => bx:si
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage		; we're done with this job

	;
	;  If we are printing in double height we need to print the 
	;  bottom half, so set BS_PRINT_PASS and print again.
	;

	pop	di			; Banner object => *DS:DI
	mov	di, ds:[di]
	add	di, ds:[di].Banner_offset

	test	ds:[di].BI_specialEffects, mask SE_DOUBLE_HEIGHT
	jz	done			; not double-height, so done
	xornf	ds:[di].BI_bannerState, mask BS_PRINT_PASS
	test	ds:[di].BI_bannerState, mask BS_PRINT_PASS
	jz	done			; we've done two passes, so done

	mov	ax, MSG_PRINT_CONTROL_INITIATE_PRINT
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	.leave
	ret
BannerStartPrinting	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerPrint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prep the call to BannerDraw for printer output

CALLED BY:	BannerStartPrinting

PASS: 		*ds:si	= TheBanner
		ds:[di]	= BannerInstance
		bp	= GState to draw to

RETURN:		ax	= # of pages printed

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	- Set the printer attributes
	- set page info (height, border width, ...)
	- if there is no text then return carry set
	- Repeat printing, section by section

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	6/23/90		Initial version
	roger	9/9/90		new version.  Prints multiple sections.
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerPrint	proc	near
	class	BannerClass
	uses	bx,cx,dx,si,di,bp

	PV	local	PrintingVariables

	.enter

	mov	ax, ss:[bp]		; gstate
	mov	PV.gstate, ax

	call	InitializePrinter	; sets up the printer 'n' stuff

	;
	;  We want to print sections that are the same size as the paper,
	;  so we ask the spooler for the paper size.  Then we maximize
	;  the text height for the paper height, and set up our
	;  boundaries to print sections as wide as the paper. 
	;

	mov	di, ds:[si]
	add	di, ds:[di].Banner_offset

	mov	dx, PV.paperHeight	; used by BannerMaximizeTextHeight

	;
	;  Double the text height if printing double height.
	;

	test	ds:[di].BI_specialEffects, mask SE_DOUBLE_HEIGHT
	jz	doneTextHeight

	;
	;  When printing double-height text, the print system leaves
	;  two bands running across the middle of the banner due to
	;  the print margins at the bottom of the top half, and at the
	;  top of the bottom half.  Because these areas are not 
	;  printable we subtract them.  Except that somehow I didn't
	;  notice that they were commented out of the 1.2x code.  -steve
	;

	shl	dx, 1			; double it
;	sub	dx, PV.topMargin
; 	sub	dx, PV.bottomMargin
	mov	PV.paperHeight, dx

doneTextHeight:

	push	bp			; stack frame
	mov	bp, PV.gstate
	call	BannerMaximizeTextHeight; set the point size in PV.gstate
	call	BannerCalcTextWidth	; bx = handle, cx = length
	pop	bp			; stack frame

EC <	tst	bx			; text handle			>
EC <	ERROR_Z NULL_STRING_ENCOUNTERED_WHILE_PRINTING			>

	segmov	es, ds, ax		; *es:si = banner, es:[di] = instance
	call	MemLock
	mov	ds, ax			; ds:0 = string

	push	bx			; save string handle to free later

	;
	;  Set the banner up to print.
	;

	BitSet	es:[di].BI_bannerState, BS_PRINT
	
	;
	;  The section leader must fit at least one character.  To 
	;  be sure of this we make the section leader's size one greater
	;  than the widest character in the current font/point size.
	;  The EndSpace is half of the widest character in the font.
	;

	mov	ax, es:[di].BI_endSpace	; initialized by BannerCalcTextWidth
	inc	ax
	shl	ax, 1
	mov	PV.goalLeaderLength, ax	; length of widest character + 2

	;
	;  The entire length is the section length with a leader 
	;  before and after.
	;

	shl	ax, 1			; ax = 2 * leader length
	add	ax, PV.goalSectionLength
	mov	PV.entireLength, ax

	mov	ax, PV.leftMargin	; initialized in InitializePrinter
	mov	es:[di].BI_xOffset, ax	; don't leave room for the background
	mov	ax, PV.topMargin	; leave room for top margin
	test	es:[di].BI_bannerState, mask BS_PRINT_PASS
	jz	setYOffset

	;
	; set the YOffset to position the bottom half to printout
	;

	mov	ax, PV.paperHeight	; assume double height text is true
	shr	ax, 1			; print the bottom half
	neg	ax

	;
	;  When printing the bottom half, we need to shift the image past
	;  the quarter inch cutoff zone.  This space is also counted in
	;  the initial sizing.
	;
	;  NOTE: This may no longer be accurate.  But since double-height
	;  printing has not available in the UI for years, there's no
	;  point in my testing it.  So, if it becomes an option once more,
	;  this code should probably be verified. -dhunter 6/22/2000

;	add	ax, PV.topMargin
setYOffset:
	mov	es:[di].BI_yOffset, ax

	call	BannerPrintLoop

	pop	bx			; string handle
	call	MemFree
	segmov	ds, es, ax		; *ds:si = banner object
	mov	ax, PV.pageCount	; total pages in document => AX

	.leave
	ret
BannerPrint	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializePrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the printer for printing.

CALLED BY:	BannerPrint

PASS:		ss:bp = PrintingVariables

RETURN:		nothing 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Initializes:
			PV.topMargin
			PV.leftMargin
			PV.paperHeight
			PV.goalSectionLength

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/28/92		Initial version
	don	12/30/94		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitializePrinter	proc	near
	class	BannerClass
	uses	ax,bx,cx,dx,si,di
	PV	local	PrintingVariables
	.enter	inherit

	;
	; We are a non-WYSIWYG printing application, so we can use
	; a special message provided by the PrintControl to perform
	; all of the calculations we need to determine our printable
	; width & height (returned in PSR_width & PSR_height).
	;
	push	bp			; save frame pointer
	mov	ax, MSG_PRINT_CONTROL_CALC_DOC_DIMENSIONS
	GetResourceHandleNS	BannerPrintControl, bx
	mov	si, offset	BannerPrintControl
	sub	sp, size PageSizeReport
	mov	dx, ss
	mov	bp, sp			; PageSizeReport => DX:BP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	;
	; Store the resulting values into our data structure
	;
	mov	ax, ss:[bp].PSR_margins.PCMP_top
	mov	bx, ss:[bp].PSR_margins.PCMP_left
	mov	cx, ss:[bp].PSR_width.low
	mov	dx, ss:[bp].PSR_height.low
	add	sp, size PageSizeReport
	pop	bp			; restore frame pointer
	mov	PV.topMargin, ax
	mov	PV.leftMargin, bx
	mov	PV.goalSectionLength, cx
	mov	PV.paperHeight, dx

	.leave
	ret
InitializePrinter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerPrintLoop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the GString for output to spooler.

CALLED BY:	BannerPrint

PASS:		*es:si	= banner instance data
		es:[di]	= specific instance data
		ds:0	= banner message string
		bp 	= inherited stack frame

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
BannerPrintLoop()
{
	DBFixed		doc_start, string_start_in_doc;
	WBFixed        text_length, length_walked;
	char    	*end_ptr, *next_start_ptr;

	clear (doc_start);
	clear (string_start_in_doc);

	
	next_start_ptr = get_string(BannerTextEdit);
	string_start_in_doc = BI_BorderWidth + end_space;

	do this:

	call	BannerStringWalk(next_start_ptr,doc_start-SECTION_LEADER_LENGTH
			- string_start_in_doc, ROUND_DOWN, next_start_ptr, 
			length_walked);
		print_leader = doc_start - string_start_in_doc - length_walked;
		string_start_in_doc += length_walked;
		(void) BannerStringWalk(next_start_ptr, GRAPHICS_PAGE_LENGTH, 
			ROUND_UP, end_ptr, length_walked);
		doc_width = length_walked - print_leader + end_space + 
			BI_BorderWidth;		; calculates section width

		if (length_walked - leaderWidth < goalSectionLength) {
			set BS_DRAW_RIGHT_BORDER;
			; the following is true if the border extends into
			; the next section
			if (length_walked - leaderWidth > 
			    goalSectionLength - BorderWidth - EndSpace)
			   rightBorder = where the border is drawn
		}
		BannerDraw(next_start_ptr, end_ptr - next_start_ptr,
			doc_start - string_start_in_doc);

		doc_start += PRINT_SECTION_LENGTH;
	} while (not BS_DRAW_RIGHT_BORDER or rightBorder != 0);
}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	10/ 3/90	broken up from BannerPrint
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerPrintLoop	proc	near
	class	BannerClass

	PV	local	PrintingVariables

	.enter inherit

	;
	; The following section sets up the local variables 
	; for the printASection loop
	;

	clr	ax
SBCS<	mov	PV.nextStartPtr, al				>
DBCS<	mov	PV.nextStartPtr, ax				>
	mov	PV.docStart.DBF_intH, ax
	mov	PV.docStart.DBF_intL, ax
	mov	PV.docStart.DBF_frac, al
	mov	PV.stringStartInDoc.DBF_intH, ax
	mov	PV.stringStartInDoc.DBF_frac, al
	mov	PV.rightBorder, ax
	mov	PV.pageCount, ax

	;
	;  When the banner is printed in sections we must remember to 
	;  leave room for the border in the calculations.  If we start 
	;  the string's doc position variable after the border's width,
	;  all the text will be properly displaced!
	;

	mov	ax, es:[di].BI_borderWidth	; sly code
	add	ax, es:[di].BI_endSpace;	; also add this for the start
	mov	PV.stringStartInDoc.DBF_intL, ax

printASection:

	push	bp, ds				; stack frame & text string
	mov	bp, PV.gstate
	segmov	ds, es				; *ds:si = banner
	call	BannerSetFontDetails
	pop	bp, ds				; stack frame & text string

	;
	;  When doing the following DBFixed arithmetic, the result 
	;  should be just a WBFixed value.  Do the arithmetic in bx, 
	;  cx, dh, subracting with, ax/ah docStart - goalLeaderLength 
	;  - stringStartInDoc
	;
	;  Load in docStart.
	;

	mov	bx, PV.docStart.DBF_intH
	mov	cx, PV.docStart.DBF_intL
	mov	dh, PV.docStart.DBF_frac

	;
	;  Subtract stringStartInDoc.
	;

	sub	dh, PV.stringStartInDoc.DBF_frac
	sbb	cx, PV.stringStartInDoc.DBF_intL
	sbb	bx, PV.stringStartInDoc.DBF_intH

	;
	;  The result of this subtraction is a WBFixed number 
	;  (within the realm of the graphic coordinate system).  
	;  If not, then BannerStringWalk will fail because it only does 
	;  16 bit arithmetric (32 bit is too much work).
	;
	;  Since the result of the previous subtraction must be a 
	;  16bit + byte number.  This number may be either positive 
	;  or negative so the high 16 bits must either be 0000 or ffff.
	;

EC <	tst	bx							>
EC <	jz	noError							>
EC <	cmp	bx, 0xffff						>
EC <	je	noError							>
EC <	ERROR	DISTANCE_BETWEEN_DOC_AND_STRING_TOO_BIG			>
EC <noError:								>

	;
	;  Store the PV.leaderWidth.  Later we subtract the 
	;  length_walked from this and then this is copied into 
	;  BI_LeaderWidth.
	;

	movwbf	PV.leaderWidth, cxdh

	;
	; subtract goalLeaderLength
	;

	clr	ax
	sub	cx, PV.goalLeaderLength
	sbb	bx, ax

	;
	;  Call BannerStringWalk to find the character at
	;  (docSize - goalLeaderLength)
	;

	mov_tr	ax, cx
	mov	bh, dh
	mov	bl, ROUND_DOWN

	mov	cx, PV.gstate
SBCS<	clr	dh						>
SBCS<	mov	dl, PV.nextStartPtr				>
DBCS<	mov	dx, PV.nextStartPtr				>
	call	BannerStringWalk

SBCS<	mov	PV.nextStartPtr, dl		; store byte offset	>
DBCS<	mov	PV.nextStartPtr, dx		; store byte offset	>

	;
	;  leaderWidth -= lengthWalked;
	;

	subwbf	PV.leaderWidth, axbh
	
	;
	; stringStartInDoc += lengthWalked;
	;

	add	PV.stringStartInDoc.DBF_frac, bh
	adc	PV.stringStartInDoc.DBF_intL, ax
	clr	ax
	adc	PV.stringStartInDoc.DBF_intH, ax

	;
	; now that ax is trashed we might as well copy 
	; leaderWidth to BI_LeaderWidth.  This rounds the number 
	; according to the Round macro in Kernel/Graphics/graphicsMacro.def
	;

	cmp	PV.leaderWidth.WBF_frac, 80h
	mov	ax, PV.leaderWidth.WBF_int
	jb	roundedLeader
	inc	ax
roundedLeader:
	mov	es:[di].BI_leaderWidth, ax

	;
	;  Call BannerStringWalk to find out how many characters 
	;  will fit in entireLength.
	;

	mov	ax, PV.entireLength
	clr	bh
	mov	bl, ROUND_UP
	call	BannerStringWalk		; dx gets end_ptr

	;
	;  Sometimes in the last section we need to print the right 
	;  border but not any text.  In this case rightBorder equals 
	;  the border's position and not 0.  If this happens, set the 
	;  BS_DRAW_RIGHT_BORDER, set the width, skip rest.
	;

	tst	PV.rightBorder
	jz	calcRightBorder

	mov	ax, PV.rightBorder
	clr	PV.rightBorder
	mov	es:[di].BI_width, ax
	BitSet	es:[di].BI_bannerState, BS_DRAW_RIGHT_BORDER
	jmp	rightBorderDone

calcRightBorder:
	;
	; we can draw the right border edge if the string ends 
	; in this section.  The string ends in this section if the 
	; width of the string walked by BannerStringWalk is less 
	; than goalSectionLength + goalLeaderLength
	;

	cmp	bh, 80h
	jb	roundedLengthWalked
	inc	ax

roundedLengthWalked:

	sub	ax, PV.leaderWidth.WBF_int
	cmp	ax, PV.goalSectionLength

	pushf
	add	ax, es:[di].BI_borderWidth
	add	ax, es:[di].BI_endSpace
	mov	es:[di].BI_width, ax
	popf

	jge	noDrawRightBorderEdge

	;
	; the banner message ends in this section, so set BS_DRAW_RIGHT_BORDER
	;

	BitSet	es:[di].BI_bannerState, BS_DRAW_RIGHT_BORDER
	cmp	ax, PV.goalSectionLength
	jle	rightBorderDone

	;
	;  If all of the border will not fit in this section then 
	;  record where it should be drawn in the next section.  
	;  Continue to draw the border in this section as well, 
	;  because the first half might be in this section.
	;

	sub	ax, PV.goalSectionLength
	mov	PV.rightBorder, ax
	jmp	rightBorderDone

noDrawRightBorderEdge:

	andnf	es:[di].BI_bannerState, not mask BS_DRAW_RIGHT_BORDER

rightBorderDone:

	call	BannerPrintPrepareBannerDraw
	inc	PV.pageCount
	
	mov	ax, PV.goalSectionLength
	add	PV.docStart.DBF_intL, ax
	adc	PV.docStart.DBF_intH, 0

	;
	; Draw as long as there is more to draw. Also end each page with
	; a GR_NEW_PAGE. On every page but the last, pass PEC_NO_FORM_FEED.
	;

	mov	al, PEC_NO_FORM_FEED		; assume more pages to go
	test	es:[di].BI_bannerState, mask BS_DRAW_RIGHT_BORDER
	jz	endPage				; if not to border, keep going
	tst	PV.rightBorder
	jnz	endPage				; if border left, keep going
	mov	al, PEC_FORM_FEED		; ...else we're done
endPage:
	push	di
	mov	di, PV.gstate
	call	GrNewPage
	pop	di
	cmp	al, PEC_NO_FORM_FEED
	LONG je	printASection

	.leave
	ret
BannerPrintLoop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BannerPrintPrepareBannerDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This sets the variables like BannerScreenDraw but for printing.

CALLED BY:	BannerPrint

PASS:		*es:si	= banner object
		es:[di]	= banner instance data
		ds:0	= banner message string
		bp	= pointer to inherited local variables
		dx	= banner message end-ptr from BannerStringWalk

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	10/ 3/90	Taken out of BannerPrintLoop
	stevey	10/19/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BannerPrintPrepareBannerDraw	proc	near
	class	BannerClass
	uses	ax,bx,cx,dx

	PV	local	PrintingVariables

	.enter inherit

	;
	;  If the print section starts at zero then we are at the left
	;  edge of the banner and we can draw in the left border edge.
	;

	mov	ax, PV.docStart.DBF_intL
	ornf	ax, PV.docStart.DBF_intH
	ornf	ah, PV.docStart.DBF_frac

	tst	ax
	jnz	noDrawLeftBorderEdge

	BitSet	es:[di].BI_bannerState, BS_DRAW_LEFT_BORDER
	jmp	short	leftBorderSet

noDrawLeftBorderEdge:

	BitClr	es:[di].BI_bannerState, BS_DRAW_LEFT_BORDER

leftBorderSet:
	;
	; set up the char start, number of chars, and the height 
	; to pass to BannerDraw.
	;
if DBCS_PCGEOS
	mov	bx, PV.nextStartPtr
	mov	es:[di].BI_charStart, bx
	sub	dx, bx
	shr	dx, 1				; dx = glyph count
	mov	es:[di].BI_charLength, dx
else
	clr	bh
	mov	bl, PV.nextStartPtr
	mov	es:[di].BI_charStart, bl
	sub	dx, bx
	mov	es:[di].BI_charLength, dl
endif
	;
	; Set a clip region to cut text outside of the section.
	; The clip region is always the same size - the size of the section.
	;

	push	si, di
	mov	ax, PV.leftMargin		; ax = left
	mov	bx, PV.topMargin		; bx = top
	mov	cx, ax
	mov	dx, bx
	add	cx, PV.goalSectionLength	; cx = right
	add	dx, es:[di].BI_height		; dx = bottom
	mov	di, PV.gstate			; di = gstate
	mov	si, PCT_REPLACE
	call	GrSetClipRect
	pop	si, di

	;
	; draw a box around the section
	;

	push	bp				; stack frame
	mov	bp, PV.gstate
	call	BannerDraw
	pop	bp				; stack frame

	.leave
	ret
BannerPrintPrepareBannerDraw	endp
