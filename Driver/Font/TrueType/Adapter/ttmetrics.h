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
 *	Declarations of driver function DR_FONT_CHAR_METRICS.
 ***********************************************************************/

#ifndef _TTMETRICS_H_
#define _TTMETRICS_H_


TT_Error _pascal TrueType_Char_Metrics( 
                                   word                 character, 
                                   GCM_info             info, 
                                   const FontInfo*      fontInfo,
	                           const OutlineEntry*  outlineEntry,  
                                   TextStyle            stylesToImplement,
                                   WWFixedAsDWord       pointSize,
                                   dword*               result );

#endif /* _TTMETRICS_H_ */
