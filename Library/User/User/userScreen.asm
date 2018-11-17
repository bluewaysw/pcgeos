COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		User/User -- Screen handling
FILE:		userScreen.asm

AUTHOR:		Adam de Boor, Sep  5, 1989

ROUTINES:
	Name			Description
	----			-----------
	UserMakeScreens		Create all screens necessary for system
	UserScreenRegister	Register another screen
	UserScreenSetCur	Set the current screen (by index)
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/ 5/89		Initial revision


DESCRIPTION:
	Functions to handle multiple screens
		
	XXX: Should be better integrated with the System object, I think.

	$Id: userScreen.asm,v 1.2 98/02/14 13:56:31 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.ioenable			; for video detection

idata		segment

;
; Data to record the order and positioning of the various screens. The array
; holds the window handles for all the root windows in left (low address) to
; right (high address) order. 16 seems to me to be a ridiculously high, and
; therefore safe, limit.  Dropped to 1 by Doug :)
; 
MAX_SCREENS	= 1
screenHandles	hptr	MAX_SCREENS dup(?)
screenDrivers	hptr	MAX_SCREENS dup(?)
screenFields	lptr	MAX_SCREENS dup(0)
screenScreens	lptr	MAX_SCREENS dup(?)
nextScreenIdx	word	0

fieldTable	label	lptr
;firstScreenNum = 0
;rept MAX_SCREENS
;	word	offset SystemField&firstScreenNum
;firstScreenNum = firstScreenNum+1
;endm
	word	offset SystemField0

;
; Data for current screen
;
curScreen	word	0		; Index of current screen
screenBounds	Rectangle <>		; Its bounds

screenCatStr 	char	'screen'
screenCatScrNum char  	'F', 0		; ranges from 0-F (hexadecimal)
;
; Monitor record for catching attempts to leave the current screen.
;
screenMonitor	Monitor	<>
idata		ends


Init segment resource



if 0	;VIDEO DETECT CODE MOVED TO LOADER. EDS 3/6/93
VIDMISC		=	12h	; Miscellaneous functions. bl selects what
				; is changed: 10h alters color/mono, mem size,
				; feature bits and switch setting.
				; 20h means to use alternate routine to print
				; the scr, when the PrtSc key is pressed.

; Definitions for the hardware itself, rather than its BIOS

HGCADDRPORT	=	03b4h	; Index register for mono adapters (e.g. HGC)
CGAADDRPORT	=	03d4h	; Index register
EGAADDRPORT	=	03d4h	; CRTC Index register (See ScrSetCursor)

; Id numbers for the different types of graphic cards.

TYPE_UNKNOWN	= 0
TYPE_MDA	= 1
TYPE_CGA	= 2
TYPE_EGA	= 3
TYPE_MCGA	= 4
TYPE_VGA	= 5
TYPE_HGC	= 6
TYPE_HGCPLUS	= 7
TYPE_INCOLOR	= 8

;For each of the above values, there is an entry in each of the following
;two tables:

videoDeviceTable lptr.char	0, 0, offset cgaDevName, offset egaDevName,
				offset mcgaDevName, offset vgaDevName,
				offset hgcDevName, offset hgcDevName, 0

videoDriverTable nptr.char	0, 0, cgaName, egaName, mcgaName,
				vgaName, hgcName, hgcName, 0
endif

;For each of the SysSimpleGraphicsMode values, there is an entry in
;each of the following two tables:

.assert (SSGM_NONE eq 0)
.assert (SSGM_VGA eq 1)
.assert (SSGM_EGA eq 2)
.assert (SSGM_MCGA eq 3)
.assert (SSGM_HGC eq 4)
.assert (SSGM_CGA eq 5)
.assert (SSGM_SPECIAL eq 6)
.assert (SSGM_SVGA_VESA eq 7)

videoDeviceTable lptr.char	\
		0,			;SSGM_NONE
		offset vgaDevName,	;SSGM_VGA
		offset egaDevName,	;SSGM_EGA
		offset mcgaDevName,	;SSGM_MCGA
		offset hgcDevName,	;SSGM_HGC
		offset cgaDevName,	;SSGM_CGA
		0,			;SSGM_SPECIAL
		offset vgaDevName	;SSGM_SVGA_VESA

videoDriverTable nptr.char	\
		0,			;SSGM_NONE
		vgaName,		;SSGM_VGA
		egaName,		;SSGM_EGA
		mcgaName,		;SSGM_MCGA
		hgcName,		;SSGM_HGC
		cgaName,		;SSGM_CGA
		0,			;SSGM_SPECIAL
		vgaName			;SSGM_SVGA_VESA

