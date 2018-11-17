COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Boot
FILE:		bootInitfile.asm

AUTHOR:		Cheng, 11/89

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	11/89		Initial revision

DESCRIPTION:
		
	$Id: bootInitfile.asm,v 1.1 97/04/05 01:10:51 newdeal Exp $

-------------------------------------------------------------------------------@


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ProcessInitFileBeforeGr, ProcessIniFileAfterGr

DESCRIPTION:	Searches the init file for drivers to load (crucial info)
		as well as for specifiers for additional drivers (optional).

CALLED BY:	INTERNAL (InitGeos)

PASS:		ds - seg addr of idata

RETURN:		ds - seg addr of idata

DESTROYED:	ax,bx,cx,dx,di,si,bp,es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

ProcessInitFileBeforeGr		proc	near

if	ERROR_CHECK
	call	GetEC
endif

	call	GetFontId
	call	GetFontSize
	ret
ProcessInitFileBeforeGr		endp

ProcessInitFileAfterGr		proc	near

	call	LoadPathMods
	call	LoadMemoryDriver
	call	LoadKeyboardDriver

	;
	; if the initfile contains "noFontDriver = true" under the system
	; category, then do not load the font driver.
	;
	
	push 	ds
	mov	cx, cs
	mov	dx, offset cs:[noFontDriverKeyString]
	mov	ds, cx
	mov	si, offset cs:[systemCategoryString]
	call	InitFileReadBoolean
	pop	ds

	jc	loadFont		; if no key, load font driver
	tst	ax			; if noFontDriver = false, load it.
	jz	loadFont
	jmp 	noFont

loadFont:
	call	LoadFontDriver

noFont:

	call	LoadUI

	ret
ProcessInitFileAfterGr		endp

;these are the default values

penModeKey		char	"penBased",0
penClicksKey		char	"inkTimeout",0
penWidthKey		char	"penWidth",0
autoCursorCenteringKey	char	"autoCursorCentering", C_NULL
LocalDefNLString defaultKeyboardName	<"kbd.geo", 0>

NEC< LocalDefNLString defaultFontDrvName <"nimbus.geo", 0>		>
EC< LocalDefNLString defaultFontDrvName <"nimbusec.geo", 0>		>

NEC< LocalDefNLString defaultUiName <"ui.geo", 0>			>
EC< LocalDefNLString defaultUiName <"uiec.geo", 0>			>

NEC < LocalDefNLString defaultMemoryName <"disk.geo", 0>		>
EC< LocalDefNLString defaultMemoryName <"diskec.geo",0>			>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadPathMods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load (hacked) initfile mods to std paths, if any.

CALLED BY:	ProcessInitFileAfterGr

PASS:		ds - idata

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	This is purely and completely a hack.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine is called pretty late in the game.  I'm assuming
	that the SP_DOCUMENT directory isn't used before now!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadPathMods	proc near
	uses	cx,si,dx,ax
	.enter
	push	ds
	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:[systemCategoryString]
	mov	dx, offset cs:[docIsTopKeyString]
	call	InitFileReadBoolean
	pop	ds
	jc	done
	
	mov	ds:[documentIsTop], al		; TRUE or FALSE
done:
	.leave
	ret
LoadPathMods	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadPenDefaults
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine loads up the pen defaults from the .ini file

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/18/91	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DEFAULT_INK_TIMEOUT	equ	54	;9/10 of a second
DEFAULT_INK_WIDTH	equ	2

LoadPenDefaults	proc	near	uses	ds, es
	.enter
	LoadVarSeg	es, dx
	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:[systemCategoryString]
	mov	dx, offset penModeKey
	call	InitFileReadBoolean
	jc	noSetMode	;If no .ini entry, exit (leave as default)
	mov	es:[penBoolean], ax
