/***********************************************************************
 *
 *	Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttadapter.h
 *
 * AUTHOR:	  Jirka Kunze: July 5 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	05.07.22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Declaration of global objects which are defined in assembler 
 *      and are also needed in c functions.
 ***********************************************************************/
#ifndef _TTADAPTER_H_
#define _TTADAPTER_H_

#include <geos.h>
#include "../FreeType/freetype.h"

/***********************************************************************
 *      global dgoup objects
 ***********************************************************************/
extern GTT_Engine tt_Engine;


#endif /* _TTADAPTER_H_ */
