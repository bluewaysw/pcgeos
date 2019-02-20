/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  Swat -- Breakpoint declarations
 * FILE:	  break.h
 *
 * AUTHOR:  	  Adam de Boor: Mar 23, 1989
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	3/23/89	  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Declarations of functions and types for the Break module.
 *
 *
* 	$Id: break.h,v 4.2 96/05/20 18:43:42 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _BREAK_H
#define _BREAK_H

typedef	Boolean	    BreakHandler(Break brkpt, Opaque data);

extern void 	Break_Init (void);
extern Break 	Break_Set (Patient patient, Handle handle, Address offset,
			   BreakHandler *func, Opaque data);
extern Break 	Break_TSet (Patient patient, Handle handle, Address offset,
			    BreakHandler *func, Opaque data);
extern void 	Break_Clear (Break brkpt);
extern void 	Break_Enable (Break brkpt);
extern void 	Break_Disable (Break brkpt);
extern Address 	Break_Address (Break brkpt);
#endif /* _BREAK_H */
                      
