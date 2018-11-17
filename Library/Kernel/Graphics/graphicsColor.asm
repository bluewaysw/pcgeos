COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		KernelGraphics
FILE:		Graphics/graphicsColor.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
    GLB GrMapColorIndex		Map an index to its RGB equivalent
    GLB GrMapColorRGB		Map an RGB color to an index
    INT EnterColor		Common entry routine for color palette
				functions
    INT ExitColor		Common exit routine for color palette
				functions
    GLB GrCreatePalette		Create a color mapping table and associate
				it with the current window.	Initialize
				the table entries to the default palette
				for the device.
    GLB GrDestroyPalette	Free any custom palette associated with the
				current window
    GLB GrSetPalette		Set one or more palette entries
    GLB GrGetPalette		Get the current palette
    GLB GrSetPaletteEntry	Set one entry in the current palette
    INT MapRGBtoIndex		Take an RGB value and a palette, return a
				closest RGB and a color table index

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jad	12/88	initial version

DESCRIPTION:
	This file contains the application interface for all color
	palette setting and query routines.

	$Id: graphicsColor.asm,v 1.1 97/04/05 01:12:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

kcode	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMapColorIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map an index to its RGB equivalent

CALLED BY:	GLOBAL

PASS:		di	- gstate
			- or di = 0 to get default mapping
		ah	- color index

RETURN:		al	- R component
		bl	- G component
		bh	- B component

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If (there is a custom palette defined)
		    look up the RGB value in the custom palette;
		else (if the video device is color)
		    query the video driver for the mapping

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrMapColorIndex	proc	far
		uses	ds, es, si, dx
		.enter

		; use common palette entry routine, to lock palette..etc

		call	EnterColor		; 
		push	es			; save window 

		jc	defaultMap		; do default for gstrings
		tst	di			; just call default driver if
		jz	defaultMap		;  want default values
		tst	dx			; if no custom palette
		jz	defaultMap
		mov	si, dx			; es:si -> palette data
haveMapPointer:
		mov	bl, ah
		clr	bh
		mov	dx, bx
		shl	bx, 1
		add	bx, dx			; es:[si][bx] -> pal entry
		mov	al, es:[si][bx].RGB_red	; get red value
		mov	bx, {word} es:[si][bx].RGB_green

		pop	es
		call	ExitColor		; unlock blocks, etc.

		.leave
		ret

		; get defaults
defaultMap:
		LoadVarSeg	es
		mov	si, offset idata:defaultPalette
		jmp	haveMapPointer

GrMapColorIndex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrMapColorRGB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map an RGB color to an index

CALLED BY:	GLOBAL

PASS:		di	- gstate
			- or di=0 to get default mapping
		al	- R component
		bl	- G component
		bh	- B component

RETURN:		ah	- index
		al	- R component of closest fit
		bl	- G component of closest fit
		bh	- B component of closest fit

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		If (there is a custom palette defined)
		    do a closest fit for the RGB values stored in the palette
		    return the index that corresponds to the closest value
		else (if the video device is color)
		    query the video driver for the mapping

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrMapColorRGB	proc	far
		uses	ds,es,si,cx
		.enter

		; check for default mapping


		; common entry routine

		call	EnterColor		; get everything setup
		push	ds			; save gstate segment

		jc	useDefault
		tst	di			; check for default 
		jz	useDefault
		tst	dx
		jz	useDefault
		segmov	ds, es
		mov	si, dx			; ds:si -> palette data
havePointer:
		mov	ch, 0xff		; check 'em all
		call	MapRGBtoIndex

		pop	ds
		call	ExitColor		; cleanup before we go

		.leave
		ret

		; query default driver for mapping
		; call driver to get #colors
useDefault:
		LoadVarSeg	ds
		mov	si, offset idata:defaultPalette
		jmp	havePointer
GrMapColorRGB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnterColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common entry routine for color palette functions

CALLED BY:	GLOBAL

PASS:		di	- handle to gstate

