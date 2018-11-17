COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		spooltdMisc.asm

AUTHOR:		Adam de Boor, Oct 27, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/27/94		Initial revision


DESCRIPTION:
	Things I couldn't think of any other place to put...
		

	$Id: spooltdMisc.asm,v 1.1 97/04/18 11:40:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MiscCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDChooseFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select in which format we want the body of the message to
		be created

CALLED BY:	(GLOBAL) DR_MBTD_CHOOSE_FORMAT
PASS:		cx:dx	= array of MailboxDataFormat tokens
		bx	= number of formats from which to choose
RETURN:		ax	= 0-origin index of acceptable format, or -1 if none
			  is acceptable
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDChooseFormat proc	far
		uses	ds, si, cx, dx
		.enter
		movdw	dssi, cxdx
	;
	; We prefer a stream gstring that we can pass directly to the spooler
	; 
		mov	dx, GMDFID_STREAM_GSTRING
		call	STDTryFormat
		jnc	done
	;
	; Failing that, look for formats we can convert to a gstring ourselves
	; 
		mov	dx, GMDFID_TEXT_CHAIN
		call	STDTryFormat
		jnc	done
		
		mov	dx, GMDFID_INK
		call	STDTryFormat
		jnc	done
	;
	; No format acceptable.
	; 
		mov	ax, -1
done:
		.leave
		ret
SpoolTDChooseFormat endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STDTryFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look through the array for a format we like

CALLED BY:	(INTERNAL) SpoolTDChooseFormat
PASS:		ds:si	= format array
		bx	= # entries in it
		dx	= geoworks-defined format for which we're searching
RETURN:		carry set if not found
			ax	= destroyed
		carry clear if found:
			ax	= 0-origin index
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
STDTryFormat	proc	near
		uses	si, di
		.enter
		mov	cx, bx
		jcxz	notFound
formatLoop:
		lodsw			; ax <- MDF_id
		cmp	ax, dx
		lodsw			; ax <- MDF_manuf, in case match
		jne	nextFormat
			CheckHack <MANUFACTURER_ID_GEOWORKS eq 0>
		tst	ax
nextFormat:
		loopne	formatLoop	; loop if either word mismatched
		jne	notFound	; => ran out of formats
	;
	; Convert to a 0-origin index. Sample case:
	; 	bx	= 2
	; matched the first item in the array, so cx = 1 (decremented by loop)
	; 1 - 2 = -1, NOT(-1) = 0, which is what we want
	; 
		sub	cx, bx
		not	cx
	;
	; Return the index in AX with carry clear.
	; 
		mov_tr	ax, cx
		clc
done:
		.leave
		ret
notFound:
		stc
		jmp	done
STDTryFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolTDGetFormats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the formats we support.

CALLED BY:	DR_MBTD_ESC_GET_FORMATS
PASS:		cx:dx	= buffer in which to place formats
		ax	= number of MailboxDataFormat descriptors that will
			  fit
RETURN:		carry clear
		ax	= number of MailboxDataFormats we support
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/17/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpoolTDGetFormats proc	far
		uses	ds, si, cx, es, di
		.enter
		movdw	esdi, cxdx
	;
	; Figure how many entries to copy
	;
		mov	cx, length spooltdFormats
		cmp	cx, ax
		jbe	doCopy
		mov_tr	cx, ax
doCopy:
	;
	; Copy the durn things
	;
		mov	si, offset spooltdFormats
		segmov	ds, cs
			CheckHack <size MailboxDataFormat eq 4>
		shl	cx
		rep	movsw
	;
	; Return the number of formats we support (may be more than we
	; copied in...
	;
		mov	ax, length spooltdFormats
		clc
		.leave
		ret
SpoolTDGetFormats endp

spooltdFormats	MailboxDataFormat <
	GMDFID_STREAM_GSTRING, MANUFACTURER_ID_GEOWORKS
>, <
   	GMDFID_TEXT_CHAIN, MANUFACTURER_ID_GEOWORKS
>, <
	GMDFID_INK, MANUFACTURER_ID_GEOWORKS
>
MiscCode	ends
