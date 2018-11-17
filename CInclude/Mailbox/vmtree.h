/***********************************************************************
 *
 *	Copyright (c) Geoworks 1994 -- All Rights Reserved
 *
 * PROJECT:	  Clavin 
 * MODULE:	  VM Tree Data Driver
 * FILE:	  vmtree.h
 *
 * AUTHOR:  	  Chung Liu: Nov 21, 1994
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	CL	11/21/94   	Initial version
 *
 * DESCRIPTION:
 *	Interface file for the VM Tree data driver.
 *
 *
 * 	$Id: vmtree.h,v 1.1 97/04/04 15:55:43 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _VMTREE_H_
#define _VMTREE_H_

typedef struct {
    VMChain       VMTAR_vmChain;
    VMFileHandle  VMTAR_vmFile;
} VMTreeAppRef;

#endif /* _VMTREE_H_ */
