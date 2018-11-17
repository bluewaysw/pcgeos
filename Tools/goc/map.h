/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  goc
 * FILE:	  map.h
 *
 * AUTHOR:  	  Gene Anderson: Apr 17, 1990
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/17/90	  gene	    Initial version
 *
 * 	$Id: map.h,v 1.2 90/06/08 17:35:43 adam Exp $
 *
 ***********************************************************************/
#ifndef _MAP_H_
#define _MAP_H_

/*
 * Shortcut key classes:
 */
#define	KEY_ALPHA   	1   	    /* eg. 'a'-'z' */
#define	KEY_MISC    	2   	    /* eg. tab, f1-f10 */
#define KEY_NAVIGATION	3   	    /* eg. home, end */
#define	KEY_DIGIT	4   	    /* eg. '0'-'9' */
#define KEY_PUNCT   	5   	    /* e.g. '(', '%' */

/*
 * Keyboard modifiers & combinations thereof:
 */

#define	M_SHIFT	    	    0x1
#define	M_CTRL	    	    0x2
#define	M_ALT	    	    0x4

/*
 * Routine to map a shortcut.  Returns 0 if error
 */

int CheckShortcut(
    int mods,		/* M_ bits */
    int type,		/* KEY_ */
    int value,		/* ASCII value */
    int specificUI,	/* Allow specific UI */
    char **error	/* Error string */
    );

#endif /* _MAP_H_ */
