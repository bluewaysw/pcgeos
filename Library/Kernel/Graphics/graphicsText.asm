COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1988 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Graphics
FILE:		Graphics/grText.asm

AUTHOR:		Tony Requist

ROUTINES:
	Name		Description
	----		-----------
   GBL	GrDrawTextAtCP	Draw a character string at the current position
   GBL	GrDrawText	Draw a character string at a specified position
   GBL	GrDrawCharAtCP	Draw a character at the current position
   GBL	GrDrawChar	Draw a character at a specified position
   GBL	GrDrawTextField	Draw a text field

   INT	TextCallDriver	Lock the font, transform coords, call driver

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	tony	11/88	initial version
	gene	4/89	new version for outline fonts
	jim	10/89	add graphics string support
	john	12/89	add support for text fields.

DESCRIPTION:
	This file contains the application interface for all text output.
	Most of the routines here call the currently selected screen driver
	to do most of the work, and deal with coordinate translation.

	$Id: graphicsText.asm,v 1.1 97/04/05 01:12:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawText

C DECLARATION:	extern void
		    _far _pascal GrDrawText(GStateHandle gstate, sword x,
				sword y, const char _far *str, word size);
			Note: "str" *cannot* be pointing to the XIP movable 
				code resource.
			
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
GRDRAWTEXT	proc	far	gstate:hptr, px:sword, py:sword, pstr:fptr,
				tsize:word
				uses si, di, ds
	.enter

	mov	ax, px
	mov	bx, py
	mov	cx, tsize
	lds	si, pstr
	mov	di, gstate
	call	GrDrawText

	.leave
	ret

GRDRAWTEXT	endp
	SetDefaultConvention

COMMENT @----------------------------------------------------------------------

C FUNCTION:	GrDrawTextAtCP

C DECLARATION:	extern void
		    _far _pascal GrDrawTextAtCP(GStateHandle gstate,
					const char _far *str, word size);
			Note: "str" *cannot* be pointing to the XIP movable 
				code resource.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
GRDRAWTEXTATCP	proc	far	gstate:hptr, pstr:fptr, tsize:word
				uses si, di, ds
	.enter

	mov	cx, tsize
	lds	si, pstr
	mov	di, gstate
	call	GrDrawTextAtCP

	.leave
	ret

GRDRAWTEXTATCP	endp
	SetDefaultConvention

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawTextAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw a string at the current pen position with the current TEXT
		drawing state

CALLED BY:	GLOBAL

PASS: 		cx 	- maximum number of chars to draw
		     	(or 0 for null terminated string)
		ds:si 	- string to draw
		di 	- handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		Store new pen position and call driver

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawTextAtCP	proc	far

if ERROR_CHECK
	;
	; Validate that the text is *not* in a movable code segment
	;
FXIP<		push	bx						>
FXIP<		mov	bx, ds						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx						>
endif

		call	EnterGraphicsText
		jnc	getCPAndDraw
		;
		; handle writing to a graphics string
		;
		call	LibGSTextAtCP
		jmp	ExitGraphicsGseg

getCPAndDraw:
		call	GetDocWBFPenPos			; ax.dl = x, bx.dh = y
		jnc	drawtextCommon
		jmp	ExitGraphics
GrDrawTextAtCP	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw a string at the given position with the current TEXT
		drawing state

CALLED BY:	GLOBAL

PASS: 		ax - x position for string
		bx - y position for string
		cx - maximum number of characters to draw
		     (or 0 for null terminated string)
		ds:si - string to draw
		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none


		REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		Store new pen position and call driver

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawText	proc	far

if ERROR_CHECK
	;
	; Validate that the text is *not* in a movable code segment
	;
FXIP<		push	bx						>
FXIP<		mov	bx, ds						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx						>
endif

		call	EnterGraphicsText
		call	SetDocPenPos		; set out pen pos to start
		jc	GPS_gseg
		clr	dx			;dl, dh <- no frac position

		; drawing to screen, check for NULL mask and NULL window
drawtextCommon	label	near
		tst	ds:[GS_window]		; null window ?
		jz	getStringWidth		; yes, deal with position

		test	es:[W_grFlags], mask WGF_MASK_NULL ; if no mask then
		jnz	getStringWidth		; don't draw string. Go update
						; the pen pos though.
		mov	bp, ss:[bp].EG_ds	; get passed ds (ptr to string)
		mov	di, -1			; Draw all underline, etc
		call	TextCallDriver		;lock font, xform, call driver
GPS_afterDraw:
		jmp	ExitGraphics

;------------------------------------------------------------------------
;		Drawing to a gstring....or just need to update position
;------------------------------------------------------------------------

GPS_gseg:
		call	LibGSText
quickExit:
		jmp	ExitGraphicsGseg

getStringWidth:
		mov	di, ss:[bp].EG_ds	;di:si <- ptr to string
		call	UpdateTextPos
		tst	ds:[GS_window]		; make it work with no window
		jz	quickExit
		jmp	GPS_afterDraw

GrDrawText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SNDrawText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A simple version of GrDrawText that loads no modules

CALLED BY:	INTERNAL
		DrawErrorBox, SysNotify
PASS:		di	- GState
		ax,bx	- position to draw
		ds:si	- string to draw
		cx	- char count
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SNDrawText	proc	far
		tst	di
		jz	useBIOS

		call	EnterGraphics
		add	ax, es:[W_winRect].R_left
		add	bx, es:[W_winRect].R_top
		mov	bp, ss:[bp].EG_ds	; get passed ds (ptr to string)
		mov	di, bp			; di <- seg addr of string
	
		; lock the font
	
		push	ax, bx
		call	LockWinFont
		mov	bp, ax			; bp <- seg addr of font
		pop	ax, bx
	
		; call the driver, passing stuff on the stack (see VPS_params)
	
		push	di			; pass string segment
		push	cx			; pass # chars
		mov	cx, bp			; cx <- seg addr of font
		mov	bp, sp 			; ss:bp <- ptr to stack params
		mov	di, DR_VID_PUTSTRING	; di <- driver function
		call	es:W_driverStrategy	; call the driver
		add	sp, size VPS_params	; clean up stack
	
		; unlock the font
	
		mov	bx, ds:GS_fontHandle		;bx <- font handle
		call	NearUnlockFont
		jmp	ExitGraphics

