COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Bitmap Library
FILE:		bitmapBackupProcess.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jon	12/91		Initial Version

DESCRIPTION:
	This file contains handlers for the undo process thread.

RCS STAMP:
$Id: backupProcess.asm,v 1.1 97/04/04 17:43:12 newdeal Exp $

------------------------------------------------------------------------------@

BitmapClassStructures	segment resource

	BitmapBackupProcessClass

BitmapClassStructures	ends


BitmapEditCode	segment	resource	;start of code resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			BackupGStringToBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Writes the last user edit from the temporary store space
		out into the main bitmap.

CALLED BY:	VisBitmapWriteChanges, VisBitmapStartSelect, etc.

PASS:		bp = gstate of bitmap to draw to
		cx = gstate of gstring to draw
		dx = memory handle of gstring *if* you want it freed,
		     0 otherwise
		
RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	2/91		initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BackupGStringToBitmap	method dynamic	BitmapBackupProcessClass, MSG_BACKUP_GSTRING_TO_BITMAP
	uses	dx, bp
	.enter
 	mov	di, bp				;di <- bitmap's gstate handle
	mov	si, cx				;si <- gstring's gstate handle
	push	dx				;save mem handle
	push	cx

	;
	;  Draw the damn thing
	;

	call	BitmapWriteGStringToBitmapCommon

	;
	;	Kill the gstring, as we no longer need it
	;
	pop	di
	mov	dl, GSKT_KILL_DATA
	call	GrDestroyGString

	;
	;	Free the block containing the gstring
	;
	pop	bx
	tst	bx
	jz	done
	call	MemFree
done:
	.leave
	ret
BackupGStringToBitmap	endm



BitmapEditCode	ends
