/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:	  PC SDK
 * FILE:	  SDK.h
 *
 * AUTHOR:  	  Tom Lester: Aug  9, 1993
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	TL	8/ 9/93   	Initial version
 *
 * DESCRIPTION:
 *	
 *	Certain mechanisms within PC/GEOS utilize a two-word indentification
 *	scheme in which the first word is a ManufacturerID, & the second
 *	is an enumeration defined by the manufacturer identified by the
 *	first word.  This file contains the enumerations for the Geoworks
 *	Software Development Kit`s ManufacturerID of MANUFACTURER_ID_SDK.
 *	
 *	NOTE:  Any developer assigned a ManufacturerID should have a file
 *	       similar to this one, named after their own company, for the
 *	       purpose of defining the meaning of enumerations when that
 *	       ManufacturerID is used. Please contact GeoWorks ISV support
 *             to have a constant assigned for your company if you do not 
 *             already have one.
 *
 *	WARNING:
 *	       When updating this file, it is imperative that the assembly
 *	       equivalent, Include/SDK_C/SDK.def, be updated as well.
 *
 *	ONE MORE THING:
 *	       NOTHING should be placed in this file that can be made to
 *             reside in a more specialized include file.  Yes, that includes
 *	       Notification data block structures!  This is not a substitute
 *	       for a library-specific definition file;  Constants & structures
 *	       pertinent to a specific library belong in a specific include
 *	       file for that library.
 *
 * 	$Id: SDK.h,v 1.1 97/04/04 15:54:24 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _SDK_H_
#define _SDK_H_

#include <geode.h>       /* definition of MANUFACTURER_ID_SDK */

/* 
 * This is the base value for the GenApplication GCN list types.  
 * The base list type value must match the base message value of 
 * the GenApplication class.
 */
#define FIRST_GEN_APP_GCN_LIST_TYPE 0x6800

/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	MSG_META_NOTIFY & MSG_META_NOTIFY_WITH_DATA_BLOCK NotificationTypes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	MSG_META_NOTIFY & MSG_META_NOTIFY_WITH_DATA_BLOCK are general purpose
	notification messages, whose data format & meaning are defined by
	the "NotificationType" passed in the messages.

	This section contains the enumerations of the NT_type field of
	NotificationType for the case of NT_manuf = MANUFACTURER_ID_SDK.

	NOTE: needs to be word sized enums

	Name	Date		Description
	----	----		-----------
	TL	8/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */

typedef enum /* word */ {
    /* 
     * This notification type is used for the MSet library with the 
     * GAGCN list SDK_GAGCNLT_APP_TARGET_NOTIFY_MSET_ATTR_CHANGE.
     * The data block that is send along with this notification type 
     * with the message MSG_META_NOTIFY_WITH_DATA_BLOCK is a 
     * MSetParameters structure (defined in mset.goh).
     */
    SDK_NT_MSET_ATTR_CHANGE = 0x0000,

} SDKNotificationType;


/* %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	GenApplication GCNList enums
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	The UI library's GenApplicationClass supports its very own GCN
	(General Change Notification) system separate from the kernel's.
	Lists within this system are identified by a GCNListType, whose
	enumerations are seperate from that of the kernel's GCN system.

	This section contains the enumerations of the GCNLT_type field for
	GCNListType used within a GenApplication for the case of
	GCNLT_manuf = MANUFACTURER_ID_SDK.

	!!WARNING!!!!WARNING!!!!WARNING!!!!WARNING!!!!WARNING!!!!WARNING!!

	NOTE:	The GenApplication GCN list types must have values that 
	        are multiples of two (2) and the base value for the 
		list types must match the base message value of the 
		GenApplication class. So assign values to the list 
		types as shown below.

	!!WARNING!!!!WARNING!!!!WARNING!!!!WARNING!!!!WARNING!!!!WARNING!!

	NOTE:
	       When updating this file, it is imperative that the assembly
	       equivalent, Include/SDK_C/SDK.def, be updated as well.

	Name	Date		Description
	----	----		-----------
	TL	8/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% */

typedef enum /* word */ {
    /* 
     * List for keeping the MSet controllers up to date on the
     * status of the MSet object that is the current target.
     * The data block that is send to this list with the message
     * MSG_META_NOTIFY_WITH_DATA_BLOCK is a MSetParameters structure
     * (defined in mset.goh).
     */
    SDK_GAGCNLT_APP_TARGET_NOTIFY_MSET_ATTR_CHANGE 
         	                  = FIRST_GEN_APP_GCN_LIST_TYPE,
    /*
     * This is just a dummy list type to show how to number the lists.
     */
    SDK_GAGCNLT_DUMMY_LIST_TYPE 
	                          = FIRST_GEN_APP_GCN_LIST_TYPE + 2,

} SDKGenAppGCNListType;

#endif /* _SDK_H_ */


