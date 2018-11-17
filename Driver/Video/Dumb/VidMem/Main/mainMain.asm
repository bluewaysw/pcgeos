COMMENT }%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Memory video drivers
FILE:		mainMain.asm

AUTHOR:		Jim DeFrisco

ROUTINES:
	Name			Description
	----			-----------
	DriverStrategy		entry point to driver
	VidStartExclusive	Enter into exclusive use
	VidEndExclusive		Finished with exclusive use
	VidInfo			Return address of info block
	VidEscape		Generalized escape function

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	jim	5/88	initial verison
	jim	8/89	moved into mem module for special modifications

DESCRIPTION:
	This file contains the entry point routine for the video drivers.
		
	$Id: mainMain.asm,v 1.1 97/04/18 11:42:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%}

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriverStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Entry point for vidmem calls

CALLED BY:	KERNEL

PASS:		[di] - offset into driver function table

RETURN:		see individual routines

DESTROYED:	depends on routine called

PSEUDO CODE/STRATEGY:
		call function thru the jump table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88...	Initial version of strategy routine
	Jim	10/88		Modified for video drivers
	Jim	5/89		Modified to add escape capability

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DriverStrategy	proc	far


		; this is really simple, folks.  The REAL DriverStrategy 
		; routine (well, the one you normally see for video drivers)
		; is executed in each individual module of vidmem.  So there 
		; is one for Mono, one for Color4, etc.  But many of the normal
		; driver functions are NULL for vidmem (pointer, save-under...)
		; so they are handled locally.  Basically, all we do here is 
		; either call into one of the modules or call a local routine.
		; yawn.

		; Of course, we also need to deal with escape codes.  So check
		; that first.

		tst	di
		js	handleEscape
		call	cs:driverJumpTable[di]
done:
		ret

handleEscape:
		call	VidEscape			; ESC function handler
		jmp	done
DriverStrategy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidCallMod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to call into one of the main modules (Mono, etc)

CALLED BY:	INTERNAL
		DriverStrategy

PASS:		di	- function number
		es	- window structure

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		save necc variables, call into other module.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidCallMod	proc	near

		; first, save away ax/bx since they are trashed by CallMod

		mov	ss:[TPD_dataAX], ax		; trashed by CallMod
		mov	ss:[TPD_dataBX], bx

		; find out what type of bitmap it is, then call the appropriate
		; module's entry point

		push	ds				; save segreg
EC <		tst	es:[W_bmSegment]		; if zero, hosed >
EC <		ERROR_Z	VIDMEM_HUGE_ARRAY_PROBLEM			 >
		mov	ds, es:[W_bmSegment]		; get bitmap segment
		mov	bx, offset EB_bm		; ds:bx -> bitmap
		mov	bl, ds:[bx].B_type		; get color info
		mov	ax, ds:[EB_flags]		; grab edit mask flag
		pop	ds
		and	bx, mask BMT_FORMAT 		; isolate type bits
		shl	bx, 1				; dword table
		shl	bx, 1

		; if we're going to edit the mask, then we need to do a
		; bit different work

		push	es:[LMBH_handle]		; save win blk handle
		test	ax, mask BM_EDIT_MASK
		jnz	editMask
		mov	ax, cs:[colorModTable][bx].offset ; grab pointer
		mov	bx, cs:[colorModTable][bx].segment
		;
		; if bx = 0, that means this module is not supported. So
		; we don't do anything.
		;
		tst	bx
		jz	done

		call	ProcCallFixedOrMovable
done:
		mov	ss:[TPD_dataBX], bx		; save bx return val
		pop	bx				; restore win blk han
		call	MemDerefES			; es -> window
		mov	bx, ss:[TPD_dataBX]		; restore bx return val
		ret

		; OK, we want to edit just the mask part of the bitmap.  That
		; means that we want to use the Mono module, but we need to
		; get some information from the module that the bitmap
		; naturally would go to (to have the picture part edited).
editMask:
		mov	ax, cs:[maskInfoTable][bx].offset ; get pointer
		mov	bx, cs:[maskInfoTable][bx].segment
		;
		; if bx = 0, that means this module is not supported. So
		; we don't do anything.
		;
		tst	bx
		jz	done
		call	ProcCallFixedOrMovable
		call	MonoEditMask			; always use mono mod
		jmp	done
VidCallMod	endp


colorModTable	label	fptr
if _MONO
		fptr	Mono:MonoEntry			; mono bitmap
else
		fptr	0				; not supported
endif							; if _MONO
if _4BIT
		fptr	Clr4:Clr4Entry			; 4-bit bitmap
else
		fptr	0				; not supported
endif							; if _4BIT
if _8BIT
		fptr	Clr8:Clr8Entry			; 8-bit bitmap
else
		fptr	0				; not supported
endif							; if _8BIT
if _24BIT
		fptr	Clr24:Clr24Entry		; 24-bit bitmap