;
; 2/12/98: Changed mapping for SSGM_SVGA_VESA to use VGA.  The svga.geo
; driver doesn't work for everyone and therefore causes tech support
; calls.  VGA is a safer choice, and people with higher resolution/color
; displays can change it in setup.  -- eca
;

NEC < LocalDefNLString cgaName <'cga.geo',0>			>
NEC < LocalDefNLString egaName	<'ega.geo',0>			>
NEC < LocalDefNLString mcgaName	<'mcga.geo',0>			>
NEC < LocalDefNLString vgaName	<'vga.geo',0>			>
NEC < LocalDefNLString hgcName	<'hgc.geo',0>			>
;NEC < LocalDefNLString svgaName	<'svga.geo',0>			>

EC < LocalDefNLString cgaName	<'cgaec.geo',0>			>
EC < LocalDefNLString egaName	<'egaec.geo',0>			>
EC < LocalDefNLString mcgaName	<'mcgaec.geo',0>		>
EC < LocalDefNLString vgaName	<'vgaec.geo',0>			>
EC < LocalDefNLString hgcName	<'hgcec.geo',0>			>
;EC < LocalDefNLString svgaName	<'svgaec.geo',0>		>


if 0	;VIDEO DETECT CODE MOVED TO LOADER. EDS 3/6/93
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenFindCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the type of the graphics card that is attached to this
		system so that we can call the correct routines for screen
		manipulation.
CALLED BY:	UserScreenMakeOne
PASS:		nothing
RETURN:		Carry set if found a supported card.
		cx = the type of card.
			TYPE_UNKNOWN	0
			TYPE_MDA	1	; Unused
			TYPE_CGA	2	;
			TYPE_EGA	3
			TYPE_MCGA	4
			TYPE_VGA	5
			TYPE_HGC	6
			TYPE_HGCPLUS	7	; Unused
			TYPE_INCOLOR	8	; Unused
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserScreenFindCard	proc	near	uses dx, ax, bx
		.enter
	;
	; Check for VGA or MCGA present.
	;
		call	UserScreenFindVGAOrMCGA	; Check for VGA or MCGA card
		jc	done			; skip if found one (cx = type)
	;
	; Check for EGA present.
	;
		call	UserScreenFindEGA	; Check for the EGA card.
		mov	cx, TYPE_EGA
		jc	done
	;
	; Check for Hercules card present.
	;
		call	UserScreenFindHerc
		mov	cx, TYPE_HGC
		jc	done
	;
	; Check for CGA card
	;
		call	UserScreenFindCGA
		mov	cx, TYPE_CGA
		jc	done	 		; if not, we can't id the card
		mov	cx, TYPE_UNKNOWN
		clc

done:
		.leave
		ret
UserScreenFindCard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenFindHerc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of a hercules card.

CALLED BY:	UserScreenFindCard
PASS:		nothing
RETURN:		carry set if a Hercules card is present.
DESTROYED:	AX, CX, DX

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserScreenFindHerc	proc	near
		mov	dx,HGCADDRPORT	; dx <- crtc address of hercules
		call	UserScreenFind6845	; Try to find the crtc.
		jnc	SFH_NotFound	; 6845 exists on a hercules.
	;
	; We know it is either an MDA or an HGC.
	; Check for the sync bit of the status port changing.
	; If it does change then this is an HGC (hercules) card.
	;
		mov	dx,3bah		; dx <- status port address
		in	al,dx		; al <- value of status byte
		and	al,80h		; only interested in the sync bit.
		mov	ah,al		; ah <- bit 7 (corresponds to vertical
					;    sync bit on hercules card).
		mov	cx,8000h	; loop for a long time.
SFH_loop:			; Loop, waiting for change in sync bit.
		in	al,dx		; get status byte again.
		and	al,80h		; check status bit
		cmp	ah,al		; check for difference.
		loope	SFH_loop	; loop until bit changes or cx = 0.
		je	SFH_NotFound	; if bit hasn't changed then this is
					; not a Hercules card
		; else fall thru to signal we have found a hercules card.
;SFH_Found:			; Hercules found
		stc			; Signal found
		ret			;
SFH_NotFound:			; Hercules not found
		clc			; Signal not found
		ret			;
UserScreenFindHerc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenFindCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of a CGA card.

CALLED BY:	UserScreenFindCard
PASS:		nothing
RETURN:		carry set if a CGA card is present.
DESTROYED:	AX, CX, DX

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	mav	1/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserScreenFindCGA	proc	near
		mov	dx,EGAADDRPORT	; dx <- crtc address of hercules
		call	UserScreenFind6845	; Try to find the crtc.
	;
	; this returns the carry correctly so just return
	;
		ret
UserScreenFindCGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenFind6845
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for the existence of the crtc that is in the Hercules
		card.

CALLED BY:	UserScreenFindHerc
PASS:		nothing
RETURN:		carry set if the 6845 is found
DESTROYED:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserScreenFind6845	proc	near
		mov	al,0fh		;
		out	dx,al		; select 6845 register f (crsr low)
		inc	dx		;
		in	al,dx		; al <- current crsr low
		mov	ah,al		; save it.
		mov	al,66h		; trash value
		out	dx,al		; try to write it
		mov	cx,100h		; loop value
SF6_loop:				;
		loop	SF6_loop	; Spin wheels waiting for bit to change
		in	al,dx		;
		xchg	ah,al		; ah <- new value, al <- old value.
		out	dx,al		; restore original value.
		cmp	ah,66h		; Check for register change.
		je	SF6_Found	;
		clc			; Signal : not found.
		ret			;
SF6_Found:				;
		stc			; Signal : found.
		ret			;
UserScreenFind6845	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenFindVGAOrMCGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of an VGA card.

CALLED BY:	UserScreenGetCardType
PASS:		nothing
RETURN:		carry set if VGA or MCGA card is found.
		cx = TYPE_VGA or TYPE_MCGA
DESTROYED:	BL, AH, ...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eds	11/92		Adapted from EGA version and code from
				the VGA video driver.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserScreenFindVGAOrMCGA	proc	near

		; use the Video Display Combination BIOS call to determine
		; if VGA is present

		mov	ah, 1ah			; function code
		clr	al			; al = 0 >> Get Display Comb
		int	10h
		cmp	al, 1ah			; call successful ?
		jne	failed			; skip if not...

		;the call was successful, now check for the type of device

		cmp	bl, 7			; ignore anything below 7 or 8
		jb	failed

		mov	cx, TYPE_VGA
		cmp	bl, 9			; 7,8 = VGA (superset of MCGA)
		jb	haveMode		; skip if is VGA...
		je	failed			; skip if is type 9...

		mov	cx, TYPE_MCGA		; type 10, 11, 12: MCGA

haveMode:
		stc

done:
		ret

failed:
		clc
		jmp	short done
UserScreenFindVGAOrMCGA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenFindEGA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check for the existence of an EGA card.

CALLED BY:	UserScreenGetCardType
PASS:		nothing
RETURN:		carry set if EGA card is found.
DESTROYED:	BL, AH, ...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	1/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserScreenFindEGA	proc	near
		mov	bl,10h		; 10h == return ega info
		mov	ah, VIDMISC
		int	10h		; if bl returns unchanged then there
					; is no EGA present.
		cmp	bl,10h		;
		jne	SFE_Found	;
		; Not found if bl has not changed. (carry already clear)
		ret			;
SFE_Found:				;
		stc			; Found if bl has changed.
		ret			;
UserScreenFindEGA	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenCreateField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new field object for a screen, & set it usable

CALLED BY:	UserMakeScreenFields
PASS:		BX:SI	= screen object for which to create field
		DS	= User library dgroup
		DI	= index of screen field should be created for
RETURN:		SI	= handle of field object
DESTROYED:	AX, CX, DX, DI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserScreenCreateField proc near
		push	bx, bp, es

		segmov	es, ds

		push	bx
		push	si			; save screen object

		mov	bx, handle SystemFieldUI	; ^lbx:si = field for
		mov	si, ds:[fieldTable][di]		;	this screen

		;
		; If we have a environment application (i.e. Welcome), turn
		; off Express menu and background bitmap for the system field.
		;
		; XXX: this only really works for a single screen scenario
		;
		; Note: we can lock this and access Gen instance data because
		; the fields are defined in .ui file, so their Gen portion
		; exists already.
		;
		push	ds, si
		mov	cx, cs
		mov	dx, offset haveEnvironmentAppKey
		mov	ds, cx
		mov	si, offset haveEnvironmentAppCategory
		call	InitFileReadBoolean
		pop	ds, si
		jc	noEnvironApp		; leave express menu
		tst	ax
		jz	noEnvironApp		; leave express menu
		call	ObjSwapLock		; *ds:si = GenField
		call	ObjMarkDirty
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset	; ds:di = gen instance
.warn -private
		andnf	ds:[di].GFI_flags, not \
					(mask GFF_NEEDS_WORKSPACE_MENU or \
					 mask GFF_LOAD_BITMAP)
