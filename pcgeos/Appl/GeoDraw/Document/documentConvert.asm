COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Document
FILE:		documentConvert.asm

AUTHOR:		Jon Witort, September 2, 1992

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jon		2 sept 1992	initial revision

DESCRIPTION:
	$Id: documentConvert.asm,v 1.1 97/04/04 15:51:48 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UseLib Internal/convert.def

idata	segment

if not DBCS_PCGEOS
convertLibDir	char	CONVERT_LIB_DIR
convertLibPath	char	CONVERT_LIB_PATH
endif

idata	ends

DrawConvertFrom1XTo20Code	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDocumentUpdateEarlierIncompatibleDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	DrawDocument method for MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

Called by:	MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

Pass:		*ds:si = DrawDocument object
		ds:di = DrawDocument instance

Return:		carry set if error
		ax - non-zero to change protocol

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	?user	?date 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDocumentUpdateEarlierIncompatibleDocument method dynamic DrawDocumentClass,
			MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

	.enter

if DBCS_PCGEOS

	stc			;don't load library under DBCS
else

	;
	;  Load the conversion library
	;
	push	ds, si
	segmov	ds, ss
	mov	bx, CONVERT_LIB_DISK_HANDLE
	mov	dx, offset convertLibDir
	call	FileSetCurrentPath

	mov	si, offset convertLibPath
	mov	ax, CONVERT_PROTO_MAJOR
	mov	bx, CONVERT_PROTO_MINOR
	call	GeodeUseLibrary
	pop	ds, si
	jc	done

	push	bx					;save library handle

	;
	;  Call our conversion routine
	;
	mov	ax, enum ConvertDrawDocument
	call	ProcGetLibraryEntry
	mov	cx, offset DrawGrObjBodyObjTemp
	call	ProcCallFixedOrMovable
	pop	bx
	pushf
	call	GeodeFreeLibrary
	popf
	jc	done

	;
	;  Update various controllers regarding the current document
	;
	call	DrawDocumentSetGrObjBodyBounds
	call	DrawDocumentUpdatePageSizeControl

	mov	ax, TRUE
	clc
done:

endif
	.leave
	ret
DrawDocumentUpdateEarlierIncompatibleDocument	endm

DrawConvertFrom1XTo20Code	ends