noSetMode:
	mov	ax, DEFAULT_INK_TIMEOUT
	mov	dx, offset penClicksKey
	call	InitFileReadInteger
	mov	es:[penTimeout], ax

	mov	ax, DEFAULT_INK_WIDTH
	mov	dx, offset penWidthKey
	call	InitFileReadInteger
	mov	ah, al
	mov	es:[inkDefaultWidthAndHeight], ax

	clr	ax			; default = FALSE
	mov	dx, offset autoCursorCenteringKey
	call	InitFileReadBoolean
	mov	es:[autoCenterBoolean], al

	.leave
	ret
LoadPenDefaults	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadKeyboardDriver

DESCRIPTION:	Retrieve and load the keyboard driver specified.

CALLED BY:	INTERNAL (ProcessInitFile)

PASS:		nothing

RETURN:		carry clear if successful

DESTROYED:	ax,bx,cx,dx,bp,di,si,ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

LoadKeyboardDriver	proc	near
	mov	dx, offset cs:[kbdDriverString]
	mov	si, offset cs:[kbdCategoryString]
	call	GetString
	jc	useDefault

	mov	ax, SP_KEYBOARD_DRIVERS
	mov	cx, KEYBOARD_PROTO_MAJOR
	mov	dx, KEYBOARD_PROTO_MINOR
	call	LoadDriver		;ax,bx,ds <- func(ds:si)
	jnc	done

useDefault:
	mov	si, offset cs:[defaultKeyboardName]
	mov	ax, SP_KEYBOARD_DRIVERS
	segmov	ds, cs
	mov	cx, KEYBOARD_PROTO_MAJOR
	mov	dx, KEYBOARD_PROTO_MINOR
	call	LoadDriver
	ERROR_C	CANNOT_LOAD_KEYBOARD_DRIVER
done:
	mov	ds:[defaultDrivers].DDT_keyboard, bx
	call	DoneWithString
	ret
LoadKeyboardDriver	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadFontDriver

DESCRIPTION:	Load the font driver specified.

CALLED BY:	INTERNAL (ProcessInitFile)

PASS:		nothing

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

InitFontDriver	proc	near	; Callback for ProcessStartupList to init
				;  a font driver.
	push	cx, si, ds
	LoadVarSeg	ds, cx
	call 	GrInitFontDriver	; destroys ax,bx,cx,dx,si,ds
	pop	cx, si, ds
	ret
InitFontDriver	endp

LoadFontDriver	proc	near
	mov	dx, offset cs:[fontDrvString]
	mov	bp, offset InitFontDriver	;bp <- callback routine

	call	GetSystemString
	jc	useDefault

	mov	di, SP_FONT_DRIVERS
	mov	cx, FONT_PROTO_MAJOR
	mov	dx, FONT_PROTO_MINOR
	call	ProcessStartupList
	tst	cx
	jnz	exit		; => something loaded

useDefault:
	mov	si, offset cs:[defaultFontDrvName]
	segmov	ds, cs
	mov	di, SP_FONT_DRIVERS
	mov	cx, FONT_PROTO_MAJOR
	mov	dx, FONT_PROTO_MINOR
	call	ProcessStartupList

exit:
	call	DoneWithString
	ret
LoadFontDriver	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ProcessStartupList

DESCRIPTION:	Break a string into its component geode names and load each
		in turn, calling the specified routine for any extra
		initialization required.

CALLED BY:	INTERNAL (LoadFontDriver, LoadMemoryDriver)

PASS:		di - StandardPath constant
		cx.dx - protocol number expected
		ds:si - ptr to list of programs
		bp - routine to call in kinit when a driver is succesfully
		     loaded

RETURN:		cx - number of drivers loaded

DESTROYED:	ax, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version
	Adam	6/90		Changed to load things and call callback
	Eric	2/93		Rewrite to handle initial whitespace and
				null strings better.

-------------------------------------------------------------------------------@

ProcessStartupList	proc	near
	push	bx
	clr	bx			;init program count
SBCS <	mov	ah, bh			;ah = 0 (used below)		>

