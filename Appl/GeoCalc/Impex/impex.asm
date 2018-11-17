
COMMENT @-----------------------------------------------------------------------

	Copyright (c) Geoworks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		impexMain.asm

AUTHOR:		Cheng, 10/92

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial revision

DESCRIPTION:
		
	$Id: impex.asm,v 1.1 97/04/04 15:49:04 newdeal Exp $

-------------------------------------------------------------------------------@

if 0
ImpexCode	segment	resource

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ImpexImportFromTransferItem

DESCRIPTION:	

CALLED BY:	INTERNAL ()

PASS:		ss:bp - ptr to ImpexTranslationParams

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/92		Initial version

-------------------------------------------------------------------------------@

ImpexImportFromTransferItem	method dynamic GeoCalcProcessClass, \
				MSG_GEOCALC_DOCUMENT_IMPORT_FROM_TRANSFER_ITEM
	.enter

PrintMessage <The import code here can't possibly work>

	test	ss:[bp].ITP_dataClass, mask IDC_SPREADSHEET
	je	done

	mov	ax, MSG_SSHEET_PASTE_FROM_DATA_FILE
	mov	cx, ss:[bp].ITP_transferVMFile
	mov	dx, ss:[bp].ITP_transferVMChain.high
	push	bp
	mov	bp, ss:[bp].ITP_transferVMChain.low
	call	CallTargetSpreadsheet
	pop	bp

	; Send notification back to ImportControl that we're done
done:
	call	ImpexImportExportCompleted

	.leave
	ret
ImpexImportFromTransferItem	endm


ImpexExportFromTransferItem	method dynamic GeoCalcProcessClass, \
				MSG_GEOCALC_DOCUMENT_EXPORT_FROM_TRANSFER_ITEM
	.enter

PrintMessage <The export code here can't possibly work>

	mov	ax, MSG_SSHEET_EXPORT_FROM_DATA_FILE
	mov	cx, ss:[bp].ITP_transferVMFile
	mov	dx, ss:[bp].ITP_transferVMChain.high
	push	bp
	mov	bp, ss:[bp].ITP_transferVMChain.low
	call	CallTargetSpreadsheet
	pop	bp

	; dx = transferHdrVMHan
	mov	ss:[bp].ITP_transferVMChain.high, dx
	clr	ss:[bp].ITP_transferVMChain.low

	mov	ss:[bp].ITP_clipboardFormat, CIF_SPREADSHEET
	mov	ss:[bp].ITP_manufacturerID, MANUFACTURER_ID_GEOWORKS

	;
	; Send notification back to ExportControl that we're done
	; pass ss:bp = ImpexTranslationParams
	;
	call	ImpexImportExportCompleted

	.leave
	ret
ImpexExportFromTransferItem	endm

ImpexCode	ends
endif
