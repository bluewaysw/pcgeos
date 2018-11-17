/***********************************************************************
 *
 *	Copyright (c) Geoworks 1996 -- All Rights Reserved
 *
 * PROJECT:	  Tools
 * MODULE:	  glue
 * FILE:	  cv.h
 *
 * AUTHOR:  	  Tim Bradley: Jun 20, 1996
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TB	6/20/96   	Initial version
 *
 * DESCRIPTION:
 *	prototypes for codeview.c file
 *
 *
 * 	$Id$
 *
 ***********************************************************************/
#ifndef _CV_H_
#define _CV_H_

extern void CV_Init   (const char *file, FILE *f);
extern void CV_Finish (const char *file, Boolean happy, int pass);
extern int  CV_Check  (const char *file, byte rectype, word reclen, byte *bp,
                       int pass);
extern void CV32_Init   (const char *file, FILE *f);
extern void CV32_Finish (const char *file, Boolean happy, int pass);
extern int  CV32_Check  (const char *file, byte rectype, word reclen, byte *bp,
                      int pass);

#endif /* _CV_H_ */
