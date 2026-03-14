
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Video Drivers
FILE:		vidcomInfo.asm

AUTHOR:		Jim DeFrisco, 7/31/90

ROUTINES:
	Name			Description
	----			-----------
	VidInit			standard driver init call
	VidExit			standard driver exit call
	VidSetDevice		set the current device enum
	VidTestDevice		test for the existance of a device
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/30/90		Initial revision


DESCRIPTION:
	This file contains the code to supply/return info about the 
	specific video device being supported by the driver.  
		
	$Id: vidcomInfo.asm,v 1.1 97/04/18 11:41:51 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; It is non-standard to put this here, but this is the only video file
; that will this constant.
ifdef WIN32
	NT_DRIVER = -1
else
	NT_DRIVER = 0
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Standard call on driver loading

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry	- clear if successful load

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		get the current video mode, so we can restore in on exit

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidInit		proc	near
		uses	ax,bx,dx
		.enter

		; reset the deviceEnum to prohibit any function calls from
		; happening...

		mov	cs:[DriverTable].VDI_device, 0xffff

		; we have our own little stack, so save away some important
		; stuff

		mov	cs:[TPD_stackBot], offset dgroup:vidStackBot
		mov	cs:[TPD_blockHandle], handle dgroup
		mov	cs:[TPD_processHandle], handle 0

if 0		;MOVED to Loader -EDS 3/6/93
		; get the current video mode.  The VESA standard says that
		; this should work with VESA boards as well...
		; (VESA Super VGA Standard VS891001, page 6, 10/1/89)
  ifndef	IS_CASIO
		mov	ah, GET_VMODE			; get current mode
		int	VIDEO_BIOS
		mov	cs:[prevVideoMode], al		; save it for later
  endif
endif

		;Ask the Kernel for video configuration information that
		;was determined by the loader.

		mov	ax, SGIT_INITIAL_TEXT_MODE
		call	SysGetInfo			;al = SysInitialTextMode
		mov	cs:[prevVideoMode], al		; save it for later

		call	SetDevicePalette

		clc

		.leave
		ret

VidInit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Standard call on driver exiting

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		restore the previous video mode

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	09/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidExit		proc	near
		uses	ax,bx
		.enter
if NT_DRIVER
		push	ds
		;
		; Tell our windows DLL it is no longer needed
		;
		segmov	ds, dgroup
		mov	ax, ds:[vddHandle]
		mov	bx, 109			; destroy the window
		push	ax
		DispatchCall
		pop	ax
		UnRegisterModule
		clr	ds:[vddHandle]
		pop	ds
endif
		cmp	cs:[DriverTable].VDI_device, 0xffff
		je	done

if not NT_DRIVER
		; get the previous video mode.  The VESA standard says that
		; this should work with VESA boards as well...
		; (VESA Super VGA Standard VS891001, page 6, 10/1/89)

		mov	ah, SET_VMODE			; set current mode
		mov	al, cs:[prevVideoMode]		; restore it 
		int	VIDEO_BIOS
endif
done:
		.leave
		ret
VidExit		endp


VideoMisc	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSetDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new video mode for the driver.

CALLED BY:	GLOBAL
		DriverStrategy

PASS:		dx:si	- pointer to null-terminated device name string

RETURN:		ax	- DP_INVALID_DEVICE if bad string passed
			  DP_PRESENT if device set correctly

DESTROYED:	di

PSEUDO CODE/STRATEGY:
		This function sets the current device and initializes it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidSetDevice	proc	far
		uses	bx, cx, ds, bp, si, ds, es
		.enter
		EnumerateDevice VideoDevices	; parse the passed string
		jc	notFound
		call	MemUnlock		; unlock info resource
		mov	ax, dgroup
		mov	ds, ax
		mov	ds:[DriverTable].VDI_device, di	; save it

		; do any device-specific initialization
alreadySet:
		call	cs:[vidSetRoutines][di]
		
		; now that device-specific initialization is out of the way,
		; do some common stuff, like showing the cursor

		mov	ds:[cursorCount],1	;start hidden
		mov	si, -1			; start with default cursor
		call	VidSetPtrFar
		mov	ds:[videoEnabled], 1	; video is ON
		mov	ax, DP_PRESENT
done:
		.leave
		ret
notFound:	
		mov	ax, dgroup
		mov	ds, ax
		mov	di, ds:[DriverTable].VDI_device
		cmp	di, 0xFFFF
		jne	alreadySet
		jmp	done
		
		endp

idata	segment
VidSetPtrFar	proc	far
		call	VidSetPtr
		ret
VidSetPtrFar	endp
idata	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidTestDevice
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test for the existance of a device

CALLED BY:	GLOBAL
		DriverStrategy

PASS:		dx:si	- points at null-terminated device name string

RETURN:		carry	- SET if string did not map to any supported device
			- CLEAR otherwise
		ax	- DevicePresent enum
			
DESTROYED:	di

PSEUDO CODE/STRATEGY:
		check for the device

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VidTestDevice	proc	far
		uses	bx, cx, ds, es
		.enter
;		call	SysEnterInterrupt	; protect other video
						;  drivers if we've been
						;  loaded just to test
						;  for the existence of
						;  a device...

		EnumerateDevice VideoDevices	; get device enum
		jc	done
		call	MemUnlock

		call	cs:[vidTestRoutines][di]
		clc				; signal we found the string
done:
;		call	SysExitInterrupt
		.leave
		ret
VidTestDevice	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put the video board into stasis

CALLED BY:	DR_SUSPEND
PASS:		cx:dx	= buffer for reason for failure to suspend, if such
			  there be
RETURN:		carry set if can't suspend
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidSuspend	proc	far
		uses	ds
		.enter
		segmov	ds, dgroup, ax
		cmp	ds:[DriverTable].VDI_device, 0xffff
		je	done
		
		; get the previous video mode.  The VESA standard says that
		; this should work with VESA boards as well...
		; (VESA Super VGA Standard VS891001, page 6, 10/1/89)

		mov	ah, SET_VMODE			; set current mode
		mov	al, ds:[prevVideoMode]		; restore it 
		int	VIDEO_BIOS
		
		ornf	ds:[driverState], mask VS_IGNORE_SPLASH_MODE
		clc
done:
		.leave
		ret
VidSuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VidUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return to our desired video mode.

CALLED BY:	DR_UNSUSPEND
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VidUnsuspend	proc	far
		uses	ds
		.enter
	;
	; Just call the DRE_SET_DEVICE routine specific to the chosen board
	; to get it into the right mood.
	; 
		segmov	ds, dgroup, ax
		mov	di, ds:[DriverTable].VDI_device
		call	cs:[vidSetRoutines][di]	; destroys nothing,
						;  supposedly...
		.leave
		ret
VidUnsuspend	endp

VideoMisc	ends
