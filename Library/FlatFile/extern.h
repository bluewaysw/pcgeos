/***********************************************************************
 *
 *	Copyright (c) Geoworks 1992 -- All Rights Reserved
 *
 * PROJECT:	  PCGEOS
 * MODULE:	  ffile.ldf
 * FILE:	  extern.h
 *
 * AUTHOR:  	  Anna Lijphart : Apr 20, 1992
 *
 * DESCRIPTION:
 *	This file holds declarations for externally declared routines
 * 	for ffile.
 *
 * RCS STAMP:
 *	$Id: extern.h,v 1.1 97/04/04 18:03:26 newdeal Exp $
 *
 ***********************************************************************/

extern Boolean CheckNumber(FieldDataType dataType, MemHandle textBlock, 
		    dword floatAddress);

extern Boolean CheckDateTime(FieldDataType dataType, MemHandle textBlock, 
	      dword floatAddress);

extern void DisplayUserError(optr errorMessageChunk);