.warn @private
		call	ObjSwapUnlock
noEnvironApp:

		;
		; Add field as generic child of system object
		;
		mov	ax, MSG_META_ATTACH
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
					; SET vis parent for GenField
		pop	dx
		pop	cx

		mov	ax, MSG_GEN_FIELD_SET_VIS_PARENT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	dl, VUM_NOW	; Set as usable, so it comes
		mov	ax, MSG_GEN_SET_USABLE	;	up
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

					; Bring to top, let have focus, etc.
		mov	ax, MSG_GEN_BRING_TO_TOP
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		;
		; Record the handle of the screen's field now for setting the
		; default vis parent when change screens.
		; 
		mov	cx, bx
		mov	bx, ds:nextScreenIdx
		mov	ds:screenFields[bx-2], si
		mov	bx, cx

		pop	bx, bp, es
		ret
UserScreenCreateField endp

haveEnvironmentAppCategory	char	"ui", 0
haveEnvironmentAppKey		char	"haveEnvironmentApp", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an individual screen for a driver.

CALLED BY:	UserMakeScreens
PASS:		ds - dgroup of User Interface Library
		si - lmem handle of system object
		bx - block handle for UI objects like this
		bp - handle of driver to use (0 if default)
RETURN:		bx:si	- OD of screen object created
DESTROYED:	si, bp, ax, es, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserScreenCreate proc near
		push	si			; save system object
		push	bp			; Save driver to use

		;
		; Instantiate a new screen object
		; 
		mov	di, segment GenScreenClass
		mov	es, di
		mov	di, offset GenScreenClass
		call	ObjInstantiate		; Create the screen object
		;
		; Now invoke the SETUP method on the GenScreen object to
		; tell it what video driver to use.
		; 
		pop	bp
		mov	ax, MSG_GEN_SCREEN_SET_VIDEO_DRIVER
		mov	di, mask MF_CALL
		call	ObjMessage
		;
		mov	cx, bx
		mov	dx, si			; -> DX for adding
		mov	si, ds:nextScreenIdx	; Save in case initial
		mov	ds:screenScreens[si], dx
		pop	si			; get system object
		;
		; Add field as screen child of system
		; 
		mov	ax, MSG_GEN_SYSTEM_ADD_SCREEN_CHILD
		mov	bp, CCO_LAST		; put in back
		push	dx			; save handle of screen object
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si			; retrieve handle of screen
						;  object

		mov	dl, VUM_NOW		; Set as usable, so it comes
		mov	ax, MSG_GEN_SET_USABLE	;	up
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		ret
UserScreenCreate endp

		


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenMakeOne
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a single screen based on the screen number.

CALLED BY:	UserMakeScreens
PASS:		al	= screen number to create (0..MAX_SCREENS-1).
		bx	= block in which to allocate screen and field objects
RETURN:		screen and field objects created and appropriate things
		stored in the screen* arrays
DESTROYED:	bx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/23/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserScreenMakeOne proc	near	uses	ax, cx
		.enter
	;
	; Convert the screen number to hexadecimal so we can look things up
	; in the .ini file.
	; 
		add	al, '0'
		cmp	al, '9'
		jbe	10$
		add	al, ('A' - '0') - 10	; -> uppercase hex
10$:
		mov	ds:[screenCatScrNum], al


		mov	si, offset screenCatStr
		push	bx			; save object block
		mov	ax, SP_VIDEO_DRIVERS
		mov	cx, VIDEO_PROTO_MAJOR
		mov	dx, VIDEO_PROTO_MINOR
		call	UserLoadExtendedDriver
		jc	couldntLoad

driverLoaded:
	;
	; If we're creating screen 0, mark the driver as the default video
	; driver for the system.
	; 
		cmp	ds:[screenCatScrNum], '0'
		jne	createThings
		mov	ax, GDDT_VIDEO
		call	GeodeSetDefaultDriver

createThings:
		xchg	ax, bx			; ax <- driver handle
		pop	bx			; bx <- object block
	;
	; AX now contains the handle for the driver to use. Call
	; UserScreenCreate to create the screen and field objects,
	; passing BP containing the driver handle.
	; 
		xchg	bp, ax
		segmov	es, ds
		mov	si, ds:[uiSystemObj].chunk
		call	UserScreenCreate
done:
		.leave
		ret