useBIOS:
	;
	; 0 for gstate means video driver not loaded, so use the BIOS
	; output-tty-char function to spit out the characters.
	; 
		push	si, ax, cx
useBIOSLoop:
		LocalGetChar ax, dssi		;high byte ignored
		LocalIsNull ax
		jz	useBIOSDone
		mov	ah, 0eh
		int	10h
		loop	useBIOSLoop
useBIOSDone:
	;
	; Put out CR-LF pair, as SysNotify always needs this and never gives
	; it to us :)
	; 
		mov	ax, (0eh shl 8) or '\r'
		int	10h
		mov	ax, (0eh shl 8) or '\n'
		int	10h
		pop	si, ax, cx
		ret
SNDrawText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawCharAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw a character at the current pen position with the current
		TEXT drawing state

CALLED BY:	GLOBAL

PASS: 		dx - character to draw
		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		Store new pen position and call driver

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	11/88		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawCharAtCP	proc	far

if not DBCS_PCGEOS
EC <	tst	dh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif

		call	EnterGraphicsText
		jnc	getCPAndDraw
		;
		; handle writing to a graphics string
		;
		call	LibGSCharAtCP
		jmp	ExitGraphicsGseg

getCPAndDraw:
		call	GetDocPenPos			; ax = x, bx = y
		jnc	drawCharCommon
		jmp	ExitGraphics
GrDrawCharAtCP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Draw a character at the given position with the current TEXT
		drawing state

CALLED BY:	GLOBAL

PASS: 		ax - x position for character
		bx - y position for character
		dx - character to draw
		di - handle of graphics state

RETURN: 	none

DESTROYED: 	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
		Store new pen position and call driver

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Tony	11/88		Initial version
		Jim	3/89		Changed to use transformation matrix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawChar	proc	far

if not DBCS_PCGEOS
EC <	tst	dh							>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION	>
endif

		call	EnterGraphicsText
		call	SetDocPenPos		; set new pen position
		jc	GPC_gseg
drawCharCommon	label	near
		call	TrivialReject		; check null window, clip
SBCS <		mov	dh,0			;use stack for string	>
		push	dx
		mov	si,sp
		mov	bp,ss			;bp:si = string
		mov	cx, 1			;must be one character long
		clr	dx			;dl, dh <- no frac position
		mov	di, -1			;draw all underline, etc
		call	TextCallDriver		;lock font, xform, call driver
		pop	dx			;discard character
		jmp	ExitGraphics

	;
	; handle writing to a graphics string
	;
GPC_gseg:
		mov	bp, sp			;bp <- ptr to EGframe
		call	LibGSChar
		jmp	ExitGraphicsGseg
GrDrawChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a text field.

CALLED BY:	Global.
PASS:		ss:bp	= GDF_vars structure
		di	= gstate to draw with.
RETURN:		GDFV_saved.GDFS_xPos set to end of text drawn
DESTROYED:	nothing

NOTES:		This routine can handle fields containing leading TAB
		characters. You can skip the TAB yourself, or you can 
		include it in the text and count it as a character 
		(in the count passed in cx).

		The callback routine supplied as part of the GDF_vars 
		structure has the following API:

		PASS:           ss:bp   = ptr to GDF_vars structure on stack.
                		si      = offset to current position in text.
		                bx:di   = fptr to buffer, sizeof TextAttr struc
		RETURN:         buffer at bx:di filled
		                cx      = # of characters in this run.
		                ds:si   = Pointer to text at offset

PSEUDO CODE/STRATEGY:
	The algorithm is pretty simple:
	    while (nChars > 0) {
		runLength, text = GetRun()
		drawSize = nChars
		if (runLength < nChars) {
		    drawSize = runLength
		}
		DrawString(text, drawSize)
		nChars -= runLength
	    }

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 6/89	Initial version
	jim	12/21/89	Changed to implement new callback interface
	eca	 1/31/90	Changes for new, fractional TextCallDriver
	jcw	 1/ 7/92	Changes to make it more general

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrDrawTextField	proc	far
	call	EnterGraphicsText		; ds <- gstate, es <- window

	;
	; There is now a lot of stuff on the stack which we kind of need.
	;
	mov	cx, 0				; Assume callback not called
	mov	di, ss:[bp].EG_di		; get passed gstate handle
	mov	bp, ss:[bp].EG_bp		; ss:bp <- ptr to parameters
	jnc	drawField			; branch if not a gstring

	push	di				; Save gstate handle
	mov	bx, di				; we need it in StoreTextField
	mov	di, ds:[GS_gstring]		; pass gstring handle as gstate
	push	ss:[bp].GDFV_other.segment	; save other field
	push	ss:[bp].GDFV_other.offset	;   (gstring code changes it)
	call	StoreTextField			; write it out to gseg
						; Nukes: ax, bx, cx, dx, si
	pop	ss:[bp].GDFV_other.offset	; restore other field
	pop	ss:[bp].GDFV_other.segment	;   (gstring code changes it)
	pop	di				; Restore gstate handle
	
	;
	; Fall thru to update the X position.
	;
	mov	cx, -1				; callback has been called

drawField:
	;
	; The flag in the carry is passed to the style callback routine
	;
	mov	bx, ss:[bp].GDFV_saved.GDFS_nChars
	clr	si				; At the start of the field

drawLoop:
	;
	; Call the callback routine to find out how many characters there are
	; in this style.
	;
	; ss:bp = GDF_vars structure
	; ds	= segment address of the gstate
	; di	= GState handle
	; bx	= Number of characters in the field
	; si	= Offset into the field
	; cx	= Zero if the callback has never been called before
	; 
	tst	bx				; Check for no characters left
	jle	done				; Branch if nothing left

	call	SetupGStateForDraw		; Set up gstate
						; ds:si <- ptr to text
						; cx <- number of chars in run
	;
	; Use the minimum of the length of the run and the number of characters
	; to draw.
	;
	cmp	cx, bx				; cx <- min(runLength, nChars)
	jbe	gotNChars
	mov	cx, bx
