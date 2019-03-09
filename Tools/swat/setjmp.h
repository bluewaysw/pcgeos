/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- inter-system compatibility
 * FILE:	  setjmp.h
 *
 * AUTHOR:  	  Adam de Boor: Mar  1, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/ 1/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	This is the ISI declaration of a jmp_buf because it's the bigger
 *	of the two (ISI and SUN).
 *
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _SETJMP_H_
#define _SETJMP_H_

#endif /* _SETJMP_H_ */

/*	setjmp.h	4.1	83/05/03	*/

typedef int jmp_buf[10+12];