handleWhiteSpace:
	;Skip any initial white-space chars

	LocalGetChar	ax, dssi	;ax = character from string
	LocalIsNull	ax		;reached end of string?
	jz	done			;skip if so...

	call	IsWhiteSpace		;space, tab, CR, etc.?
	jnc	handleWhiteSpace	;loop if so...

	LocalPrevChar	dssi		;point to first non-white-space char

findEndOfName::
	;we have reached the start of a non-null name

	push	si			;save offset to start of name

scanLoop: ;scan until the end of this name (white space or null-term)
	LocalGetChar	ax, dssi
	LocalIsNull	ax		;reached null terminator?
	jz	loadThisName		;skip to load this name if so...

	call	IsWhiteSpace		;space, tab, CR, etc?
	jc	scanLoop		;loop for next char if not...

SBCS <	mov	ds:[si-1], ah		;terminate this string		>
DBCS <	mov	{wchar}ds:[si-2], 0	;terminate this string		>

loadThisName:
	XchgTopStack si			;fetch string start &
					;save string end
	push	ax			;save char which ended string
	push	bx			;save program count

	push	bp, cx, dx, di, ds	;save important registers
	mov	ax, di
	call	LoadDriver
	pop	bp, cx, dx, di, ds
	jc	loadError		;skip if error loading driver...

	tst	bp			;any callback?
	jz	countEntry

	call	bp			;call the callback routine

countEntry:
	pop	bx			;restore bx = program count
	inc	bx			;another driver loaded

nextEntry:
	;-----------------------------------------------------------------------
	;end of string?

	pop	ax			;recover terminator
	pop	si			;and addr of byte after it
	LocalIsNull	ax		;did we hit the null?
	jnz	handleWhiteSpace	;loop if not...

done:
	mov	cx, bx
	pop	bx
	ret

loadError:
	pop	bx
	jmp	nextEntry
ProcessStartupList	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetFontId

DESCRIPTION:	Get the default font specified in the .ini file and it's ID

CALLED BY:	INTERNAL (ProcessInitFile)

PASS:		ds - seg addr of idata
RETURN:		ds:defaultFontID - ID of default font (FontID)

DESTROYED:	ax, bx, cx, dx, si, di, es

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Assumes the list of available fonts has been built.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version
	Gene	2/90		Commented, rewrote to use GrEnumFonts

-------------------------------------------------------------------------------@

GetFontId	proc	near

	push	ds				;save seg addr of idata

	mov	dx, offset cs:[fontIdString]
	call	GetSystemString			;ds:si <- font name
	jc	fontError			;branch if error
	mov	dl, mask FEF_BITMAPS \
		 or mask FEF_STRING \
		 or mask FEF_DOWNCASE		;dl <- font types to check
	call	GrCheckFontAvail			;see if font available
	jcxz	fontError			;branch if not found
doStore:
	pop	ds				;ds <- seg addr of idata
	mov	ds:defaultFontID, cx		;store the new font id
	call	DoneWithString			;free string buffer
	ret

fontError:
	;
	; Error: block couldn't be allocated, or init file string
	; couldn't be found. Default to Berkeley, and hope it exists.
	;
	mov	cx, DEFAULT_FONT_ID		;cx <- default font id
	jmp	doStore
GetFontId	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetEC

DESCRIPTION:	Get the EC level

CALLED BY:	INTERNAL (ProcessInitFile)

PASS:		ds - seg addr of idata
RETURN:		ds:sysECLevel

DESTROYED:	ax, bx, cx, dx, si, di, es

REGISTER/STACK USAGE:
PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Assumes the list of available fonts has been built.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version
	Gene	2/90		Commented, rewrote to use GrEnumFonts

-------------------------------------------------------------------------------@

if	ERROR_CHECK

GetEC		proc	near

