/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  goc
 * FILE:	  map.c
 *
 * AUTHOR:  	  Gene Anderson : Apr 17, 1990
 *
 * ROUTINES:
 *	Name	  	    Description
 *	----	  	    -----------
 *	CheckShortcut	    See if string represents valid shortcut.
 *
 *	CheckAlpha  	    Check if alpha class shortcut (eg. a-z)
 *	CheckMiscKey   	    Check if miscellaneous shortcut (eg. tab, f1..f10)
 *	CheckNavigation	    Check if navigation key shortcut (eg. home, end)
 *	CheckDigit	    Check if digit class shortcut (eg. 0-9, !@#)
 *
 *	shortcuts   	    table of ShortcutEntry[] of shortcuts.
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	4/17/90	  eca	    Initial version
 *
 * DESCRIPTION:
 *	Contains shortcut map and routines for checking it.
 *
 ***********************************************************************/
#ifndef lint
static char *rcsid =
"$Id: map.c,v 1.2 93/01/14 02:11:26 josh Exp $";
#endif lint

#include "map.h"
#include "goc.h"
#define	M_NONE	    	    0x0
#define	M_SHIFT_CTRL	    M_SHIFT | M_CTRL
#define	M_SHIFT_ALT 	    M_SHIFT | M_ALT
#define	M_CTRL_ALT  	    M_CTRL | M_ALT
#define	M_SHIFT_CTRL_ALT    M_SHIFT | M_CTRL | M_ALT

/*
 * Miscellaneous shortcut constants:
 */

#define	CS_BSW	    	0x0000
#define CS_CTRL	    	0x0f00

#define	KSS_PHYSICAL	0x8000
#define KSS_SHIFT   	0x1000
#define KSS_CTRL   	0x2000
#define KSS_ALT   	0x4000

int CheckAlpha(int mods, int value, int specificUI, char **error);
int CheckMiscKey(int mods, int value, int specificUI, char **error);
int CheckNavigation(int mods, int value, int specificUI, char **error);
int CheckDigit(int mods, int value, int specificUI, char **error);
int CheckPunct(int mods, int value, int specificUI, char **error);


/***********************************************************************
 *				CheckShortcut
 ***********************************************************************
 * SYNOPSIS:	See if string represents valid shortcut name and
 *	    	if modifiers are valid.
 * CALLED BY:	
 * PASS:	name: shortcut string
 *	    	mods: modifiers used (M_SHIFT, M_CTRL, M_ALT)
 * RETURN:	value of keyboard shortcut (0 if invalid)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	gene	4/17/90		Initial Revision
 *
 ***********************************************************************/

int
CheckShortcut(
    int mods,		/* M_ bits */
    int type,		/* KEY_ */
    int value,		/* ASCII value */
    int specificUI,	/* Allow specific UI */
    char **error	/* error string (return value) */
    )
{

    switch (type) {
	case KEY_ALPHA:
	    return( CheckAlpha(mods, value, specificUI, error));
	case KEY_MISC:
	    return( CheckMiscKey(mods, value, specificUI, error));
	case KEY_NAVIGATION:
	    return( CheckNavigation(mods, value, specificUI, error));
	case KEY_DIGIT:
	    return( CheckDigit(mods, value, specificUI, error));
	case KEY_PUNCT:
	    return( CheckPunct(mods, value, specificUI, error));
	default:
	    break;
    }
    return 0;
}


/***********************************************************************
 *				CheckAlpha
 ***********************************************************************
 * SYNOPSIS:	See if valid alpha-based shortcut (eg. a-z)
 * CALLED BY:	CheckShortcut()
 * PASS:    	mods: modifiers used (M_SHIFT, M_CTRL, M_ALT)
 *	    	value: character value
 * RETURN:	shortcut value (0 if invalid shortcut)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	gene	4/17/90		Initial Revision
 *
 ***********************************************************************/

int
CheckAlpha(int mods, int value, int specificUI, char **error)
{
    switch (mods) {
	case M_NONE:
	    if (specificUI) {
		return(value | CS_BSW | KSS_PHYSICAL);
	    } else {
		*error = "<alpha> cannot be used as an accelerator";
		return(0);
	    }
	case M_SHIFT:
	    *error = "<shift><alpha> cannot be used as an accelerator";
	    return(0);
	case M_CTRL_ALT:
	    *error = "<ctrl><alt><alpha> reserved for foreign keyboards";
	    return(0);
	case M_SHIFT_CTRL_ALT:
	    *error = "<shift><ctrl><alt><alpha> reserved for foreign keyboards";
	    return(0);

	case M_SHIFT_CTRL:
	    return( (value - 'a' + 'A') | CS_BSW | KSS_PHYSICAL | KSS_CTRL);
	case M_CTRL:
	    return(value | CS_BSW | KSS_PHYSICAL | KSS_CTRL);
	case M_ALT:
	    return(value | CS_BSW | KSS_PHYSICAL | KSS_ALT);
	case M_SHIFT_ALT:
	    return(value | CS_BSW | KSS_PHYSICAL | KSS_SHIFT | KSS_ALT);
	default:
	    break;
    }
    return 0;
}


/***********************************************************************
 *				CheckMiscKey
 ***********************************************************************
 * SYNOPSIS:	See if miscellaneous key shortcut (eg. TAB, F1-F10)
 * CALLED BY:	CheckShortcut()
 * PASS:    	mods: modifiers used (M_SHIFT, M_CTRL, M_ALT)
 *	    	value: character value
 * RETURN:	shortcut value (0 if invalid shortcut)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	gene	4/17/90		Initial Revision
 *
 ***********************************************************************/

int
CheckMiscKey(int mods, int value, int specificUI, char **error)
{
    if (specificUI) {
	return(value | CS_CTRL | (mods << 12));
    } else {
	*error = "function keys and misc reserved for the specific UI";
	return(0);
    }
}


/***********************************************************************
 *				CheckPunct
 ***********************************************************************
 * SYNOPSIS:	See if punctuation key shortcut (eg. '(', '%')
 * CALLED BY:	CheckShortcut()
 * PASS:    	mods: modifiers used (M_SHIFT, M_CTRL, M_ALT)
 *	    	value: character value
 * RETURN:	shortcut value (0 if invalid shortcut)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	gene	4/17/90		Initial Revision
 *
 ***********************************************************************/

int
CheckPunct(int mods, int value, int specificUI, char **error)
{
    if (specificUI) {
	return(value | CS_BSW | KSS_PHYSICAL | (mods << 12));
    } else {
	*error = "punctuation reserved for the specific UI";
	return(0);
    }
}


/***********************************************************************
 *				CheckNavigation
 ***********************************************************************
 * SYNOPSIS:	See if navigation key shortcut (eg. home, end, arrows)
 * CALLED BY:	CheckShortcut()
 * PASS:    	mods: modifiers used (M_SHIFT, M_CTRL, M_ALT)
 *	    	value: character value
 * RETURN:	shortcut value (0 if invalid shortcut)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	gene	4/17/90		Initial Revision
 *
 ***********************************************************************/

int
CheckNavigation(int mods, int value, int specificUI, char **error)
{
    if (specificUI) {
    	return(value | CS_CTRL | (mods << 12) | KSS_PHYSICAL);
    } else {
	*error = "navigation keys reserved for the specific UI";
	return(0);
    }
}


/***********************************************************************
 *				CheckDigit
 ***********************************************************************
 * SYNOPSIS:	See if digit based shortcut (eg. 0-9, !@#$)
 * CALLED BY:	CheckShortcut()
 * PASS:    	mods: modifiers used (M_SHIFT, M_CTRL, M_ALT)
 *	    	value: character value
 * RETURN:	shortcut value (0 if invalid shortcut)
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	gene	4/17/90		Initial Revision
 *
 ***********************************************************************/
int
CheckDigit(int mods, int value, int specificUI, char **error)
{
    switch (mods) {
	case M_NONE:
	    if (!specificUI) {
		*error = "<digit> cannot be used as an accelerator";
		return(0);
	    } else {
		return(value | CS_BSW | KSS_PHYSICAL);
	    }
	case M_SHIFT:
	    *error = "<shift><digit> cannot be used as an accelerator";
	    return(0);
	case M_CTRL_ALT:
	    *error = "<ctrl><alt><digit> reserved for foreign keyboards";
	    return(0);
	case M_SHIFT_CTRL_ALT:
	    *error =
		"<shift><ctrl><alt><digit> reserved for foreign keyboards";
	    return(0);
	case M_SHIFT_CTRL:
	    *error = "<shift><ctrl><digit> cannot be used as an accelerator";
	    return(0);
	case M_SHIFT_ALT:
	    *error = "<shift><alt><digit> cannot be used as an accelerator";
	    return(0);

	case M_CTRL:
	case M_ALT:
	    return(value | CS_BSW | KSS_PHYSICAL | (mods << 12));
	default:
	    break;
    }
    return 0;
}