couldntLoad:
	;
	; If we got some error besides being unable to find the device, or if
	; this is happening for some screen besides the primary one, just
	; bail.
	; 

		pop	bx			;^hbx = object block
		cmp	ax, GLE_DRIVER_INIT_ERROR
		je	20$			;skip to handle this error well

		cmp	ax, GLE_FILE_NOT_FOUND	;could not find keyword or
		stc				;file?
		jne	done			;if not, then must be some
						;other heinous error. Die...

20$:	;
	; See if error occurred while trying to load screen #0. If so,
	; then we must autodetect the video mode.
	;

		cmp	ds:[screenCatScrNum], '0'
		stc
		jne	done

if 0	;VIDEO DETECT CODE MOVED TO LOADER. EDS 3/6/93
	; Well, this is a fine howdy-do. See if we can determine the type of
	; card that's around using more primitive methods than SETUP did.
		call	UserScreenFindCard
		cmc
		jc	done
endif

	;
	; Ask the kernel which "simple" graphics mode the loader suggested
	;

		push	bx
		push	ds, di, dx

		mov	ax, SGIT_DEFAULT_SIMPLE_GRAPHICS_MODE
		call	SysGetInfo		;al = SysSimpleGraphicsMode
		clr	ah			;ax = SysSimpleGraphicsMode