;SSP <	mov	ds:[sysECLevel], mask ECF_NORMAL or mask ECF_SEGMENT or mask ECF_FREE or mask ECF_LMEM>
	mov	dx, offset cs:[ecIdString]
	call	GetSystemInteger		;ax = value

	clr	bx				;0 = ec none
	tst	ax
	jz	setEC
	mov	bx, mask ECF_NORMAL or mask ECF_SEGMENT
						;1 = ec segment normal
	cmp	ax, 1
	jz	setEC
	mov	bx, mask ECF_NORMAL or mask ECF_SEGMENT or \
			mask ECF_FREE or mask ECF_LMEM
						;2 = ec segment normal + mem
	cmp	ax, 2
	jz	setEC
	mov	bx, mask ECF_NORMAL or mask ECF_SEGMENT or \
			mask ECF_FREE or mask ECF_LMEM \
			or mask ECF_GRAPHICS or \
			mask ECF_VMEM
						;3 = ec all
	cmp	ax, 3
	jz	setEC
	jmp	done

setEC:
	mov	ds:[sysECLevel], bx

ec_set	label	near
	ForceRef	ec_set		; for swat "ec" command
done:
	ret

GetEC	endp

endif



COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetFontSize

DESCRIPTION:	Retrieve the default pointsize.

CALLED BY:	INTERNAL (ProcessInitFile)

PASS:		ds - seg addr of idata

RETURN:		ds:defaultFontSize - set to default pointsize

DESTROYED:	ax,cx,dx,si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

GetFontSize	proc	near
	mov	dx, offset fontsizeString
	call	GetSystemInteger
	jnc	found				;branch if no error
	mov	ax, DEFAULT_FONT_SIZE		;ax <- default font size
found:
	mov	ds:defaultFontSize, ax		;store new font size
	ret
GetFontSize	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadMemoryDriver

DESCRIPTION:	Load any swap drivers specified by the memory = key in
		the [system] category. If the key is missing, load whatever
		seems appropriate.

CALLED BY:	INTERNAL (ProcessInitFile)

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,si,ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@
nomemFlag	char	'nomem', 0

LoadMemoryDriver	proc	near
	;
	; if /nomem passed, load only the disk swap driver.
	;
	mov	si, offset nomemFlag
	call	SysCheckArg
	jc	loadDiskDriver

	mov	dx, offset cs:[memDrvString]
	call	GetSystemString			;present?, ds:si <- str
	jnc	load				;check for presence ourselves

	call	LoadEMS				;load EMS if present
	call	LoadXMS				;load XMS if present
	call	LoadExtMem			;load ExtMem if present
	
loadDiskDriver:
	mov	si, offset cs:[defaultMemoryName]
	segmov	ds, cs
load:
	clr	bp				; no callback
	mov	di, SP_SWAP_DRIVERS
	mov	cx, SWAP_PROTO_MAJOR
	mov	dx, SWAP_PROTO_MINOR
	call	ProcessStartupList
	call	DoneWithString			;free any string that was
						; allocated for us.
	ret
LoadMemoryDriver	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadEMS

DESCRIPTION:	Determines if an Expanded Memory Manager is present and
		loads the driver for it if so

CALLED BY:	INTERNAL (LoadMemoryDriver)

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, di, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Uses the 'get interrupt vector technique' to determine if an
	EMS manager is present. The vector at 67h is retrieved
	and a string comparison is done to see if the name of the
	driver that is present matches that of the EM manager.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/89		Initial version

-------------------------------------------------------------------------------@

LoadEMS	proc	near	uses ds, es
	.enter

	clr	ax
	mov	es, ax
	mov	es, es:[67h * dword].segment

	mov	di, 0ah
	mov	ax, cs
	mov	ds, ax
	lea	si, cs:[emm_device_name]
	mov	cx, length emm_device_name;number of bytes to compare
	cld
	repe	cmpsb

	jnz	done

	mov	ah, 40h			;check status of driver
	int	67h			;call EMM
	tst	ah			;test for error
	jnz	done
	;
	; Manager is ready and accounted for -- load the EMS driver (ds is
	; already cs...)
	;
	mov	si, offset emm_name
	mov	ax, SP_SWAP_DRIVERS
	mov	cx, SWAP_PROTO_MAJOR
	mov	dx, SWAP_PROTO_MINOR
