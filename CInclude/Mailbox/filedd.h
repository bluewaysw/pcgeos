/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	  Clavin
 * MODULE:	  File Data Driver
 * FILE:	  filedd.h
 *
 * AUTHOR:  	  Chung Liu: Nov 21, 1994
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	CL	11/21/94   	Initial version
 *
 * DESCRIPTION:
 *	Interface for File Data Driver
 *
 *
 * 	$Id: filedd.h,v 1.1 97/04/04 15:55:44 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _FILEDD_H_
#define _FILEDD_H_

typedef struct {
    DiskHandle FAR_diskHandle;
 /* label char *FAR_filename */
} FileDDAppRef;

typedef struct {
    DiskHandle FMAR_diskHandle;
    PathName   FMAR_filename;
} FileDDMaxAppRef;

#endif /* _FILEDD_H_ */
