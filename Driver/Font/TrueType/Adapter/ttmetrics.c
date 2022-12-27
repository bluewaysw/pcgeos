/***********************************************************************
 *
 *                      Copyright FreeGEOS-Project
 *
 * PROJECT:	  FreeGEOS
 * MODULE:	  TrueType font driver
 * FILE:	  ttadapter.c
 *
 * AUTHOR:	  Jirka Kunze: December 23 2022
 *
 * REVISION HISTORY:
 *	Date	  Name	    Description
 *	----	  ----	    -----------
 *	12/23/22  JK	    Initial version
 *
 * DESCRIPTION:
 *	Definition of driver function DR_FONT_CHAR_METRICS.
 ***********************************************************************/

#include "ttadapter.h"
#include "ttmetrics.h"

/********************************************************************
 *                      TrueType_Char_Metrics
 ********************************************************************
 * SYNOPSIS:	  Returns the metics of the given char.
 * 
 * PARAMETERS:    fontInfo              Pointer to FontInfo structure.
 *                gstate                Handle to current gstate.
 *                character             Character from which the metrics 
 *                                      are requested.
 *                info                  Information to return.
 *                result                Pointer in wich the result will 
 *                                      stored. The result is not affected
 *                                      by scaling, rotation, etc.
 * 
 * RETURNS:       TT_Error = FreeType errorcode (see tterrid.h)
 * 
 * SIDE EFFECTS:  none
 * 
 * CONDITION:     The current directory must be the ttf font directory.
 * 
 * STRATEGY:      - find font-file for the requested style from fontInfo
 *                - open outline of character in founded font-file
 *                - calculate requested metrics and return it
 * 
 * TODO:          If we want to support fake styles, this must also 
 *                be implemented here.
 * 
 * REVISION HISTORY:
 *      Date      Name      Description
 *      ----      ----      -----------
 *      23/12/22  JK        Initial Revision
 * 
 *******************************************************************/
TT_Error _pascal TrueType_Char_Metrics( 
                                   word             character, 
	                           const FontInfo*  fontInfo, 
                                   void*            gstatePtr, 
                                   GCM_info         info, 
                                   dword*           result ) 
{
        /* Api-Funktion für DR_FONT_GET_METRICS                                              */
        /* Transformationen werden nicht beachtet!!!                                         */
        /* The information is in document coordinates, which is to say it is not affected by */
        /* scaling, rotation, etc. that modifies the way the document is viewed, but simply  */
        /* by the pointsize and font attributes requested.                                   */
        /* siehe GrCharMetrics()                                                             */
        return TT_Err_Ok;
}