EC <	segmov	es, ds					>
					; put valid segment in es so
					; ec segment won't die -- dl
	call	LoadDriver
done:
	.leave
	ret
LoadEMS	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadXMS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load driver for XMS (extended memory manager) if it's present

CALLED BY:	LoadMemoryDriver
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadXMS		proc	near	uses ds
		.enter
	;
	; XMS can only be around for DOS 3.0 and above...
	;
		LoadVarSeg	ds, ax
		cmp	ds:[dosVersion].low, 3
		jb	done

		mov	ax, 4300h	; See if XMS manager is present (q.v.
		int	2fh		;  XMS spec p. 2-2)

		cmp	al, 80h
		jne	done
		;
		; Manager is there. Load driver for it.
		;
		mov	si, offset cs:xms_name
		segmov	ds, cs
		mov	ax, SP_SWAP_DRIVERS
		mov	cx, SWAP_PROTO_MAJOR
		mov	dx, SWAP_PROTO_MINOR
		call	LoadDriver
done:
		.leave
		ret
LoadXMS		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadExtMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load driver for unmanaged extended memory

CALLED BY:	LoadMemoryDriver
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx, cx, di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadExtMem	proc	near	uses ds
		.enter
		mov	ah, 88h		;call function to get size of ext mem
		int	15h
		test	ah, 0x80	;some BIOSes return carry set even if
					; there is extended memory. On machines
					; that don't support extended memory,
					; the carry will come back set w/either
					; 0x80 or 0x86 in AH. Since a machine
					; cannot possibly have 0x8000 K of
					; extended memory, it strikes me as
					; safe to test the high bit of AH for
					; an error return.
		jnz	done

		tst	ax
		jz	done		; => none there

		;
		; Memory is there. Load driver for it.
		;
		mov	si, offset cs:extMem_name
		segmov	ds, cs
		mov	ax, SP_SWAP_DRIVERS
		mov	cx, SWAP_PROTO_MAJOR
		mov	dx, SWAP_PROTO_MINOR
		call	LoadDriver
done:
		.leave
		ret
LoadExtMem	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadUI

DESCRIPTION:	Load the generic UI

CALLED BY:	INTERNAL (ProcessInitFile)

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

LoadUI	proc	near
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath

	mov	dx, offset cs:[genericString]
	call	GetUIString	;ds:si <- generic ui ASCIIZ string
	jc	useDefault

	clr	cx			; any attributes...
	clr	di
	clr	bp
	mov	dx, cx			;  I mean any
	call	GeodeLoad
	jnc	done

useDefault:
	mov	si, offset cs:[defaultUiName]
	segmov	ds, cs
	clr	cx
	clr	di
	clr	bp
	mov	dx, cx
	call	GeodeLoad
	ERROR_C	CANNOT_LOAD_UI

done:
	LoadVarSeg	ds, ax
	mov	ds:[uiHandle], bx
	mov	ds:[uiHandleInternal], bx
	call	DoneWithString
	ret
LoadUI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSystemInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch an integer for a key in the [system] category

CALLED BY:	GetFontSize, OpenSwap
PASS:		dx	= offset in kinit of key string
RETURN:		ax	= value
		ds	= idata
		carry set if key not found
DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSystemInteger proc	near
		.enter
		mov	cx, cs
		mov	ds, cx
		mov	si, offset cs:[systemCategoryString]
		call	InitFileReadInteger
		LoadVarSeg	ds, cx
		.leave
		ret
GetSystemInteger endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetSystemString

DESCRIPTION:	Locate and return the body of the given key under the
		system category in the init file.

