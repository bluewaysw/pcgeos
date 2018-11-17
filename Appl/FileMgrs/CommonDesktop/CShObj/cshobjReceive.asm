COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cshobjReceive.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/26/93   	Initial version.

DESCRIPTION:
	

	$Id: cshobjReceive.asm,v 1.2 98/06/03 13:46:30 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectCheckTransferEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	See if this object can receive transfers.

PASS:		*ds:si	- ShellObjectClass object
		ds:di	- ShellObjectClass instance data
		es	- dgroup
		dx:bp	- FileOperationInfoEntry 

RETURN:		carry clear if OK, carry SET otherwise

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellObjectCheckTransferEntry	method	dynamic	ShellObjectClass, 
					MSG_SHELL_OBJECT_CHECK_TRANSFER_ENTRY

	.enter

	mov	es, dx

	test	ds:[di].SOI_attrs, mask SOA_RECEIVES_TRANSFERS
	jz	rejectWholeBlock

	mov	ax, ATTR_SHELL_OBJECT_RESTRICT_TRANSFERS
	call	ObjVarFindData
	jnc	afterRestrict

	call	CheckInfoEntryInVarData
	jc	rejectEntry

afterRestrict:

	mov	ax, ATTR_SHELL_OBJECT_ACCEPT_TRANSFERS
	call	ObjVarFindData
	jnc	done

	call	CheckInfoEntryInVarData
	jnc	rejectEntry

	clc
done:
	.leave
	ret



rejectWholeBlock:
	; reject all items in this FQT block.  Only beeps once
	cmp	cx, es:[FQTH_numFiles]
	jne	rejectSilently

rejectEntry:
	mov	ax, ERROR_REJECT_ENTRY
	call	DesktopOKError

rejectSilently:
	stc	
	jmp	done




ShellObjectCheckTransferEntry	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckInfoEntryInVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the NewDeskObjectType of the current
		FileOperationInfoEntry is in the vardata pointed to by
		ds:bx 

CALLED BY:	ShellObjectCheckTransferEntry

PASS:		ds:bx - vardata entry
		es:bp - FileOperationInfoEntry

RETURN:		carry SET if found, clear otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	1/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckInfoEntryInVarData	proc near
	uses	cx
	.enter

	mov	ax, es:[bp].FOIE_info	; fetch the info entry's type

	VarDataSizePtr	ds, bx, cx	; fetch the # entries in the list
	shr	cx

startLoop:
	cmp	ax, ds:[bx]
	stc
	je	done
	loop	startLoop
	clc
done:
	.leave
	ret
CheckInfoEntryInVarData	endp

