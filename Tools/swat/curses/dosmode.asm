COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosmode.asm

AUTHOR:		Adam de Boor, Jul 26, 1992

ROUTINES:
	Name			Description
	----			-----------
	DosModeSet25Line
	DosModeSet43Line
	DosModeSet50Line
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/26/92		Initial revision


DESCRIPTION:
	Functions for changing the video mode.

	$Id: dosmode.asm,v 1.1 92/07/26 16:46:46 adam Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

_CODE	segment dword public 'CODE'
CGROUP	group _CODE
	assume cs:CGROUP

include	dosx.ah

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosModeSet25Line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the screen to be 25-lines high

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	eax, ecx, fs

PSEUDO CODE/STRATEGY:
		This code comes from p.575 of "Programmer's Guide to the EGA
		and VGA Cards", by Richard F. Ferraro

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	DosModeSet25Line
DosModeSet25Line proc	near
		push	ebx
	;
	; Fetch current page.
	;
		mov	ah, 0fh
		int	10h
		mov	bl, bh
		push	bx
	;
	; Make page 0 the active one
	; 
		mov	ax, 0500h
		int	10h
	;
	; Load 8x14 font in block 0
	; 
		mov	ax, 1111h
		mov	bl, 0
		int	10h
	;
	; Set bit 0 of 0:487h non-zero to enable cursor emulation
	; 
		mov	ax, SS_DOSMEM
		mov	fs, ax
		or	byte ptr fs:[487h], 1
	;
	; Set cursor position to a three-line underline from 11 to 14
	; 
		mov	cx, 0b0dh
		mov	ah, 1
		int	10h
	;
	; Reset bit 0 of 487h to disable cursor emulation.
	; 
		and	byte ptr fs:[487h], not 1
	;
	; Adjust the underline location.
	; 
		mov	dx, 3d4h
		mov	al, 14h
		out	dx, al
		inc	dx
		mov	al, 0dh
		out	dx, al
	;
	; Reset the active page to its previous value.
	; 
		pop	ax
		mov	ah, 5
		int	10h

		pop	ebx
		ret
DosModeSet25Line endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosModeSet43Line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the screen to be 43-lines high

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	eax, ecx, fs

PSEUDO CODE/STRATEGY:
		This code comes from p.576 of "Programmer's Guide to the EGA
		and VGA Cards", by Richard F. Ferraro

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	DosModeSet43Line
DosModeSet43Line proc	near
		push	ebx
	;
	; Fetch current page.
	;
		mov	ah, 0fh
		int	10h
		mov	bl, bh
		push	bx
	;
	; Make page 0 the active one
	; 
		mov	ax, 0500h
		int	10h
	;
	; Load 8x8 font in block 0
	; 
		mov	ax, 1112h
		mov	bl, 0
		int	10h
	;
	; Set bit 0 of 0:487h non-zero to enable cursor emulation
	; 
		mov	ax, SS_DOSMEM
		mov	fs, ax
		or	byte ptr fs:[487h], 1
	;
	; Set cursor position to a three-line underline from 0 to 6
	; 
		mov	cx, 0006h
		mov	ah, 1
		int	10h
	;
	; Reset bit 0 of 487h to disable cursor emulation.
	; 
		and	byte ptr fs:[487h], not 1
	;
	; Adjust the underline location.
	; 
		mov	dx, 3d4h
		mov	al, 14h
		out	dx, al
		inc	dx
		mov	al, 07h	; set underline to line 7
		out	dx, al
	;
	; Reset the active page to its previous value.
	; 
		pop	ax
		mov	ah, 5
		int	10h

		pop	ebx
		ret
DosModeSet43Line endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DosModeSet50Line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the screen to be 50-lines high

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	eax, ecx, fs

PSEUDO CODE/STRATEGY:
		This code comes from p.577 of "Programmer's Guide to the EGA
		and VGA Cards", by Richard F. Ferraro

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	DosModeSet50Line
DosModeSet50Line proc	near
		push	ebx
	;
	; Fetch current page.
	;
		mov	ah, 0fh
		int	10h
		mov	bl, bh
		push	bx
	;
	; Make page 0 the active one
	; 
		mov	ax, 0500h
		int	10h
	;
	; Select 50 lines
	; 
		mov	ax, 1202h	; 400 scan lines
		mov	bl, 30h
		int	10h
	;
	; Perform a mode set without changing display mode
	; 
		mov	ah, 0fh
		int	10h		; al <- current mode
		mov	ah, 0		; set mode
		int	10h
	;
	; Load 8x8 font in block 0
	; 
		mov	ax, 1112h
		mov	bl, 0
		int	10h
	;
	; Set bit 0 of 0:487h non-zero to enable cursor emulation
	; 
		mov	ax, SS_DOSMEM
		mov	fs, ax
		or	byte ptr fs:[487h], 1
	;
	; Set cursor position to a block from 0 to 6
	; 
		mov	cx, 0006h
		mov	ah, 1
		int	10h
	;
	; Reset bit 0 of 487h to disable cursor emulation.
	; 
		and	byte ptr fs:[487h], not 1
	;
	; Adjust the underline location.
	; 
		mov	dx, 3d4h
		mov	al, 14h
		out	dx, al
		inc	dx
		mov	al, 07h	; set underline to line 7
		out	dx, al
	;
	; Reset the active page to its previous value.
	; 
		pop	ax
		mov	ah, 5
		int	10h

		pop	ebx
		ret
DosModeSet50Line endp

_CODE	ends

end
