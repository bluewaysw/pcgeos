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

	$Revision: 1.1 $

	Liberty version control
	$Id: fixds.h,v 1.1 98/10/05 12:35:09 martin Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%*/
#ifndef _FIXDS_H_
#define _FIXDS_H_

#ifdef LIBERTY
#define DS_DECL
#define DS_DGROUP
#define DS_RESTORE

#define SET_DS_TO_DGROUP
#define RESTORE_DS
#else
extern word setDSToDgroup(void);
extern void restoreDS(word oldDS);

/* Version of SET_DS_TO_DGROUP that doesn't need to be in
 * declaration section. geez.
 */
#define DS_DECL word oldDS
#define DS_DGROUP oldDS = setDSToDgroup()
#define DS_RESTORE RESTORE_DS

#define SET_DS_TO_DGROUP word oldDS = setDSToDgroup()
#define RESTORE_DS restoreDS(oldDS)
#endif

#endif /* _FIXDS_H_ */
