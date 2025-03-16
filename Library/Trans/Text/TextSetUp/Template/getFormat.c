/*********************************************************************/
/*                                                                   */
/*      Copyright (c) GeoWorks 1992 -- All Rights Reserved           */
/*                                                                   */
/*      PROJECT:        PC GEOS                                      */
/*      MODULE:		Template Translation Library		     */
/*      FILE:           getFormat.c                                  */
/*                                                                   */
/*      AUTHOR:         Jenny Greenwood, 20 September 1992           */
/*                                                                   */
/*      REVISION HISTORY:                                            */
/*                                                                   */
/*      Name    Date            Description                          */
/*      ----    ----            -----------                          */
/*      jenny   9/20/92         Initial version                      */
/*                                                                   */
/*      DESCRIPTION:                                                 */
/*                                                                   */
/*      $Id: getFormat.c,v 1.1 97/04/07 11:40:29 newdeal Exp $
/*                                                                   */
/*********************************************************************/

#pragma Code ("ImportMainC")

#include <geos.h>
#include <Internal/xlatLib.h>
#include <libFormat.h>

/* GeoComment: TemplateGetFormat requires that at least ??? bytes
               of the file have been read into the buffer.

	       The original MasterSoft version of this routine, found in
	       /s/p/Library/Translation/Text/Original/Autorec/autorec.c,
	       is called ???. */

TemplateGetFormat (char * bufr)
{
return ( NO_IDEA_FORMAT );
}
