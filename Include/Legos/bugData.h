/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	Legos
MODULE:		Compiler & Debugger (part in basrun)
FILE:		bugdata.h

AUTHOR:		Roy Goldman, Jul  9, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 9/95	Initial version.

DESCRIPTION:
	
        Annoying, but these data structures are shared by
	the debugger and the compiler. Since parts of the debugger
	are in basrun, export these structures here...
	Hohum

	$Id: bugData.h,v 1.1 97/12/05 12:16:12 gene Exp $
	$Revision: 1.1 $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _BUGDATA_H_
#define _BUGDATA_H_

typedef struct {
    word	LD_offset;
    word	LD_line;
} LineData;

typedef struct {
    dword       FLI_labelOffset;
    int         FLI_labelSize;
} FuncLabelInfo;

#endif /* _BUGDATA_H_ */