gotNChars:

	sub	bx, cx				; bx <- # left after draw

	;
	; Load up the coordinates to draw at.
	;
	push	bx, cx, di, si, bp		; Save lots of stuff
	movwbf	bxdh, ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_y
	addwbf	bxdh, ss:[bp].GDFV_saved.GDFS_baseline

	movwbf	axdl, ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_x

	mov	di, ss:[bp].GDFV_saved.GDFS_limit

						; bp:si <- ptr to string
	mov	si, ss:[bp].GDFV_textPointer.offset
	mov	bp, ss:[bp].GDFV_textPointer.segment

	;
	; ds	= Segment address of gstate
	; es	= Segment address of window
	; ax.dl	= X coordinate (WBFixed, document coordinate)
	; bx.dh	= Y coordinate (WBFixed, document coordinate)
	; bp:si	= Pointer to the text
	; cx	= Number of characters to draw
	; di	= Limit
	;
	call	SetDocWBFPenPos			; set initial pen position
	call	TextCallDriver			; Draw the piece
						; cx, di, si, bp Destroyed
	pop	bx, cx, di, si, bp		; Restore lots of stuff
	
	;
	; ax.dl	= X coordinate for next character
	;
	; Save the new X position
	;
	movwbf	ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_x, axdl

	;
	; cx	= Number of characters drawn
	; bx	= Number of characters left after this draw
	;
	add	si, cx				; si <- offset into field
	
	mov	cx, -1				; Signal: Not first call
	jmp	drawLoop			; Loop to do more

done:
	; 
	; if there is an auto-hyphen, draw it now
	; 

	
	test	ss:[bp].GDFV_saved.GDFS_flags, mask HF_AUTO_HYPHEN
	jz	noAutoHyphen

	push	ax,bx,cx,dx,si,di,bp	; save a bunch of stuff
	mov	cx, 1			; draw 1 char
SBCS <	mov	al, C_HYPHEN		; set up bp:si -> hyphen char	>
SBCS <	clr	ah							>
DBCS <	mov	ax, C_HYPHEN_MINUS	; set up bp:si -> hyphen char	>
	push	ax			; param 
	mov	si, sp

	; setup rest of params to TextCallDriver

	movwbf	bxdh, ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_y
	addwbf	bxdh, ss:[bp].GDFV_saved.GDFS_baseline

	movwbf	axdl, ss:[bp].GDFV_saved.GDFS_drawPos.PWBF_x

	mov	di, ss:[bp].GDFV_saved.GDFS_limit

	mov	bp, ss
	call	TextCallDriver
	pop	ax			; pop parameter
	pop	ax,bx,cx,dx,si,di,bp	; restore bunch of stuff

	; all done, cleanup and exit.  If we are defining a path, then act
	; like we are exiting a GString
noAutoHyphen:
	test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
	jnz	exitGraphicsGS
	tst	ds:[GS_window]			; check for no window
	jz	exitGraphicsGS
	jmp	ExitGraphics


exitGraphicsGS:
	jmp	ExitGraphicsGseg

GrDrawTextField	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupGStateForDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the gstate for drawing.

CALLED BY:	GrDrawTextField
PASS:		ds	= Segment address of the gstate
		es	= Segment address of window
		di	= GState handle
		si	= Offset into the field
		ss:bp	= GDF_vars
		cx	= Flag to pass to style callback
RETURN:		GState set up for drawing
		cx	= Number of characters in this run
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 1/ 7/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupGStateForDraw	proc	near
	uses	ax, bx, di, si, ds
	.enter
	;
	; Allocate a stack frame and call the style-callback to fill in the
	; various character attributes. Also locks the text and returns
	; a pointer to the current position.
	;
	mov	ax, di				; ax <- gstate handle

	sub	sp, size TextAttr		; allocate some space
	movdw	bxdi, sssp			; bx:di -> TextAttr structure
	
	push	es, ax				; Save window seg, gstate han
	segmov	es, ds, ax			; es <- seg address of gstate

	;
	; Fill in the text attributes
	;
if	ERROR_CHECK
FXIP<	push	bx, si							>
FXIP<	movdw	bxsi, ss:[bp].GDFV_styleCallback			>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif
FXIP<	mov	ss:[TPD_dataAX], ax					>
FXIP<	mov	ss:[TPD_dataBX], bx					>
FXIP<	movdw	bxax, ss:[bp].GDFV_styleCallback			>
FXIP<	call	ProcCallFixedOrMovable					>
NOFXIP<	call	ss:[bp].GDFV_styleCallback	; Fill the TextAttr structure >
						; ds:si <- ptr to text
						; cx <- # of chars in this run

	movdw	ss:[bp].GDFV_textPointer, dssi	; Save the address of the text

	;
	; Set up a pointer to the text-attributes and then set everything up
	; in the gstate we're drawing with.
	;
	movdw	dssi, bxdi			; ds:si <- ptr to TextAttr

	;
	; Before we get too happy here we need to set the space-padding in
	; the TextAttr structure.
	;
	; The space-padding to use is the same space-padding that is currently
	; set in the gstate.
	;
	; ds:si	= Pointer to the TextAttr
	; es	= Segment containing the gstate
	; di	= GState handle
	;
	movwbf	ds:[si].TA_spacePad, es:GS_textSpacePad, ax

	pop	es, di				; Restore window seg, gstate han

	call	SetTextAttrInt			; use special version of 
						;  GrSetTextAttr that assumes
						;  window is locked.
	add	sp, size TextAttr		; restore stack
	.leave
	ret
SetupGStateForDraw	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextCallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Lock the current font, transform the point, call the driver,
		untransform the point, unlock the font

CALLED BY:	INTERNAL:
		StringCommon, CharCommon

PASS:
	ds	- seg addr of graphics state (GState) (might have NULL window,
		     in which case es will no point to a window)
	es	- seg addr of window (Window) 
	ax.dl	- x coordinate (WBFixed, document coords)
	bx.dh	- y coordinate (WBFixed, document coords)
	cx	- # of chars to draw
	bp:si	- ptr to string to draw
	di	- limit for underline and strike-through (-1 for none)

RETURN:
	ax.dl	- x coordinate for next character (document coords)
	bx.dh	- unchanged
	ds:GS_penPos - updated
	si	- ptr after last char drawn

DESTROYED:
	cx, bp, di

