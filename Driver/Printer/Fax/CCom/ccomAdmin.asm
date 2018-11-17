COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:		Printer/Fax/CCom
FILE:		ccomAdmin.asm

AUTHOR:		Don Reeves, April 26, 1991

ROUTINES:
	Name		Description
	----		-----------
	PrintInit	initialize the driver, called once by OS at load time
	PrintExit	exit the driver
	PrintInitStream	initialize the stream, if necessary

REVISION HISTORY:
	Name	Date	Description
	----	----	-----------
	don	4/91	initial version

DESCRIPTION:
	This file contains routines to implement some of the administrative 
	parts of the driver.

	$Id: ccomAdmin.asm,v 1.1 97/04/18 11:52:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver

CALLED BY:	GLOBAL
		(PC GEOS kernel at load time)

PASS:		nothing

RETURN:		carry	- clear signalling successful init
			- set if the Complete Communicator is not loaded

DESTROYED:	ax,cx,dx,di

PSEUDO CODE/STRATEGY:
	Initialize driver local variable space;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 2/91		Initial version
	Don	4/91		Remove queue work

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;string sitting at a paragraph boundary that identifies the data area. First
;letter is actually an F, but we don't want to chance mistaking a disk buffer
;that contains this resource for the FAX data area....

searchLogo	char	'AAX ResidentCode'
STOP_SEGMENT	equ	0xf000	; search up to BIOS for the data...

PrintInit	proc	near
		uses	si, di, es, cx, ds
		.enter

		segmov	ds, cs
		assume	ds:Entry
		mov	ds:[searchLogo], 'F'	; correct search logo

		clr	ax			; start search from segment 0
searchLoop:
		lea	si, ds:[searchLogo]
		clr	di
		mov	es, ax
		mov	cx, length searchLogo / 2
		repe	cmpsw
		je	found
nextSegment:
		inc	ax
		cmp	ax, STOP_SEGMENT
		jne	searchLoop
	;
	; Data segment not found, so set the carry to signal error and bail
	;
		stc
done:
		.leave
		ret

found:
	;
	; Make sure we've not found ourselves (though that might be nice :)
	;
		mov	ds:[searchLogo], 'A'
		cmp	{char}es:[0], 'F'
		je	confirmed
		mov	ds:[searchLogo], 'F'
		jmp	nextSegment

confirmed:
	;
	; We've definitely found the CCom data area. Save the segment away.
	;
		segmov	ds, dgroup, cx
		mov	es, cx
		assume	ds:dgroup, es:dgroup
		mov	ds:[faxDataArea], ax
	;
	; Copy the bit-reversed local ID into the fax file header we use
	; for each page. Makes life much easier...
	;
		push	ds
		mov	ds, ax
		mov	di, offset faxFileHeader.FFH_localID
		mov	si, offset FRA_localID
		mov	cx, size FRA_localID
		rep	movsb
		pop	ds
	;
	; Signal our happiness.
	;
		clc
		jmp	done
PrintInit	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Exit the driver

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		carry	- clear

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Clean up anything before getting killed

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintExit	proc	near
		clc
		ret
PrintExit	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintInitStream
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do any stream-type, device specific initialization required

CALLED BY:	INTERNAL
		PrintSetStream

PASS:		ds	- points to locked PState
			- contains valid PS_streamType, PS_streamToken and
			  PS_streamStrategy

RETURN:		carry	- set if some transmission error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		some type of required init

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInitStream	proc	near
		clc			; no errors possible
		ret
PrintInitStream	endp
