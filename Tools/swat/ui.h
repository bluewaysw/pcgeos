/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1988 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  SWAT -- User Interface
 * FILE:	  ui.h
 *
 * AUTHOR:  	  Adam de Boor: Nov  8, 1988
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	11/ 8/88  ardeb	    Initial version
 *
 * DESCRIPTION:
 *	Definitions for the user-interface of SWAT.
 *
* 	$Id: ui.h,v 4.5 96/05/20 18:54:41 dbaumann Exp $
 *
 ***********************************************************************/
#ifndef _UI_H_
#define _UI_H_

extern void	Ui_Init (int *argcPtr, char **argv);
extern Boolean	Ui_CheckInterrupt (void);
extern void	Ui_ClearInterrupt (void);
extern void	Ui_TakeInterrupt (void);
extern void 	Ui_AllowInterrupts(Boolean);
extern Boolean	Ui_Interrupt (void);
extern volatile void	Ui_TopLevel (void);

#endif /* _UI_H_ */
