/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	gInterC.h
 * AUTHOR:	Jenny Greenwood, September 3, 1993
 *
 * DECLARER:	UI
 *
 * DESCRIPTION:
 *	Constants and structures for GenInteractionClass
 *
 *	$Id: gInterC.h,v 1.1 97/04/04 15:52:34 newdeal Exp $
 *
 ***********************************************************************/

#ifndef __GINTERC_H
#define __GINTERC_H

/* Internal type. Do not use. */
typedef struct {
    ThreadHandle    	UDDS_callingThread;	
    SemaphoreHandle 	UDDS_semaphore;	
    word	    	UDDS_response;
    Boolean    	   	UDDS_complete;
    Boolean    	    	UDDS_boxRunByCurrentThread;
    optr    	    	UDDS_dialog;
    QueueHandle	    	UDDS_queue;
} UserDoDialogStruct;

typedef enum /* word */ {
    IC_NULL,
    IC_DISMISS,
    IC_INTERACTION_COMPLETE,
    IC_APPLY,
    IC_RESET,
    IC_OK,
    IC_YES,
    IC_NO,
    IC_STOP,
    IC_EXIT,
    IC_HELP,
    IC_INTERNAL_1,
    IC_INTENRAL_2,
/* @protominor UINewInteractionCommands */
    IC_NEXT,
    IC_PREVIOUS
/* @protoreset */
} InteractionCommand;

#define IC_CUSTOM_START 1000

typedef ByteEnum GenInteractionType;
#define GIT_ORGANIZATIONAL 0
#define GIT_PROPERTIES 1
#define GIT_PROGRESS 2
#define GIT_COMMAND 3
#define GIT_NOTIFICATION 4
#define GIT_AFFIRMATION 5
#define GIT_MULTIPLE_RESPONSE 6

typedef ByteEnum GenInteractionVisibility;
#define GIV_NO_PREFERENCE 0
#define GIV_POPUP 1
#define GIV_SUB_GROUP 2
#define GIV_CONTROL_GROUP 3
#define GIV_DIALOG 4
#define GIV_POPOUT 5

typedef ByteFlags GenInteractionAttrs;
#define GIA_NOT_USER_INITIATABLE		0x80
#define GIA_INITIATED_VIA_USER_DO_DIALOG	0x40
#define GIA_MODAL				0x20
#define GIA_SYS_MODAL				0x10

typedef ByteEnum GenInteractionGroupType;
#define GIGT_FILE_MENU 0
#define GIGT_EDIT_MENU 1
#define GIGT_VIEW_MENU 2
#define GIGT_OPTIONS_MENU 3
#define GIGT_WINDOW_MENU 4
#define GIGT_HELP_MENU 5
#define GIGT_PRINT_GROUP 6

#endif