RETURN:		carry	- set if passed di = gstring handle, else clear
		
		if normal GState:
		carry 	- clear
		zero	- clear
		dx	- offset in window struct to palette, or 
			- set to 0 if using default palette
		ds	- gstate segment (locked)
		es	- window segment (locked and owned)

		if GString:
		carry	- set
		zero	- set
		dx	- set to 0
		ds	- gstate segment (locked)

		if Path:
		carry	- set
		zero	- clear
		dx	- set to 0
		ds	- gstate segment (locked)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (di = gstring handle)
		   return carry set
		else
		    lock the gstate and associated window;
		    get palette handle from window;
		    if (palette handle == 0)
			return carry clear and dx = 0
		    else
			lock palette block;
			return carry clear and dx = palette segment,
						
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
EnterColor	proc	far
		uses	ax,bx
		.enter

		; lock the gstate

		tst	di			; check for NULL gstate
		jz	done			; treat them the same
		mov	bx, di
		call	NearLockDS		; ds <- seg addr of GState

		; check for a gstring

		clr	dx			; assume no palette
		tst	ds:[GS_gstring]		; check for non-zero handle
		jnz	doGString

		mov	bx, ds:[GS_window]	; get associated window
		tst	bx
		jz	doneOK
		call	NearPLockES		; lock/own the window

		; deal with the palette, if there is one

		mov	bx, es:[W_palette]	; get palette handle
		mov	dx, bx
		tst	dx			; check for null handle
		jz	doneOK
		mov	dx, es:[bx]		; es:dx -> palette
doneOK:
		xor	ax, ax			; clear the zero & carry flags
done:
		.leave
		ret

		; passed handle is to a gstring, don't do anything
doGString:
		test	ds:[GS_pathFlags], mask PF_DEFINING_PATH
		stc				; still have a GString or Path!
		jmp	done

EnterColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common exit routine for color palette functions

CALLED BY:	GLOBAL

PASS:		di	- GState handle, or zero
		es	- window segment (locked and owned)
		ds	- gstate segment

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		if (custom palette)
		    unlock palette block;
		get window handle from LMemBlockHeader in window;
		unlockV window;
		unlock gstate;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
ExitColor	proc	far
		uses	bx
		.enter

		; check for null gstate handle (some color funcs support this)

		tst	di			; if NULL, just exit
		jz	exit

		; if this is a gstring, just unlock the gstate

		tst	ds:[GS_gstring]		; check for null handle
		jnz	unlockGS

		; first unlock palette block, if necc.

		tst	ds:[GS_window]		; if zero...
		jz	unlockGS		;  just unlock the GState

		; now unlockV the window structure, unlock the gstate

		mov	bx, es:[W_header].LMBH_handle ; get block handle
		call	NearUnlockV		; release window
unlockGS:
		mov	bx, di			; bx = gstate handle
		call	NearUnlock		; unlock the gstate
exit:
		.leave
		ret

ExitColor	endp

kcode	ends


GraphicsPalette	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrCreatePalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a color mapping table and associate it with the
		current window.  Initialize the table entries to the default
		palette for the device.

CALLED BY:	GLOBAL

PASS:		di	- gstate

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This function allocates a 256-entry table and associates
		it with the window.  (It becomes a chunk in the window 
		structure).

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrCreatePalette	proc	far
		uses	ds,es,dx,si,bp,ax,bx,cx
		.enter

		; use common routine to get pointer to window

		call	EnterColor		; es -> window
		jc	handleGString		; do the gstring thing

		; if there is already a palette, don't do another

		tst	dx			; should be zero
		jnz	exit			;  if not, then leave

		; use size of palette to calc size of block needed

		push	ds			; save GState segment
		segmov	ds, es, cx
		mov	cx, 256*3		; #bytes we need
		clr	al			; no flags
		call	LMemAlloc
		pop	ds
		jc	exit			; bug out on error

		; store handle and init values to default palette

		push	di
		mov	es:[W_palette], ax	; store chunk handle here
		mov	di, ax
		mov	di, es:[di]		; es:di -> buffer
		push	ds
		LoadVarSeg ds
		mov	si, offset idata:defaultPalette ; ds:si -> Palette
		mov	cx, (256*3)/2		; #words to copy
		rep	movsw
		pop	ds			; restore GState 
		pop	di
exit:
		call	ExitColor

		.leave
		ret

		; handle writing to a graphics string
handleGString:
		jnz	exit			; if Path, do nothing
		push	di
		mov	di, ds:[GS_gstring]	; get gstring block handle
		mov	al, GR_CREATE_PALETTE	; load up code
		clr	cl			; no data to write
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; use fast routine
		pop	di
		jmp	exit			; just exit for now
GrCreatePalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDestroyPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free any custom palette associated with the current window

CALLED BY:	GLOBAL

