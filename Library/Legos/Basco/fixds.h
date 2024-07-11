/*%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1995 -- All Rights Reserved

PROJECT:	LEGOS
MODULE:		Basrun
FILE:		fixds.h

AUTHOR:		Roy Goldman, Jul  9, 1995

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roy	 7/ 9/95	Initial version.

DESCRIPTION:
	Header for routines used to make sure ds is ok around calls.

	$Id: fixds.h,v 1.1 98/10/13 21:42:53 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FIXDS_H_
#define _FIXDS_H_

extern word setDSToDgroup(void);
extern void restoreDS(word oldDS);

#endif /* _FIXDS_H_ */
