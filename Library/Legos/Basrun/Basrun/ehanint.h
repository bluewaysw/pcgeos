/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Runtime
FILE:		ehanint.h

AUTHOR:		dubois, Jan  9, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	1/9/96  	Initial version.

DESCRIPTION:
	Internals for ehan.c

	$Id: ehanint.h,v 1.1 98/10/05 12:54:16 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _EHANINT_H_
#define _EHANINT_H_

#define PVF_NO_FRAME_CONTEXT	0x1
#define PVF_NO_ERROR_HANDLER	0x2
#define PVF_SIGNAL_FRAME_CONTEXT 0x4
typedef WordFlags PopValFlags;

Boolean	EH_PopVal(RMLPtr rms, PopValFlags flags);
Boolean	EH_UnrollFrame(RMLPtr rms);
word	EH_FindNextLine(RMLPtr rms);

#endif /* _EHANINT_H_ */