else
		fptr	0				; not supported
endif							; if _24BIT
if _CMYK
		fptr	cmykcode:CMYKEntry		; CMYK bitmap	
		fptr	cmykcode:CMYKEntry		; CMY bitmap
else
		fptr	0				; not supported
		fptr	0				; not supported
endif							; if _CMYK



maskInfoTable	label	fptr
if _MONO
		fptr	Mono:MonoMaskInfo
else
		fptr	0				; not supported
endif							; if _MONO
if _4BIT
		fptr	Clr4:Clr4MaskInfo
else
		fptr	0				; not supported
endif							; if _4BIT
if _8BIT
		fptr	Clr8:Clr8MaskInfo
else
		fptr	0				; not supported
endif							; if _8BIT
if _24BIT
;		fptr	Clr24:Clr24MaskInfo		; re-enable this when
		fptr	Clr24:Clr24Entry		;  24-bit implemented
else
		fptr	0				; not supported
endif							; if _24BIT
if _CMYK
		fptr	cmykcode:CMYKMaskInfo
		fptr	cmykcode:CMYKMaskInfo		; 3CMY bitmap
else
		fptr	0				; not supported
		fptr	0				; not supported
endif							; if _CMYK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VideoNull
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A null routine that takes the place of many non-implemented
		functions in vidmem

CALLED BY:	DriverStrategy (GLOBAL)
PASS:		various, depends on routine
RETURN:		carry clear
		cx clear	(Set/Test device would like this)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just clear the carry, since a few routines use that to signal
		all is ok.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VideoNull	proc	near
		clr	cx
VideoNullCLCOnly	label near
		clc
		ret
VideoNull	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VideoNullSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A null routine that takes the place of many non-implemented
		functions in vidmem that requires carry set on exit

CALLED BY:	DriverStrategy (GLOBAL)
PASS:		various, depends on routine
RETURN:		set clear
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VideoNullSet	proc	near
		stc
		ret
VideoNullSet	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialization routine for the driver.  Called when driver is
		loaded, or when a new memory space is allocated to be drawn
		to.

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry clear	- no errors possible

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		nothing for this driver;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	07/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidInit		proc	near

	; A hack for logging -- don't discard the Mono resource if logging is
	; on since that is where the log is kept (a hack, but it was quick)

ifdef	LOGGING
		push	ax, bx, dx
		mov	bx, handle Mono
		mov	ah, MODIFY_FLAGS
		clr	dl
		mov	dh, mask HF_DISCARDABLE		;make not discardable
		call	MemModify
		pop	ax, bx, dx
endif
		clc				; return no error
		ret
VidInit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a pointer to the driver info block

CALLED BY:	GLOBAL

PASS:		es	- locked window segment

RETURN:		dx:si	- pointer to DriverInfo block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Look up the bitmap segment in the window structure, then
		find the right offset (stored in the bitmap header)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	05/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidInfo	proc	near
		uses	ax, ds
		.enter

		mov	ds, es:[W_bmSegment]	; get segment of bitmap
		mov	dx, ds			; this is where we return in
		mov	ax, ds:[EB_flags]	; get edit-mask flag
		mov	si, offset EB_bm	; bump past dir header
		mov	ah, ds:[si].B_type	; grab type of bitmap
		add	si, ds:[si][CB_devInfo]	; get offset to device info
		and	ah, mask BMT_FORMAT	; isolate color format
		mov	ds:[si].VDI_bmFormat, ah ; assume NOT editing mask
		test	al, mask BM_EDIT_MASK	; see if editing mask
		jnz	editingMask
done:
		.leave
		ret

		; we're editing the bitmap mask.  Alter some info in the buffer
editingMask:
		mov	ds:[si].VDI_bmFormat, BMF_MONO
		jmp	done
VidInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:		Set some palette regs for bitmap

CALLED BY:		GLOBAL
PASS:			es	- Window segment
			dx:si	- fptr to array of RGBValues
			al	- palette register to start with
			ah	- 0 = custom palette
				  1 = default palette
			cx	- count of palette registers to change
RETURN:			nothing
DESTROYED:		nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSetPalette		proc	near
		uses	es, di
		.enter

		; setup destination of write

		clr	ah
EC <		tst	es:[W_bmSegment]	; check for valid segment >
EC <		ERROR_Z	VIDMEM_HUGE_ARRAY_PROBLEM			  >
		mov	es, es:[W_bmSegment]	; get segment of bitmap
		mov	di, offset EB_bm	; es:di -> bitmap structure
		tst	es:[di].CB_palette	; if zero, no palette
		jz	done

		; OK, so there is a palette.  Copy the values over.
		; the source palette is at dx:si

		push	ds, ax, cx
		mov	ds, dx			; ds:si -> buffer of values

		; setup destination offset

		add	di, es:[di].CB_palette	; es:di -> palette entries
		add	di, 2			; point past size
		add	di, ax			; calculate first index
		shl	ax, 1
		add	di, ax			; es:[di] -> first entry
		mov	ax, cx
		shl	cx, 1			; calc #bytes to move
		add	cx, ax
		rep	movsb			; copy the palette entries
		pop	ds, ax, cx