PASS:		di	- gstate

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (custom palette is defined for window)
		   free block;
		   unlock all palette entries in driver;
		   dis-associate color table with window;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDestroyPalette proc	far
		uses	ds,es,dx,di,ax,bx
		.enter

		; lock the window to get the palette handle

		call	EnterColor		; get everything set up
		jc	handleGString		; do the string thing

		; if there wasn't a palette alloc'd, exit

		tst	dx
		jz	exit

		; everything kosher, free the palette

		clr	ax
		xchg	ax, es:[W_palette]	; get palette handle, set to 0
		push	ds
		segmov	ds, es
		call	LMemFree
		pop	ds
exit:
		call	ExitColor		; cleanup and exit

		.leave
		ret

		; handle writing to a gstring
handleGString:
		jnz	exit			; if a Path, do nothing
		push	di
		mov	di, ds:[GS_gstring]
		mov	al, GR_DESTROY_PALETTE	; load up code
		clr	cl			; no data to write
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; use fast routine
		pop	di
		jmp	exit			; just exit for now
GrDestroyPalette endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set one or more palette entries

CALLED BY:	GLOBAL

PASS:		di	- gstate
		al	- palette entry to start at
		cx	- number of entries to set
		dx:si	- pointer to buffer of cx entries, each of type
			  RGBValue
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrSetPalette	proc	far
	;
	; Compute size of data at DX:SI.  (RGBValue is 3 bytes.)
	;		
		push	ax		
		mov	ax, cx
		shl	ax, 1				; (#entries x 2)
		add	ax, cx				; + #entries = #bytes
		mov	ss:[TPD_callVector].segment, ax
		pop	ax
		
		mov	ss:[TPD_dataBX], handle GrSetPaletteReal
		mov	ss:[TPD_dataAX], offset GrSetPaletteReal
		GOTO	SysCallMovableXIPWithDXSIBlock
GrSetPalette	endp
CopyStackCodeXIP	ends

else

GrSetPalette	proc	far
	FALL_THRU	GrSetPaletteReal
GrSetPalette	endp

endif



GrSetPaletteReal	proc	far
		uses	ds,es,dx,si,di,cx,bx,ax
		.enter

		; get into the color mood

		mov	bx, dx			; save pointer to data
		call	EnterColor		; lock the things we need
		jc	handleGString		; handle writing to gstring

		; check for valid palette, quit if non

		tst	dx			; check palette handle
		jz	exit			;  no palette, quit

		; setting new values, loop through provided list

		push	ds, di			; save GState
		mov	ds, bx			; ds -> passed buffer
		mov	di, dx			; es:di -> palette
		clr	ah
		add	di, ax
		shl	ax, 1
		add	di, ax			; bx = 3*entry number
		mov	ax, cx
		shl	cx, 1
		add	cx, ax			; cx = #bytes to transfer
		rep	movsb
		pop	ds, di			; restore GState
exit:
		call	ExitColor		; all done, cleanup

		.leave
		ret

		; handle writing to gstring
handleGString:
		jnz	exit
		push	di, ds
		mov	di, ds:[GS_gstring]
		mov	ah, al
		mov	al, GR_SET_PALETTE	; write first part
		mov	bx, cx
		mov	cl, (size OpSetPalette -1) ; 3 bytes of data
		mov	ch, GSSC_DONT_FLUSH	; not done yet
		call	GSStoreBytes
		mov	cx, bx			; restore #entries
		shl	bx, 1			; *3 for #bytes
		add	cx, bx			; cx = #bytes to store
		mov	ds, dx			; ds:si -> bytes to store
		mov	al, GSE_INVALID		; not writing opcode this time
		mov	ah, GSSC_FLUSH		; done with element
		call	GSStore
		pop	di, ds
		jmp	exit

GrSetPaletteReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrGetPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current palette

CALLED BY:	GLOBAL

PASS:		di	- gstate
		al	- flag, enum of type GetPalType:
				GPT_ACTIVE - to get curr active pal
				GPT_DEFAULT - to get the default palette

RETURN:		bx	- handle to buffer containing palette
				
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
 		if (custom palette associated with window)
		    retreive the current palette entries from the block 
		    associated with the window;
		else
		    query driver for default values;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GGP_MEM_FLAGS equ ((mask HAF_ZERO_INIT or \
		    mask HAF_LOCK or \
		    mask HAF_NO_ERR) shl 8) or \
		   (mask HF_SHARABLE or mask HF_SWAPABLE)

GrGetPalette	proc	far
		uses	ds,es,si,ax,cx
		.enter

		; as usual, call the common routine

		call	EnterColor		; lock things
		jc	exit			; no gstring support here

		; allocate a buffer to put the palette into

		push	ds, es, di		; save GState/Win segments
		segmov	ds, es, cx		; ds -> Window		
		push	ax			; save flags
		mov	ax, (256*3) + 2		; size of block needed
		mov	cx, GGP_MEM_FLAGS
		call	MemAllocFar
		clr	di
		mov	es, ax			; es:di -> buffer
		pop	ax			; restore flags

		; if there is no custom palette, always return the default

		mov	si, dx			; assume we have a palette
		tst	dx
		jz	returnDefault
		cmp	al, GPT_DEFAULT		; if getting default...
		jne	havePointer		; ds:si -> Custom Palette
returnDefault:
		LoadVarSeg ds
		mov	si, offset idata:defaultPalette
havePointer:
		mov	{word} es:[di], 256	; 256 entries
		add	di, 2
		mov	cx, (256*3)/2		; moving this much data
		rep	movsw

		call	MemUnlock		; release block
		pop	ds, es, di
exit:
		call	ExitColor		; all done, cleanup

		.leave
		ret
GrGetPalette	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrSetPaletteEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set one entry in the current palette

CALLED BY:	GLOBAL

PASS:		di	- gstate
		ah	- index to set
		al	- R component
		bl	- G component
		bh	- B component

RETURN:		nothing
				
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
 		if (custom palette associated with window)
		    set the appropriate entry in the color table;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrSetPaletteEntry proc	far
		uses	ds,es,si,ax,bx,cx,dx
		.enter

		; get into the color mood

		call	EnterColor		; lock the things we need
		jc	handleGString		; handle writing to gstring

		; check for valid palette, quit if non

		tst	dx			; check palette handle
		jz	exit			;  no palette, quit

		; set the value

		push	di
		mov	di, dx			; es:di -> palette
		mov	cl, ah			; get index into cx
		clr	ch
		add	di, cx			; add index offset to pointer
		shl	cx, 1			; *2
		add	di, cx			; *3
		mov	es:[di], al		; store red comp
		mov	{word} es:[di+1], bx	; store green&blue comp
		pop	di
exit:
		call	ExitColor		; all done, cleanup

		.leave
		ret

		; handle gstring writing
handleGString:
		jnz	exit			; if a Path, do nothing
		push	di
		mov	di, ds:[GS_gstring]
		mov	dx, bx
		mov	bx, ax
		xchg	bl, bh			; index goes first
		mov	al, GR_SET_PALETTE_ENTRY	; write first part
		mov	cl, (size OpSetPaletteEntry -1) ; 3 bytes of data
		mov	ch, GSSC_FLUSH		; all done
		call	GSStoreBytes
		pop	di
		jmp	exit
GrSetPaletteEntry endp

GraphicsPalette	ends

GraphicsSemiCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapRGBtoIndex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take an RGB value and a palette, return a closest RGB and 
		a color table index

CALLED BY:	INTERNAL
		GrMapColorRGB

PASS:		ds:si	- pointer to palette data
		al	- R component to match
		bl	- G component to match
		bh	- B component to match
		ch	- max index number to check, or FF to check all

RETURN:		ah	- index
		al	- R component of closest fit
		bl	- G component of closest fit
		bh	- B component of closest fit


DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Do the 3d distance calculation for each entry in the palette
		and record the closest one.  For efficiency sake, we use a
		simplified distance formula:
			dist = (delta-R + delta-G + delta-B +
				 max (delta-R,delta-G,delta-B)) / 2
		Also, since we don't need the exact distance (only for 
		comparisons), we don't do the final divide-by-2.  whoopie.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		
