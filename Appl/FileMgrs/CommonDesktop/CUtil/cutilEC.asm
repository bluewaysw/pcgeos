COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cutilEC.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 9/92   	Initial version.

DESCRIPTION:
	

	$Id: cutilEC.asm,v 1.1 97/04/04 15:02:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UtilCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckFileOperationInfoEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that ds:si points to a valid
		FileOperationInfoEntry 

CALLED BY:	INTERNAL

PASS:		ds:si - FileOperationInfoEntry

RETURN:		nothing 

DESTROYED:	nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckFileOperationInfoEntry	proc far
	uses	es,di,cx,ax
	.enter
	pushf


	;
	; Make sure the name is properly null-terminated
	;
	mov	cx, size FileLongName
	clr	al
	segmov	es, ds
	lea	di, ds:[si].FOIE_name
	repne	scasb
	ERROR_NE	INVALID_FILE_OPERATION_INFO_ENTRY

	cmp	ds:[si].FOIE_type, GeosFileType
	ERROR_AE	INVALID_FILE_OPERATION_INFO_ENTRY

	test	ds:[si].FOIE_flags, not GeosFileHeaderFlags
	ERROR_NZ	INVALID_FILE_OPERATION_INFO_ENTRY

	popf
	.leave
	ret
ECCheckFileOperationInfoEntry	endp

UtilCode	ends
