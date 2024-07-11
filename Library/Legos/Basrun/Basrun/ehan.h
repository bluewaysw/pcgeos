/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1996 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Runtime
FILE:		ehan.h

AUTHOR:		dubois, Jan  9, 1996

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dubois	1/ 9/96  	Initial version.

DESCRIPTION:
	Interface to ehan.c

	$Id: ehan.h,v 1.1 98/10/05 12:54:11 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _EHAN_H_
#define _EHAN_H_

#ifdef LIBERTY
#include <Legos/runint.h>
#else
#include "runint.h"
#endif

extern const byte EH_DataSizes[];

#define FSF_CURRENT_FRAME	0x1
#define FSF_ENABLED_INACTIVE	0x2
typedef WordFlags FindStateFlags;
EHState*	EHFindState(RMLPtr rms, FindStateFlags flags);

FrameContext	EHCleanStack(RMLPtr rms);
Boolean		EHResume(RMLPtr rms);
Boolean		EHHandleError(RMLPtr rms);
void		EHContactDebugger(RMLPtr rms);

#endif /* _EHAN_H_ */