MapRGBtoIndex	proc	far
		uses	si,di,cx,dx
red		local	word
green		local	word
blue		local	word
default		local	word
		.enter

		mov	dl, ch			; set limit on search
		mov	dh, dl
		clr	ah			; make into a word
		mov	red, ax
		mov	al, bl			; get green
		mov	green, ax
		mov	al, bh			; get blue
		mov	blue, ax
		push	si			; save pointer
		clr	default
		cmp	ch, 0ffh		; searching entire palette?
		je	checkDefault
afterCheckDefault:
		mov	di, 0xffff		; di = max distance
		clr	cx			; ch = curr index, cl=max index
		clr	ah

		;  loop through all the values
checkLoop:
		lodsb				; get r component
		sub	ax, red			; calc delta-R
		jns	redPos			; absolute value, of course
		neg	ax
redPos:
		mov	bx, ax			; start accumulation
		mov	dl, al			; save in case max
		lodsb				; next component
		sub	ax, green		; calc delta-G
		jns	greenPos		; absolute value, of course
		neg	ax
greenPos:
		add	bx, ax			; add it to accumulation
		cmp	al, dl			; check for largest component
		jb	skip2nd			;  no, skip this one
		mov	dl, al			;  yes, store for later
skip2nd:
		lodsb				; get b component
		sub	ax, blue		; calc delta-B
		jns	bluePos 		; absolute value, of course
		neg	ax