done:		
		.leave
		ret
VidSetPalette		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidGetPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:		Set some palette regs for bitmap

CALLED BY:		GLOBAL
PASS:			es	- Window segment
			dx:si	- fptr to array of RGBValues
			ax	- palette register to start with
			cx	- count of palette registers to change
RETURN:			cx	- #pal regs changed, or zero if no palette 
DESTROYED:		nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	11/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidGetPalette		proc	near
		uses	ds, di, ax, es, cx, si, bx
		.enter

		mov	ds, es:[W_bmSegment]	; get segment of bitmap
		mov	di, offset EB_bm	; es:di -> bitmap structure
		tst	ds:[di].CB_palette	; if zero, no palette
		jz	noPalette

		; OK, so there is a palette.  Copy the values over.

		xchg	si, di			; ds:si -> our palette,
		mov	es, dx			; es:di -> buffer to fill
		add	si, ax			
		shl	ax, 1
		add	si, ax			; ds:si -> starting offset 
		mov	ax, cx			; calc #bytes to move
		shl	cx, 1
		add	cx, ax
		rep	movsb			; fill buffer
done:		
		.leave
		ret

		; signal use of default
noPalette:
		push	ax
		clr	di			; use GetPalette
		mov	al, GPT_DEFAULT		; get the default palette
		call	GrGetPalette
		call	MemLock
		mov	ds, ax
		pop	ax
		clr	di
		xchg	si, di			; ds:si -> newly acquired pal
		mov	es, dx			; es:di -> passed buffer
		add	si, ax
		shl	ax, 1
		add	si, ax			; ds:si -> right one
		mov	ax, cx
		shl	cx, 1
		add	cx, ax			; cx = #bytes to transfer
		rep	movsb			; copy bytes over
		call	MemFree			; release block
		jmp	done
VidGetPalette		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidCheckIfFormatIsSupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the passed bitmap format is supported by
		VidMem.

CALLED BY:	
PASS:		al	= BMFormat
RETURN:		carry	= clear (supported)
			= set   (not supported)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/ 2/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidCheckIfFormatIsSupported	proc	near
		uses	ax, bp
		.enter
	;
	; if the value of the corresponding entry in the table doesn't
	; match the passed bitmap format, that bitmap format is not supported.
	;
		clr	ah
		mov	bp, ax				;bp = BMFormat
		mov	al, cs:[supportedFormatTable][bp]
		cmp	bp, ax				;supported or not?
		.leave
		ret
VidCheckIfFormatIsSupported		endp

supportedFormatTable	label	byte
if _MONO
		db	BMF_MONO
else
		db	0xff
endif	; if _MONO
if _4BIT
		db	BMF_4BIT
else
		db	0xff
endif	; if _4BIT
if _8BIT
		db	BMF_8BIT
else
		db	0xff
endif	; if _8BIT
if _24BIT
		db	BMF_24BIT
else
		db	0xff
endif	; if _24BIT
if _CMYK
		db	BMF_4CMYK
		db	BMF_3CMY
else
		db	0xff
		db	0xff
endif	; if _CMYK



DefEscapeTable	2
DefEscape	VidQEscape, 	DRV_ESC_QUERY_ESC	; query esc capability
DefEscape	VidCheckIfFormatIsSupported, VID_ESC_CHECK_IF_FORMAT_IS_SUPPORTED



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidEscape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute some escape function

CALLED BY:	GLOBAL

PASS:		di	- escape code (ORed with 8000h)

RETURN:		di	- set to 0 if escape not supported
			- return unchanged if handled

DESTROYED:	see individual functions

PSEUDO CODE/STRATEGY:
		scan through the table, find the code, call the handler.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	05/89		Initial version
	CL	11/11/95	Copied from vidcomEntry.asm

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidEscape	proc	near
		push	di		; save a few regs
		push	cx
		push	ax
		push	es		
		segmov	es, cs, cx	; es -> driver segment
		mov	ax, di		; setup match value
		mov	di, offset escCodes ; si -> esc code tab
		mov	cx, NUM_ESC_ENTRIES ; init rep count
		repne	scasw		; find the right one
		pop	es
		pop	ax
		jne	VE_notFound	;  not in table, quit

		; function is supported, call through vector

		pop	cx
		call	cs:[di+((offset escRoutines)-(offset escCodes)-2)]
		pop	di
		ret

		; function not supported, return di==0
VE_notFound:
		pop	cx		; restore stack
		pop	di
		clr	di		; set return value
		ret
VidEscape	endp