PSEUDO CODE/STRATEGY:
	lock the font;
	if (not drawing from top)
		adjust for drawing position;
	if (underline or strikethrough)
		save current position;
	transform into device coords;
	call the driver;
	if (simple)
		untransform into document coords;
	if (underline or strikethrough)
		untransform into document coords;
		draw bar from old position to current;
	if (!simple && !(underline or strikethrough))
		untransform into document coords;
	unlock the font;
	update the pen position;
	
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This routine has a number of stubs which are used for special
	cases like complex transformations or adding underline style.
	They are individually commented, but be warned -- they are
	not normal routines, with calls and returns, but stubs that
	are jumped to and jump back to the appropriate place in
	the code. This is so the default case is fast. Also be warned
	that some of the stubs do strange things with the stack, as
	they don't need to worry about a return address.
		This routine assumes the Postscript ordering for
	transformations. This means that the y position will not
	change between calls, even if a rotation is applied.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/90		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextCallDriverFar	proc	far
	call	TextCallDriver
	ret
TextCallDriverFar	endp

TextCallDriver	proc	near
  
	; if we have a window and we're in the middle of defining a path, then
	; es does *NOT* point at a valid window. And so save away the current
	; es and load up the window segment.

	test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
	jnz	lockPathWindow
haveWin:
	push	di
	push	bx
EC <	call	FarCheckDS_ES			>
	;
	; If we have a NULL window, exit here
	; Also, if we are going to vidmem, and we are defining the path, then
	; don't call into the video driver, because we don't have the bitmap
	; locked.
	;
	mov	di, bp				;di <- seg addr of string

	test	ds:[GS_pathFlags], mask PF_DEF_PATH_WIN_LOCKED
	jnz	updatePosNow

	tst	ds:[GS_window]			;check for valid Window
	jnz	lockFont			;branch if Window exists

	; at this point, we could be trying to fill or stroke a path, in 
	; which case the window could well be zero.  But we don't want to
	; just update the text position -- we want to draw the text !  So
	; deal with it...

	test	ds:[GS_pathFlags], mask PF_STROKE or mask PF_FILL
	jnz	doTextPath

updatePosNow:	
	call	UpdateTextPos			;else update pen position
	jmp	exitUpdate			;and exit

	; we're creating a path.  Use our own special routine to avoid any
	; ugly complications to the exiting code.
doTextPath:
	jmp	DrawTextToPath

	; we're defining a path.  Save current es and lock the window down.
lockPathWindow:
	tst	ds:[GS_window]			; if no window, don't lock it
	jz	haveWin
	push	es
	push	ax, bx
	mov	bx, ds:[GS_window]
	call	NearPLockES			; setup window segment
	pop	ax, bx
	or	ds:[GS_pathFlags], mask PF_DEF_PATH_WIN_LOCKED ; set hack flag
	jmp	haveWin
		
lockFont:

	;;;
	;;; On stack:	di, bx
	;;;
	push	ax, cx, di, si			; save initial position
	push	dx				;save initial fractions

	;
	; if doing underline or strikethrough, save the unadjusted start position
	;
	test	ds:GS_fontAttr.FCA_textStyle, KERNEL_STYLES
	jz	afterPreStyle1			;branch if underline
	push	dx, ax, bx			;save start position
afterPreStyle1:

if SIMPLE_RTL_SUPPORT
	tst	ds:[GS_textDirection]
	jz	notRTL
	; Backup our position so we start to the left (for reversing)
	; UpdateTextPos will go backwards when we are dealing
	; with RTL text, so we move back.

	push	cx, di, si, ds
	call	UpdateTextPos
	pop	cx, di, si, ds
	call	GetDocWBFPenPos			; ax.dl = x pos, bx.dh = ypos
notRTL:
endif
	;
	; lock the font
	;
	push	ax, bx
	call	LockWinFont
	mov	bp, ax				;bp <- seg addr of font
	pop	ax, bx
	;
	; adjust the y position, if not drawing from the top
	;
	test	ds:GS_textMode, mask TM_DRAW_BASE or \
				mask TM_DRAW_BOTTOM or \
				mask TM_DRAW_ACCENT
	jz	noAdjust			;branch if top draw


	push	es
	mov	es, bp				;es <- seg addr of font
	test	ds:GS_textMode, mask TM_DRAW_BASE
	jnz	adjustBase			;branch if from baseline
	test	ds:GS_textMode, mask TM_DRAW_ACCENT
	jnz	adjustAccent			;branch if from accent

	sub	dh, es:FB_height.WBF_frac
	sbb	bx, es:FB_height.WBF_int
	jmp	afterAdjust
adjustAccent:
	sub	dh, es:FB_accent.WBF_frac
	sbb	bx, es:FB_accent.WBF_int
	jmp	afterAdjust
adjustBase:
	sub	dh, es:FB_baselinePos.WBF_frac
	sbb	bx, es:FB_baselinePos.WBF_int
afterAdjust:
	pop	es
noAdjust:
	;;;
	;;; On stack:	di, bx
	;;;		ax, cx, di, si
	;;;		dx

	;
	; if doing underline or strikethrough, save adjusted start position
	;
	test	ds:GS_fontAttr.FCA_textStyle, KERNEL_STYLES
	jz	afterPreStyle			;branch if underline
	; Save the adjusted y position (bx:dh) already on the stack
	; On stack:  dx, ax, bx (and then others as noted above)
	push	bp
	mov	bp, sp
	mov	ss:[bp+2], bx
	mov	ss:[bp+6], dh
	pop	bp

afterPreStyle:
	;
	; transform into device coordinates
	;
	test	es:W_curTMatrix.TM_flags, TM_COMPLEX
	jz	notComplexTransform
	push	cx, bp
	mov	cx, ax				;cx.dl <- x coord
	mov	bp, bx				;bp.dh <- y coord
	call	LibComplexTransform
	pop	cx, bp
notComplexTransform:

	; ax.dl = x position so far.  bx.dl = y position.
	; we need to do some 32-bit integer math and determine if we're way
	; out of bounds.  We'll save cx and si so that we can use them for
	; the extended math.

	push	cx, si
	mov	cx, dx					; save fractions
	cwd						; 
	mov	si, dx					; si.ax.cl = x coord
	xchg	ax, bx
	cwd
	xchg	ax, bx					; dx.bx,ch = y coord
	add	cl, es:W_curTMatrix.TM_31.DWF_frac.high
	adc	ax, es:W_curTMatrix.TM_31.DWF_int.low
	adc	si, es:W_curTMatrix.TM_31.DWF_int.high
	add	ch, es:W_curTMatrix.TM_32.DWF_frac.high
	adc	bx, es:W_curTMatrix.TM_32.DWF_int.low
	adc	dx, es:W_curTMatrix.TM_32.DWF_int.high
	CheckDWordResult si, ax
	jc	alreadyHosed
	CheckDWordResult dx, bx
