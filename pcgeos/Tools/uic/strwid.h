/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * FILE:	  strwid.h
 *
 * AUTHOR:  	  Tony Requist
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	1/15/93	  tony	    Initial version
 *
 * 	$Id: map.h,v 1.2 90/06/08 17:35:43 adam Exp $
 *
 ***********************************************************************/
#ifndef _STRWID_H_
#define _STRWID_H_

#define VMCW_HINTED		0x8000
#define VMCW_BERKELEY_9		0x7f00
#define VMCW_BERKELEY_10	0x00ff

#define VMCW_BERKELEY_9_OFFSET	8
#define VMCW_BERKELEY_10_OFFSET	0

#define MAX_WIDTH_9 	127
#define MAX_WIDTH_10	255

int CalcHintedWidth(char *string);

#endif /* _STRWID_H_ */