CALLED BY:	INTERNAL (LoadVideoDriver, LoadKeyboardDriver, LoadMouseDriver,
			  LoadFontId)

PASS:		dx - offset to key ASCIIZ string

RETURN:		carry clear if successful
			ds:si - pointer to retrieved string
		else carry set
			category/key not located

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

GetSystemString	proc	near
	mov	si, offset cs:[systemCategoryString]
	GOTO	GetString
GetSystemString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetUIString

DESCRIPTION:	Locate and return the body of the given key under the
		ui category in the init file.

CALLED BY:	INTERNAL (LoadGenUI, LoadSpecificUI)

PASS:		dx - offset to key ASCIIZ string

RETURN:		carry clear if successful
			ds:si - pointer to retrieved string
		else carry set
			category/key not located

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

GetUIString	proc	near
	mov	si, offset cs:[uiCategoryString]
	FALL_THRU	GetString
GetUIString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	GetString

DESCRIPTION:	Fetch a string from the ini file

CALLED BY:	INTERNAL (GetSystemString, GetUIString)

PASS:		si - offset from cs to category ASCIIZ string
		dx - offset from cs to key ASCIIZ string

RETURN:		carry clear if successful
			ds:si - pointer to retrieved string

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

GetString	proc	near
	uses	ax, bx, cx, bp, di, es
	.enter

	LoadVarSeg	es, ax
	mov	es:[bootInitFileBufHan], 0

	mov	cx, cs
	mov	ds, cx

	clr	bp			;get routine to return buffer
	call	InitFileReadString	;bx - handle to buffer
	jc	exit

	mov	es:[bootInitFileBufHan], bx
	call	MemLock
	mov	ds, ax
	clr	si
exit:
	.leave
	ret
GetString	endp


IsWhiteSpace	proc	near
if DBCS_PCGEOS
	cmp	ax, ' '
	ja	notWhitespace
	je	whiteSpace
	cmp	ax, '\r'
	je	whiteSpace
	cmp	ax, '\n'
	je	whiteSpace
	cmp	ax, '\t'
	je	whiteSpace
notWhitespace:
else
	cmp	al, '\r'
	je	whiteSpace
	cmp	al, '\n'
	je	whiteSpace
	cmp	al, ' '
	je	whiteSpace
	cmp	al, '\t'
	je	whiteSpace
endif
	stc
	ret
whiteSpace:
	clc
	ret
IsWhiteSpace	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	DoneWithString

DESCRIPTION:	Frees the buffer used by the GetString operation

CALLED BY:	INTERNAL (routines that call GetSystemString and GetUIString)

PASS:		bootInitFileBufHan = holds current buffer

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

DoneWithString	proc	near
	uses	bx, ds
	.enter

	LoadVarSeg	ds, bx
	mov	bx, ds:[bootInitFileBufHan]
	tst	bx
	jz	done
	call	MemFree
	clr	ds:[bootInitFileBufHan]
done:
	.leave
	ret
DoneWithString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadDriver

DESCRIPTION:	Calls GeodeLoad.

CALLED BY:	INTERNAL (LoadVideoDriver, LoadKeyboardDriver, LoadMouseDriver)

PASS:		ax - StandardPath enum
		ds:si - driver ASCIIZ string
		cx.dx - expected driver protocol

RETURN:		ds - idata seg
		carry clear if successful
			ax - segment address of geode's core block
			bx - handle to new geode

DESTROYED:	cx,dx,bp,di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

LoadDriver	proc	near
SBCS <	call	LogWriteInitEntry					>
DBCS <	call	LogWriteDBCSEntry					>

	call	FileSetStandardPath	; move to SYSTEM directory
EC <	ERROR_C	SET_PATH_ERROR						>
	clr	di
	clr	bp
	mov_tr	ax, cx			; ax <- major protocol
	mov	bx, dx			; bx <- minor protocol
	call	GeodeUseDriver
	LoadVarSeg	ds, di		;this is useful for callers
	ret
LoadDriver	endp