alreadyHosed:
	mov	dx, cx				; restore fractions
	pop	cx, si
	jnc	checkRotate
	jmp	skipThisDraw
	; 
	; Deal with drawing characters as part of a path, either stroking 
	; (drawing the outlines) or filling the data.
	;
doPathChars:
	call	PathOutputText			; stroke or fill characters
	add	sp, (size VPS_params)		; clean up stack
	test	ds:GS_fontAttr.FCA_textStyle, KERNEL_STYLES
	jz	afterStylesLong
	add	sp, 3 * (size word)
afterStylesLong:
	jmp	afterStyles


	;
	; the text itself is clipped, but we need to make sure the underline
	; isn't visible despite that. this code is executed iff:
	; (a) the text is definitely clipped
	; (b) the window/gstate is not rotated
	;
checkStylesClipped:
	test	ds:GS_fontAttr.FCA_textStyle, mask TS_UNDERLINE
	LONG jz	skipThisDraw
	push	ds, bx
	mov	ds, bp				;ds <- seg addr of font
	add	bx, ds:FB_underPos.WBF_int
	tst	ds:FB_underPos.WBF_frac
	jns	gotPos
	inc	bx
gotPos:
	cmp	bx, es:[W_maskRect].R_top	;compare with top of window
	pop	ds, bx
;	LONG jge DrawStyles
;we can't just use DrawStyles directly since we don't have the correct
;ending position for the underline, so just call the video driver and
;follow through with the underline -- brianc 1/12/01
	jge	callTheDriver
	jmp	skipThisDraw

	;
	; check to see if we can trivially reject this line.  If any rotation
	; just give up and try to draw it.  Otherwise, check the y position
	; (top of draw box) vs. the bottom of the mask bounds and the
	; y position plus the height vs. the top of the mask bounds.
	;
checkRotate:
	test	es:W_curTMatrix.TM_flags, TM_ROTATED
	jnz	callTheDriver
	push	ds, bx				; save a few
	mov	ds, bp				; ds -> font buffer
	sub	bx, ds:[FB_minTSB]		; take top side bear into acct
	tst	ds:[FB_pixHeight]		; see if char is upside down.
	LONG js	charUpsideDown			;  yep, do different test
	cmp	bx, es:[W_maskRect].R_bottom	; out of bounds ?
	jg	goingToSkip			;  yep, skip it
	add	bx, ds:[FB_pixHeight]		; get to bottom of character
	cmp	es:[W_maskRect].R_top, bx	; out of bounds ?
goingToSkip:
	pop	ds, bx				; restore regs
	LONG jg	checkStylesClipped
	;
	; call the driver, passing stuff on the stack (see VPS_params)
	;
callTheDriver:
	;;;
	;;; On stack:	di, bx
	;;;		ax, cx, di, si
	;;;		dx
	;;; If kernel-based styles are being drawn
	;;;		dx, ax, bx
	;;;
	push	di				;pass string segment
	push	cx				;pass # chars
	mov	cx, bp				;cx <- seg addr of font
	mov	bp, sp 				;ss:bp <- ptr to stack params
	test	ds:[GS_pathFlags], (mask PF_STROKE) or (mask PF_FILL)
	jnz	doPathChars
if SIMPLE_RTL_SUPPORT
	tst	ds:[GS_textDirection]
	jz	notRTLPutString
	call	RTLTextDraw
	jmp	afterRTL
notRTLPutString:
endif
	mov	di, DR_VID_PUTSTRING		;di <- driver function
	call	es:W_driverStrategy		;call the driver
if SIMPLE_RTL_SUPPORT
afterRTL:
endif
;afterDriver:
	add	sp, size VPS_params		;clean up stack
	;
	; if a simple transform, update the pen position as based
	; on the video driver.  We use the W_TMatrix since the pen position
	; is stored in page coordinates.
	;
	; However, the flags of interest are still in W_curTMatrix, to
	; account for transformations in the GState.
	;
	; NOTE: the document y position will not change
	;
	test	es:W_curTMatrix.TM_flags, TM_COMPLEX
	jnz	isComplex
	push	bx				; save y position
	mov	bx, dx				; we need dx for dword stuff
	cwd					; make int part a dword
	sub	bl, es:W_TMatrix.TM_31.DWF_frac.high
	sbb	ax, es:W_TMatrix.TM_31.DWF_int.low
	sbb	dx, es:W_TMatrix.TM_31.DWF_int.high

	push	bx
	clr	bx
	tst	es:[W_winRect].R_left
	jns	notNeg
	mov	bx, -1
notNeg:
	sub	ax, es:W_winRect.R_left
	sbb	dx, bx
	pop	bx

	clr	ds:GS_penPos.PDF_x.DWF_frac.low	; store new x position
	mov	ds:GS_penPos.PDF_x.DWF_frac.high, bl		
	movdw	ds:GS_penPos.PDF_x.DWF_int, dxax
	mov	dx, bx
	call	GetDocPenPos			; get pen pos in doc coords
	pop	bx
isComplex:
	;
	; if drawing kernel styles, go do it now
	;
	test	ds:GS_fontAttr.FCA_textStyle, KERNEL_STYLES
	LONG jnz	DrawStyles
	;;;
	;;; If we branched...
	;;;
	;;; On stack:	di, bx
	;;;		ax, cx, di, si
	;;;		dx
	;;; If kernel-based styles are being drawn
	;;;		dx, ax, bx
	;;;

afterStyles:
	;
	; unlock the font
	;
	mov	bx, ds:GS_fontHandle		;bx <- font handle
	call	NearUnlockFont
	;
	; If we haven't already, update the pen position. If the
	; transform was simple or if there was underline or
	; strikethrough, then the position is up to date.
	;
	pop	bx
	mov	dx, bx				;dx <- fractional positions
	test	ds:[GS_pathFlags], (mask PF_STROKE) or (mask PF_FILL)
	jnz	updatePos			; always update after path op
	test	es:W_curTMatrix.TM_flags, TM_COMPLEX
	jz	exitPop
	test	ds:GS_fontAttr.FCA_textStyle, KERNEL_STYLES
	jnz	exitPop
