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


TT_Error _pascal Get_Char_Metrics( const FontInfo*  fontInfo, 
                                   GStateHandle     gstate, 
                                   word             character, 
                                   GCM_info         info, 
                                   dword*           result );

#endif _TTMETRICS_H_