EC <		cmp	al, SysSimpleGraphicsMode			   >
EC <		ERROR_A UI_LOADER_PASSED_BAD_DEFAULT_SIMPLE_GRAPHICS_MODE >
	;
	; We know the type of display the user has, so get the proper device
	; and driver names (DON'T UPDATE THE GEOS.INI FILE)
	; 

		mov	di, ax
		shl	di			; for indexing the tables...
		segmov	ds, cs, ax		; ds:si = driver name
		assume	ds:Init
		mov	si, ds:videoDriverTable[di]
		mov	di, ds:videoDeviceTable[di]
						; Lookup deviceName chunk
		tst	di			; check for unsupported video
		stc
		jz	popAndFail		; if device not known, skip...

		mov	bx, handle Strings
		call	MemLock			; Lock Strings resource
		mov	es, ax
		mov	di, es:[di]		; Dereference so that
						; es:di = device name
	;
	; Try and load the driver here so we can bail if it fails too.
	;
if FULL_EXECUTE_IN_PLACE
		push	si
		clr	cx
		call	SysCopyToStackDSSI	;dssi = driver name on stack
endif		
		mov	ax, SP_VIDEO_DRIVERS
		mov	cx, VIDEO_PROTO_MAJOR
		mov	dx, VIDEO_PROTO_MINOR
		call	UserLoadSpecificExtendedDriver
						; returns ^hbx= driver, or
						; ax = error code
if FULL_EXECUTE_IN_PLACE
		lahf
		call	SysRemoveFromStack
		pop	si
		sahf
endif
		push	bx
		mov	bx, handle Strings
		call	MemUnlock		; Release Strings resource
						; (does not affect flags)
		pop	bx			; ^hbx = driver (if ok)

popAndFail:
		pop	ds, di, dx
		assume	ds:dgroup
		LONG	jnc driverLoaded	; loop to finish up if ok...
						; (^hbx = object block still
						; on stack.)
autodetectFailed::
	;carry is set

		pop	bx
		jmp	done
UserScreenMakeOne endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserMakeScreens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create all needed screens for the system.  If no "initial
		screen" entry in the init file, the first one is set to be the
		current screen.

CALLED BY:	UserAttach
PASS:		ds - dgroup
		si - lmem handle of system object
		bx - block handle for UI objects like this
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 5/89		Initial version
	cheng	12/89		Rewrote to use the new init file routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserMakeScreens	proc	near 	uses ax,bx,di,bp,cx,dx
	.enter
	push	ds
	segmov	ds, cs, cx		; ds, cx <- cs
	mov	si, offset cs:[uiCategoryStr]
	mov	dx, offset cs:[numberOfScreensStr]
	call	InitFileReadInteger
	jnc	createScreens
	mov	ax, 1			; default to 1 screen

createScreens:
	xchg	cx, ax			; cx <- # of screens
	clr	ax			; current screen number
	pop	ds

screenLoop:
	call	UserScreenMakeOne
	inc	ax			; next screen....
	loop	screenLoop

	tst	ds:[nextScreenIdx]
	jz	noScreens

	;
	; Figure the initial screen by looking for the "initial screen"
	; key in the init file. If not found, we assume the left-most is
	; the initial screen and leave curScreen alone. Else it gets loaded
	; with the screen number * 2 specified in the init file.
	;
	push	ds
	segmov	ds, cs, cx
	mov	si, offset [uiCategoryStr]
	mov	dx, offset [initialScreenStr]
	call	InitFileReadInteger
	pop	ds
	jc	setInitial
	shl	ax			; *2 to index tables
	cmp	ax, ds:[nextScreenIdx]	; Out of bounds?
	jge	setInitial		; Yes -- use left-most
	mov	ds:[curScreen], ax	; Set as current
setInitial:

	;
	; Make the initial screen the default vis parent for any new fields
	;
	mov	si, ds:[curScreen]	; get screen index
	mov	cx, bx
	mov	dx, ds:screenScreens[si]
	mov	ax, MSG_GEN_SYSTEM_SET_DEFAULT_SCREEN
	call	UserCallSystem
		
	mov	si, offset screenBounds.R_left
	clr	dx			;start at top left of screen...
	call	UserScreenSetCur

if	(MAX_SCREENS gt 1)
	cmp	ds:[nextScreenIdx], 2
	jle	exit
	;
	; Have more than one screen -- set up a monitor to detect
	; attempts to walk off the screen.
	; 
	mov	bx, offset screenMonitor
	mov	al, ML_OUTPUT-1
	mov	cx, segment UserScreenMonitor
	mov	dx, offset UserScreenMonitor
	call	ImAddMonitor
exit:
endif
					; Position mouse & unhide it
	call	InitMousePosition
	.leave
	ret

noScreens:
	call	UserScreenNoVideoDriverError
	.unreached
UserMakeScreens	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserMakeScreenFields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create all initial fields for screens.  If no "initial screen"
		entry in the init file, the first one is set to be the current
		field.

CALLED BY:	UserAttach
PASS:		ds - dgroup
		bx - block handle of screen objects
RETURN:		Nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserMakeScreenFields	proc	near 	uses ax,bx,di,bp,cx,dx,si
	.enter
	tst	ds:nextScreenIdx
	jz	done
	clr	di
createFieldLoop:
	;
	; create field for this screen
	;
	push	di				; save index
	mov	si, ds:screenScreens[di]	; ^lbx:si = screen object
	call	UserScreenCreateField
	pop	di
	add	di, 2
	cmp	di, ds:nextScreenIdx
	jne	createFieldLoop
done:
	;
	; make the initial field the default vis parent for any new apps
	;
	mov	si, ds:[curScreen]	; get screen index
	mov	cx, handle SystemFieldUI
	mov	dx, ds:screenFields[si]
	mov	ax, MSG_GEN_SYSTEM_SET_DEFAULT_FIELD
	call	UserCallSystem

	.leave
	ret
UserMakeScreenFields	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenNoVideoDriverError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the user there's no video driver to be found whilst
		biffing the system at the same time.

CALLED BY:	UserMakeScreens, GenScreenSetVideoDriver
PASS:		nothing
RETURN:		never
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserScreenNoVideoDriverError proc	far
		mov	bx, handle Strings
		call	MemLock
		mov	ds, ax			; Setup message in ds:si
		assume	ds:Strings
		mov	si, ds:[noVideoMessage]	; Dereference
		mov	ax, SST_DIRTY		; Fast shutdown with error
		call	SysShutdown
		.UNREACHED
		assume	ds:dgroup
UserScreenNoVideoDriverError endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	InitMousePosition

DESCRIPTION:	Do initial mouse positioning, & unhide it

CALLED BY:	INTERNAL
		UserMakeScreens

PASS:
	Nothing

RETURN:
	Nothing

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/90		Initial version
------------------------------------------------------------------------------@

InitMousePosition	proc	far
strategy	local	fptr.far	; Window's strategy routine
	.enter

	; Not warping the mouse has the unfortunate side-effect of slowing
	; boot time by 35% -- Tony 2/14/92
if 0
	call	SysGetPenMode
	tst	ax		;If we are in pen mode, then leave the mouse
	jnz	noSet		; in the upper left corner of the screen, so
				; there is no calibration necessary with
				; pen drivers that simulate mice.
endif
	push	bp
				; Move mouse to initial position
	call	TimerGetCount
	mov	bp,ax			;low word of count
	andnf	bp, not (mask PI_absX or mask PI_absY)
	mov	ax, MSG_IM_PTR_CHANGE
	mov	cx, INITIAL_X_PTR_POSITION	;push this far into screen
	mov	dx, INITIAL_Y_PTR_POSITION
	clr	si
	call	ImInfoInputProcess
	mov	di,mask MF_FORCE_QUEUE
	call	ObjMessage
	pop	bp
;;;noSet:

	;
	; if there is a mouse driver, make the pointer visible
	;
	mov	ax, GDDT_MOUSE
	call	GeodeGetDefaultDriver
	tst	ax
	jz	done				; no mouse driver, no pointer

	mov	bx, segment idata
	mov	es, bx
	mov	bx, es:[curScreen]
	mov	di, es:screenHandles[bx]	; fetch win of cur screen
	mov	si, WIT_STRATEGY
	call	WinGetInfo
	mov	strategy.segment, cx
	mov	strategy.offset, dx
	push	bp		; Let the ptr become visible now
	mov	di, DR_VID_SHOWPTR
	call	strategy
	pop	bp
done:
	.leave
	ret

InitMousePosition	endp

Init ends

;-------------------

Exit segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit this module (removes monitor from IM)

CALLED BY:	UserDetach
PASS:		ds	= UI dgroup
RETURN:		Nothing
DESTROYED:	ax, bx, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserScreenExit	proc	near
	cmp	ds:nextScreenIdx, 2
	jle	notInstalled
	mov	bx, offset screenMonitor
	mov	al, mask MF_REMOVE_IMMEDIATE
	call	ImRemoveMonitor
	;
	; Need to free all the video drivers we (might have) loaded. Even if
	; we didn't load them, our GeodeUseDriver caused their refCount to
	; be incremented, so we need to reduce it by the same to make sure
	; they go away properly.
	; 
	clr	si
freeLoop:
	mov	bx, ds:screenDrivers[si]
	call	GeodeFreeDriver
	;
	; set associated field not usable
	;
	push	si
	mov	bx, handle SystemFieldUI
	mov	si, ds:screenFields[si]
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	add	si, 2
	cmp	si, ds:nextScreenIdx
	jne	freeLoop
notInstalled:
	ret
UserScreenExit	endp


Exit ends

Init segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenRegister
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register another screen for GenScreen

CALLED BY:	EXTERNAL
PASS:		cx	= handle of root window for screen
		dx	= handle of video driver for screen
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Save lots o' registers to preserve them from the video driver
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserScreenRegister	proc	far	uses ax, bx, es, si, di, dx, es
strategy	local	fptr.far	; Window's strategy routine
		.enter
		call	SysRegisterScreen	; Tell error mechanism about it

		mov	bx, segment idata
		mov	es, bx
		mov	bx, es:[nextScreenIdx]
		mov	es:screenHandles[bx], cx
		mov	es:screenDrivers[bx], dx
		add	bx, 2
		mov	es:[nextScreenIdx], bx

		;
		; Contact driver to shut off the pointer. If this is the
		; primary screen, the pointer will be turned back on when the
		; IM is told it's the one.
		; 
		mov	di, cx
		mov	si, WIT_STRATEGY
		call	WinGetInfo
		mov	strategy.segment, cx
		mov	strategy.offset, dx

		push	bp		; Save from video driver monster
		mov	di, DR_VID_HIDEPTR
		call	strategy
		pop	bp
		.leave
		ret
UserScreenRegister		endp


if	(MAX_SCREENS gt 1)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScreenCallVideoAllScreens
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes a call to the video driver for all active screens

CALLED BY:	FlowBlankScreens, FlowUnBlankScreens

PASS:		ax	- video driver function number to call

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Call the strategy routine for the root window associated
		with each screen, using the passed function.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This function could be modified to handle other video calls
		that take parameters as well as a function number.  If you
		need that capability, go for it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	12/6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScreenCallVideoAllScreens proc near
		uses	bx, cx, dx, di, si, bp, ds, es
strategyRout	local	fptr.far
		.enter

		mov	bx, segment idata
		mov	ds, bx			; ds -> idata
		mov	bx, ds:nextScreenIdx	; get array index to next avail
		sub	bx, 2			; last valid index

		; for each screen that is active, call driver to turn it off
screenLoop:
		mov	di, ds:screenHandles[bx]; Fetch root window handle 
		mov	si, WIT_STRATEGY	; Fetch video driver strategy
		call	WinGetInfo		;  routine
		mov	strategyRout.segment,cx ; save where we can use it
		mov	strategyRout.offset, dx

		; Now that we have the strategy routine, call the driver

		push	bp, bx, ax		; trashed by video driver
		mov	di, ax			; call function
		call	strategyRout
		pop	bp, bx, ax

		sub	bx, 2			; down to next screen
		jge	screenLoop		; go through all available 

		.leave
		ret
ScreenCallVideoAllScreens endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenSetCur
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current active screen.

CALLED BY:	UserScreenMonitor, UserMakeScreens
PASS:		si	= offset of new X coord for mouse
		dx	= new y coord for mouse
		curScreen= index of new screen
RETURN:		Nothing
DESTROYED:	si, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserScreenSetCur proc	far
		push	bx, ax, cx, dx, di, bp
		mov	bx, segment idata
		mov	ds, bx
		mov	bx, ds:curScreen
		mov	di, ds:screenHandles[bx]; Fetch window handle of
						;  new root
		;
		; Figure the bounding rectangle for the window
		; 
		push	bx
		push	dx
		call	WinGetWinScreenBounds
		mov	ds:screenBounds.R_left, ax
		mov	ds:screenBounds.R_top, bx
		mov	ds:screenBounds.R_right, cx
		mov	ds:screenBounds.R_bottom, dx

		mov	bx, di		; Want window handle in BX for
					;  ImSetPtrWin
		pop	dx		; Recover Y pos
		pop	di		;  and screen index
		mov	ax, ds:screenDrivers[di]
		;
		; Fetch new X coord for mouse and tell the IM where the pointer
		; should go now.
		; 
		mov	cx, ds:[si]
		call	ImSetPtrWin

		;
		; Notify the Flow object of the change. It will ensure the
		; new driver has the proper pointer image registered, then
		; give the extra kick required to turn the pointer on for the
		; new driver. Strategy routine is passed in cx:dx.
		;
		; Also passes the field object to be made the default
		; visual parent. The Flow object handles calling the
		; System object to set this.
		;
		push	si
		mov	di, ds:curScreen
		push	ds:screenFields[di]
		push	ds:screenScreens[di]
		mov	bp, ds:screenFields[di]	; for MSG_FLOW_SET_SCREEN

		mov	di, ds:screenHandles[di]
		mov	si, WIT_STRATEGY
		call	WinGetInfo

		mov	bx, ds:uiFlowObj.handle
		mov	si, ds:uiFlowObj.chunk
		mov	ax, MSG_FLOW_SET_SCREEN
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		;
		; Set the default visual parent for any new field or
		; new application
		;
		mov	bx, ds:uiSystemObj.handle
		mov	si, ds:uiSystemObj.chunk

		mov	ax, MSG_GEN_SYSTEM_SET_DEFAULT_SCREEN
		mov	cx, bx
		pop	dx
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

		mov	ax, MSG_GEN_SYSTEM_SET_DEFAULT_FIELD
		mov	cx, handle SystemFieldUI
		pop	dx
		tst	dx				; any field yet?
		jz	afterSettingDefaultField
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
afterSettingDefaultField:

		pop	si

		pop	bx, ax, cx, dx, di, bp
		ret
UserScreenSetCur endp

Init ends

;------------------------

Resident segment resource

if	(MAX_SCREENS gt 1)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserScreenMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An input monitor to detect when mouse attempts to go off
		the current screen and find a new place for it to go. We are
		only interested in MSG_PTRs

CALLED BY:	IM
PASS:		al	= MF_DATA
		di	= event type
		cx	= mouse X position (MSG_META_PTR)
		dx	= mouse Y position (MSG_META_PTR)
		bp	= <shiftState><buttonInfo> (MSG_META_PTR)
		si	= nothing (MSG_META_PTR)
		ss:sp	= IM's stack
RETURN:		al	= MF_DATA (never MF_MORE_TO_DO)
		di	= event type
		cx, dx, bp, si = event data
DESTROYED:	maybe ah, bx, ds, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserScreenMonitor proc	far
		mov	bx, segment idata
		mov	ds, bx
		cmp	di, MSG_META_PTR
		jne	USM_ret
		cmp	cx, ds:screenBounds.R_left
		jl	USM_goLeft
		cmp	cx, ds:screenBounds.R_right
		jg	USM_goRight
USM_ret:
		ret
USM_goLeft:
		push	si
		;
		; Warp to right side of new screen
		; 
		mov	si, offset screenBounds.R_right
		;
		; Point bx at next screen to left
		; if went off the edge
		; 
		mov	bx, ds:curScreen
		tst	bx
		jz	USM_doNothing
		sub	bx, 2
		jmp	short USMgoCommon
USM_goRight:
		push	si
		;
		; Warp to left side of new screen
		; 
		mov	si, offset screenBounds.R_left
		mov	bx, ds:curScreen
		add	bx, 2
		cmp	bx, ds:nextScreenIdx
		je	USM_doNothing
USMgoCommon:
		mov	ds:curScreen, bx
		
		call	UserScreenSetCur
		
		mov	cx, ds:[si]
USM_doNothing:
		pop	si
		ret
UserScreenMonitor endp
endif

Resident ends