bluePos:
		add	bx, ax			; bump distance calc
		cmp	al, dl			; check for largest again
		jb	skip3rd			;  nope, continue
		mov	dl, al			;  yep, save it
skip3rd:
		mov	al, dl
		add	bx, ax			; add max

		; done with this entry, check if closer than one we saved

		cmp	bx, di			; check current vs max
		jae	nextOne			;  no, check next entry
		mov	di, bx			;  yes, save value
		mov	cl, ch			;  and save index too
		tst	bx			; check for perfect match
		jz	done			; bail if perfect match
nextOne:
		inc	ch			; on to next index
		jz	nearlyDone
		cmp	ch, dh 			; check vs #entries
		jbe	checkLoop		; one to next entry

nearlyDone:	tst	default
		jnz	tryColorCubeMap

		; all done, get index for closest one and lookup RGB
done:
		pop	si			; restore table pointer
		mov	ah, cl			; return index here
		clr	ch			; make index a word
		mov	bx, cx			; set up offset in bx
		shl	cx, 1
		add	bx, cx			; bx = index * 3
		mov	al, ds:[si][bx]		; get R component
		mov	bx, ds:[si][bx+1]	; get G component
		.leave
		ret

		; If the entire default system palette is being checked, 
		; we can get intelligent about searching the last 216 
		; entries in the palette and speed things up significantly.
checkDefault:
		mov	ax, ds
		cmp	ax, segment defaultPalette
		jne	afterCheckDefault
		cmp	si, offset defaultPalette
		jne	afterCheckDefault

		; Now re-enter the usual proceedings, but
		; we only look at the initial 32 entries.  Sweet!

		inc	default
		mov	dh, 31			; check #0 - #31
		jmp	afterCheckDefault

tryColorCubeMap:
		; Skip past the eight unused palette entries.

		add	ch, 8			; ch = 40
		add	si, 8 * 3		; *ds:si <- palette[40]

		; In the 6x6x6 color cube, the closest palette entry is:
		;
		; 40 + (((red + 019h) / 033h) * 6 +
		;      ((green + 019h) / 033h)) * 6 +
		;      ((blue + 019h) / 033h)
		;
		; We use the colorCubeMap table to avoid the ugly divide.
		; Besides, what's another 256 bytes between friends, eh?

		push	cx			; save cl
		mov	bx, offset colorCubeMap	; ds:bx <- color map
		mov	ax, red
		xlat	cs:[colorCubeMap]
		mov	dl, al			; multiply al by 6
		shl	al, 1			; * 2
		add	al, dl			; * 3
		shl	al, 1			; * 6
		mov	cl, al
		mov	ax, green
		xlat	cs:[colorCubeMap]
		add	al, cl
		mov	dl, al			; multiply al by 6
		shl	al, 1			; * 2
		add	al, dl			; * 3
		shl	al, 1			; * 6
		mov	cl, al
		mov	ax, blue
		xlat	cs:[colorCubeMap]
		add	cl, al			; cl <- index - 40
		mov	dh, cl
		add	dh, ch			; dh <- index

		; Determine the offset of the index into the palette.
		; ds:si currently points to palette[index - 40].

		clr	ch			; cx <- index - 40
		mov	ax, cx			; ax <- index - 40
		shl	ax, 1
		add	ax, cx
		add	si, ax			; *ds:si <- palette[index]
		
		pop	cx			; restore cl
		mov	ch, dh			; checking this entry
		dec	default
		clr	ah
		jmp	checkLoop

MapRGBtoIndex	endp

colorCubeMap	label	byte
	byte	26 dup (0)		; #000 - #025
	byte	51 dup (1)		; #026 - #076
	byte	51 dup (2)		; #077 - #127
	byte	51 dup (3)		; #128 - #178
	byte	51 dup (4)		; #179 - #229
	byte	26 dup (5)		; #230 - #255

GraphicsSemiCommon ends
