COMMENT @=====================================================================

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dirinfoEC.asm

AUTHOR:		Martin Turon, Nov 10, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/10/92	Initial version


DESCRIPTION:
	
		

RCS STAMP:
	$Id: dirinfoEC.asm,v 1.1 97/04/07 10:45:55 newdeal Exp $


=============================================================================@


COMMENT @-------------------------------------------------------------------
			ECCheckDirInfo
----------------------------------------------------------------------------

DESCRIPTION:	Checks a dirinfo chunk array for validity.

CALLED BY:	GLOBAL

PASS:		*ds:si	= dirinfo chunk array

RETURN:		if returns, all is well

DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/10/92	Initial version

---------------------------------------------------------------------------@

if ERROR_CHECK

ECCheckDirInfo	proc	far
		uses	ax, bx, di, es
		.enter
		pushf
	;
	; Perform basic chunk array checks
	;
		call	ECCheckChunkArray
		cmp	ds:[DIFH_protocol], DIRINFO_PROTOCOL_NUM
		ERROR_NE	OLD_DIRINFO_FILE
	;
	; Verify that dirinfo file is sorted
	;
		segmov	es, ds
		clr	ax
		call	ChunkArrayElementToPtr		
		jc	done
		lea	di, ds:[di].DIFE_fileID
continue:
		mov	bx, di
		inc	ax
		call	ChunkArrayElementToPtr		
		jc	done
		lea	di, ds:[di].DIFE_fileID
		push	si, bx
		mov	si, bx
		mov	bx, '_'		; bx=default char for DOS-to-GEOS conv.
SBCS <		call	LocalCmpStringsDosToGeos	;why DOS to GEOS cmp?>
DBCS <		call	LocalCmpStrings					>
		pop	si, bx
		jle	continue

				
;;;;		WARNING	DIRINFO_FILE_NOT_SORTED
		;
		; Debugging hints:
		; => pcarray -e
		;             prints out entire dirinfo file, 
		;
		; => pstring ds:di.DIFE_fileID
		;             prints file that was out of place

done:
		popf
		.leave
		ret
ECCheckDirInfo	endp

else	; if !ERROR_CHECK

;this is to keep glue happy

ECCheckDirInfo	proc	far
	ret
ECCheckDirInfo	endp

endif	; if ERROR_CHECK