updatePos:
	pop	ax, cx, di, si			;(ax,dl,bx.dh) <- original pos
	pop	bx
	call	UpdateTextPos
exit:
	call	GetDocWBFPenPos			; ax.dl = x pos, bx.dh = ypos
	pop	di				; Restore passed di
	; only thing left is checking to see if we are defining a path and
	; need to restore es

	test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
	jnz	restorePathES
reallyExit:
	ret

exitPop:
	add	sp, 8				;don't need pen position, et al
exitUpdate:
	pop	bx				;bx <- y position
	jmp	exit

	; still want to do the trivial reject test, but the character is
	; being drawn upside down, so do test a little differently.
charUpsideDown:
	cmp	bx, es:[W_maskRect].R_top	; out of bounds ?
	jl	testToSkip			;  yep, skip it
	add	bx, ds:[FB_pixHeight]		; get to bottom of character
	cmp	es:[W_maskRect].R_bottom, bx	; out of bounds ?
testToSkip:
	pop	ds, bx				; restore regs
	LONG jge callTheDriver			; don't skip the draw

skipThisDraw:
	;
	; skip this whole line of text.  The style preparation code put
	; some stuff on the stack, however, so we'll have to check for that
	; and nuke it if need be.
	;
	test	ds:GS_fontAttr.FCA_textStyle, KERNEL_STYLES
	jz	stackOK				;no styles, stack OK
	add	sp, 6				;kill stuff from styles
stackOK:
	mov	bx, ds:GS_fontHandle		;bx <- handle of font
	call	NearUnlockFont
	pop	dx
	jmp	updatePos			;go update pen position

	; defining a path.  Restore the block we were pointing at.
restorePathES:
	tst	ds:[GS_window]			; if no window, don't lock it
	jz	reallyExit
	push	bx
	mov	bx, ds:[GS_window]
	call	NearUnlockV
	pop	bx
	pop	es
	and	ds:[GS_pathFlags], not (mask PF_DEF_PATH_WIN_LOCKED)
	jmp	reallyExit

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreStyles, DrawStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw underline or strikethrough bar
CALLED BY:	jumped to by TextCallDriver -- doesn't return

PASS:		ax.dl - x position (WBFixed, document coords)
		bx.dh - y position (WBFixed, document coords)
		old (x,y) position - on stack (dx, ax, bx)
		ds - seg addr of GState
		es - seg addr of Window
		bp - seg addr of font
RETURN:		es - seg addr of Window (may have changed)
		bp - seg addr of font (may have changed)
		ax.dl (updated) x position
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Does goofy stuff with the stack -- see LibDrawKernelStyles
	in KLib/Graphics/graphicsText.asm
	
	When we get here (from TextCallDriver) the following things
	are on the stack:
			di	- Limit for drawing
		---->
			bx	- Y coordinate (again)
			ax	- X coordinate (again)
			cx	- Number of characters to draw
			di	- Segment of string
			si	- Offset to string
			dx	- Fractional values (again)
			dx	- Fractional values for start-X/Y
			ax	- StartPos X
			bx	- StartPos Y
	In the routine we push:
			dx	- Fractional values for end-X/Y
			ax	- EndPos X
			bx	- EndPos Y
			bp	- Font segment
			es	- Window segment

	The routine uses ss:bp as a pointer to a DrawUnderlineStruct
	which accounts for all of the values on the stack upto the "---->"

	We want to limit the X position to be less than or equal to the limit
	which was passed in, unless the limit was -1.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	1/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawStyles	label	near
	push	dx, ax, bx			;save current position
	push	bp, es				;pass arguments
	mov	bp, sp				;bp <- goofy var ptr
	
	test	es:W_curTMatrix.TM_flags, TM_COMPLEX
	jz	DS_afterComplex
	;
	; For a complex matrix, we need to get the pen position updated.
	; We want to do this *before* we limit the underline position so that
	; if the limit is lower than the pen position we don't override
	; our limit later on.
	;
	push	bx, cx, dx, di, si
	;
	; Release the font so we don't deadlock...
	;
	mov	bx, ds:GS_fontHandle		;bx <- handle of font
	call	FontDrUnlockFont

	;
	; Figure the new pen position
	;
	mov	dx, {word} ss:[bp].DUS_old.UPS_xFrac
	mov	ax, ss:[bp].DUS_penX
	mov	bx, ss:[bp].DUS_penY		;(ax.dl,bx.dh) <- pen pos
	mov	si, ss:[bp].DUS_strOff
	mov	di, ss:[bp].DUS_strSeg		;di:si <- ptr to string
	mov	cx, ss:[bp].DUS_strLen		;cx <- max # of chars
	call	FarUpdateTextPos
	
	;
	; Update the window (may have moved) and store the real
	; pen position.
	;
	mov	ss:[bp].DUS_args.UAS_winSeg, es	;Window may move
	call	GetDocPenPos			;ax = current x position
						;nukes bx
	mov	ss:[bp].DUS_current.UPS_xInt, ax
	mov	ss:[bp].DUS_current.UPS_xFrac, dl
	
	;
	; Lock the window font again.
	;
	push	ax
	call	FarLockWinFont
	mov	ss:[bp].DUS_args.UAS_fontSeg, ax
	pop	ax
	pop	bx, cx, dx, di, si

DS_afterComplex:
	;
	; Limit the X coordinate
	;
if SIMPLE_RTL_SUPPORT
	tst	ds:[GS_textDirection]
	jnz	posOK	; put no limit on it
endif

	cmp	ax, ss:[bp][size DrawUnderlineStruct]
	jb	posOK
	
	;
	; Limit the position
	;
	mov	ax, ss:[bp][size DrawUnderlineStruct]
	mov	ss:[bp].DUS_current.UPS_xInt, ax
	clr	ss:[bp].DUS_current.UPS_xFrac
posOK:

	call	LibDrawKernelStyles		;call klib to do the work
	
	pop	bp, es
	pop	dx, ax, bx
	add	sp, 3 * size word		;nuke old position
	jmp	afterStyles

TextCallDriver	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTextToPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Similar to the guts of TextCallDriver, but no window and to
		a path region.

CALLED BY:	INTERNAL
		TextCallDriver
PASS:		
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	3/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTextToPath	proc	near
		;;;
		;;; On stack:	di, bx
		;;;
		push	ax, cx, di, si			;save initial position
		push	dx				;save initial fractions
		;
		; lock the font
		;
		push	ax, bx
		push	bp, si
		mov	bp, ds
		mov	si, offset GS_TMatrix		;bp:si <- addr of xform
		call	DoFontLock
		pop	bp, si
		mov	bp, ax				;bp <- seg addr of font
		pop	ax, bx
		;
		; adjust the y position, if not drawing from the top
		;
		test	ds:GS_textMode, mask TM_DRAW_BASE or \
				mask TM_DRAW_BOTTOM or \
				mask TM_DRAW_ACCENT
		jz	noAdjust			;branch if top draw


		push	es
		mov	es, bp				;es <- seg addr of font
		test	ds:GS_textMode, mask TM_DRAW_BASE
		jnz	adjustBase			;branch if from baselin
		test	ds:GS_textMode, mask TM_DRAW_ACCENT
		jnz	adjustAccent			;branch if from accent

		sub	dh, es:FB_height.WBF_frac
		sbb	bx, es:FB_height.WBF_int
		jmp	afterAdjust
adjustAccent:
		sub	dh, es:FB_accent.WBF_frac
		sbb	bx, es:FB_accent.WBF_int
		jmp	afterAdjust
adjustBase:
		sub	dh, es:FB_baselinePos.WBF_frac
		sbb	bx, es:FB_baselinePos.WBF_int
afterAdjust:
		pop	es
noAdjust:
		;
		; transform into page coordinates
		;
		test	ds:GS_TMatrix.TM_flags, TM_COMPLEX
		jz	notComplexTransform
		push	cx, bp
		mov	cx, ax				;cx.dl <- x coord
		mov	bp, bx				;bp.dh <- y coord
		call	LibComplexTransform
		pop	cx, bp
notComplexTransform:

		; ax.dl = x position so far.  bx.dl = y position.
		; we need to do some 32-bit integer math and determine if 
		; we're way out of bounds.  We'll save cx and si so that 
		; we can use them for the extended math.

		push	cx, si
		mov	cx, dx				; save fractions
		cwd					; 
		mov	si, dx				; si.ax.cl = x coord
		xchg	ax, bx
		cwd
		xchg	ax, bx				; dx.bx,ch = y coord
		add	cl, ds:GS_TMatrix.TM_31.DWF_frac.high
		adc	ax, ds:GS_TMatrix.TM_31.DWF_int.low
		adc	si, ds:GS_TMatrix.TM_31.DWF_int.high
		add	ch, ds:GS_TMatrix.TM_32.DWF_frac.high
		adc	bx, ds:GS_TMatrix.TM_32.DWF_int.low
		adc	dx, ds:GS_TMatrix.TM_32.DWF_int.high
		CheckDWordResult si, ax
		jc	alreadyHosed
		CheckDWordResult dx, bx
alreadyHosed:
		mov	dx, cx				; restore fractions
		pop	cx, si
		jc	drawFinished
		;
		; call the driver, passing stuff on the stack (see VPS_params)
		;

		;;;
		;;; On stack:	di, bx
		;;;		ax, cx, di, si
		;;;		dx
		push	di			;pass string segment
		push	cx			;pass # chars
		mov	cx, bp			;cx <- seg addr of font
		mov	bp, sp 			;ss:bp <- ptr to stack params
		call	PathOutputText		; stroke or fill characters
		add	sp, (size VPS_params)	;clean up stack
		;
		; unlock the font
		;
drawFinished:
		mov	bx, ds:GS_fontHandle	;bx <- font handle
		call	NearUnlockFont
		;
		; update the pen position

		pop	dx			;dx <- fractional positions
		pop	ax, cx, di, si		;(ax,dl,bx.dh) <- original pos
		pop	bx
		call	UpdateTextPos
		call	GetDocWBFPenPos		; ax.dl = x pos, bx.dh = ypos
		pop	di			; Restore passed di
		ret
DrawTextToPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateTextPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the pen position due to drawing of text string

CALLED BY:	INTERNAL
		TextCallDriver, GrDrawText

PASS:		ax.dl	- X position to draw at
		bx.dh	- Y position to draw at
		cx 	- max # characters to check
		ds 	- seg addr of GState
		di:si 	- ptr to string
		(if any Window, es - seg addr of Window)

RETURN:		ds:GS_penPos - updated
		es 	- seg addr of Window (may have changed)
		cx 	- actual # of characters (not incl. NULL)
		ds:si	- ptr beyond last character drawn

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		figure out length (in chars) of text string;
		call GrTextWidthWBFixed to get width (in points)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Copied from version in klib
		Don	10/27/00	Removed special code to handle
					  fractional starting X-pos, as call
					  to SetDocWBFPenPos (instead of
					  SetDocPenPos) handles this case.
					  Fixes problem with scaled text
					  drawing too wide.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FarUpdateTextPos	proc	far
	call	UpdateTextPos
	ret
FarUpdateTextPos	endp

UpdateTextPos	proc	near
	uses	di
	.enter
	call	SetDocWBFPenPos			; set new pen position
	;
	; we always want to count the #chars in the string, since the
	; caller could be passing us a bogus value that is high, but non-zero.
	; Actually, we want the lesser of what the caller passed and the
	; NULL-terminated length
	;
	push	es, di, cx			; save window address
	mov	es, di
	mov	di, si				;es:di <- ptr to string
	dec	cx				;max length given?
	js	lookForNull			;no -- CX now -1, which is what
						; we want
	inc	cx				;yes -- restore max length
lookForNull:
SBCS <	clr	al				;al <- looking for null	>
DBCS <	clr	ax				;ax <- looking for null	>
SBCS <	repne	scasb				;scan me jesus		>
DBCS <	repne	scasw				;scan me jesus		>
	jnz	computeLength			;jump if NULL not found
	LocalPrevChar esdi			;else ignore NULL terminator
computeLength:
	sub	di, si
	mov	cx, di				;cx <- # of bytes (inc. NULL)
DBCS <	shr	cx, 1				;cx <- # of chars	>
	pop	es, di, dx			; restore length to dx
	cmp	cx, dx				; use the lesser
	jbe	lengthOK			;  of the two
	tst	dx				; if passed zero, use calc'd 
	jz	lengthOK			;  count
	mov	cx, dx				; use the passed length
lengthOK:
	;
	; Release window so that we don't P() the same semaphore twice
	; when we get to the text-metrics routines.  But don't do it
	; if we're drawing to a graphics string...
	; If a path definition is in progress, then the GS_gstring field in
	; the GState is non-zero, which means that the window will never be
	; locked by any graphics routine.  Except TextCallDriver.  sigh.
	;
	test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
	jz	notDefiningPath
	test	ds:[GS_pathFlags], mask PF_DEF_PATH_WIN_LOCKED
	jnz	checkWinAnyway
	jmp	winUnlocked

notDefiningPath:
	tst	ds:GS_gstring			;see if gstring
	jnz	winUnlocked			;if gstring, window OK
checkWinAnyway:
	mov	bx, ds:GS_window		; check for no window at all
	tst	bx
	jz	winUnlocked
	call	NearUnlockV			;unlock the window
winUnlocked:
	push	ds
	mov	dx, ds:LMBH_handle		;dx <- handle of GState
	mov	ds, di				;ds:si <- ptr to string
	mov	di, dx				;dx = gstate handle
	call	GrTextWidthWBFixed		;dx.ah == width of string.
	mov	bx, dx				;bx.ah == width of string
	mov	di, ds				;di:si <- ptr to string
	pop	ds

	; to update the pen position, we need to see if the GState has a 
	; complex transformation, since the penPos is stored in Page coords.

	test	ds:[GS_TMatrix].TM_flags, TM_COMPLEX
	jnz	updatePenPosComplex
	
	;
	; bx.ah	= String width
	;
if SIMPLE_RTL_SUPPORT
	tst	ds:[GS_textDirection]
	jz	notFlipped
	; RTL updates text in negative direction
	sub	ds:GS_penPos.PDF_x.DWF_frac.high, ah ; new pos <- old + width
	sbb	ds:GS_penPos.PDF_x.DWF_int.low, bx
	sbb	ds:GS_penPos.PDF_x.DWF_int.high, 0
	jmp	flipDone
notFlipped:
endif
	add	ds:GS_penPos.PDF_x.DWF_frac.high, ah ; new pos <- old + width
	adc	ds:GS_penPos.PDF_x.DWF_int.low, bx
	adc	ds:GS_penPos.PDF_x.DWF_int.high, 0
if SIMPLE_RTL_SUPPORT
flipDone:
endif
	;
	; Need to get exclusive access to the window back again so that
	; the call to ExitGraphics() will work.  Check for gstring
	; first and forget about lock in that case
	; If we are defining a path, then we don't need to lock the window.
	;
updateDone:
	test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
	jz	noPathCheckGString
	test	ds:[GS_pathFlags], mask PF_DEF_PATH_WIN_LOCKED
	jnz	lockWinAnyway
	jmp	winLocked

noPathCheckGString:
	tst	ds:GS_gstring			;see if gstring
	jnz	winLocked			;if gstring, window OK
lockWinAnyway:
	mov	bx, ds:GS_window		; check for no window at all
	tst	bx
	jz	winLocked
	call	NearPLockES			;relock the window
winLocked:

	add	si, cx				; bump the pointer anyway
	.leave
	ret

	; there is scaling and/or rotation.  Do the right thing.
	;
updatePenPosComplex:
	push	ax, bx, cx, dx
	mov	dx, bx
	mov	ch, ah
	clr	cl			; x offset in dx.cx
	clr	ax, bx			; y offset is 0.0
	call	TransformRelVector	; get in page coordinates
	push	ax
	add	ds:GS_penPos.PDF_x.DWF_frac, cx
	mov	ax, dx				; ax <- x integer (low)
	cwd					; dx:ax <- x integer
	adc	ds:GS_penPos.PDF_x.DWF_int.low, ax
	adc	ds:GS_penPos.PDF_x.DWF_int.high, dx
	pop	ax
	add	ds:GS_penPos.PDF_y.DWF_frac, ax
	mov	ax, bx				; ax <- y integer (low)
	cwd					; dx:ax <- y integer
	adc	ds:GS_penPos.PDF_y.DWF_int.low, ax
	adc	ds:GS_penPos.PDF_y.DWF_int.high, dx
	pop	ax, bx, cx, dx
	jmp	updateDone
UpdateTextPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RTLTextDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws text to the text driver in reverse order

CALLED BY:	INTERNAL
		TextCallDriver

PASS:           ax.dl	- x position (WBFixed coordinate)
		bx.dh	- y position (WBFixed coordinate)
		cx	- segment address of font
		ss:bp	- ptr to VPS_params structure on stack
			  VPS_numChars - max #chars to draw
			  VPS_stringSeg - segment of string to draw
		si	- offset into VPS_stringSeg to character string
		ds	- gstate
		es	- window

RETURN:		si	- end of string
		bp	- segment address of font (may have moved from original cx)

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		les	02/12/2002	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SIMPLE_RTL_SUPPORT
RTLTextDraw	proc	near
	push	ax, bx, dx

	mov	di, ss:[bp].VPS_numChars

	; Skip to the last character
	; while determing how many characters we have
	push	es, cx
	segmov	es, ss:[bp].VPS_stringSeg, cx
	clr	cx
loopRTL:
	tst	{byte}es:[si]		; look for null, stop there
	jz	done
	inc	si		; next character
	inc	cx
	cmp	cx, di
	jne	loopRTL
done:
	mov	di, cx
	pop	es, cx
	push	si
	dec	si		; backup one to last character
	push	di	; pop later as VPS_numChars
	; Only draw one character at a time
	mov	ss:[bp].VPS_numChars, 1

rtlLoop:
	tst	di
	je	doneRTLdraw

	push	bp, di, si
	mov	di, DR_VID_PUTSTRING		;di <- driver function
	call	es:W_driverStrategy		;call the driver
	mov	cx, bp
	pop	bp, di, si
	dec	di

	; Next previous character
	dec	si
	jmp	rtlLoop
doneRTLdraw:
	pop	si
	pop	ss:[bp].VPS_numChars

	pop	ax, bx, dx
	mov	bp, cx
	ret
RTLTextDraw	endp

endif

