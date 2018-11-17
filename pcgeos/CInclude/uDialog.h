/***********************************************************************
 *
 *	Copyright (c) Berkeley Softworks 1991 -- All Rights Reserved
 *
 * PROJECT:	PC GEOS
 * FILE:	file.h
 * AUTHOR:	Tony Requist: February 12, 1991
 *
 * DECLARER:	Kernel
 *
 * DESCRIPTION:
 *	This file defines file structures and routines.
 *
 *	$Id: uDialog.h,v 1.1 97/04/04 15:58:29 newdeal Exp $
 *
 ***********************************************************************/

#ifndef	__UDIALOG_H
#define __UDIALOG_H

#include <Objects/gInterC.h>

typedef ByteEnum CustomDialogType;
#define CDT_QUESTION 0
#define CDT_WARNING 1
#define CDT_NOTIFICATION 2
#define CDT_ERROR 3

/* Bitfield CustomDialogBoxFlags */

typedef WordFlags CustomDialogBoxFlags;
#define CDBF_SYSTEM_MODAL	0x8000
#define CDBF_DIALOG_TYPE	0x6000
#define CDBF_INTERACTION_TYPE	0x1e00
#define CDBF_DESTRUCTIVE_ACTION 0x0100
#define CDBF_DIALOG_TYPE_OFFSET		13
#define CDBF_INTERACTION_TYPE_OFFSET	9

typedef struct {
    optr                SDRTE_moniker;
    InteractionCommand  SDRTE_responseValue;
} StandardDialogResponseTriggerEntry;

/*
 * a structure of this type must be defined and passed to UserStandardDialog
 * and UserStandardDialogOptr if GIT_MULTIPLE_RESPONSE is used.
 *
 * Define as many SDRTT_triggers entries as you have SDRTT_numTriggers.  For
 * 1, 2, 3, or 4 response trigger cases, use these:
 */
typedef struct {
    word				SD1RTT_numTriggers;
    StandardDialogResponseTriggerEntry	SD1RTT_trigger1;
} StandardDialog1ResponseTriggerTable;

typedef struct {
    word				SD2RTT_numTriggers;
    StandardDialogResponseTriggerEntry	SD2RTT_trigger1;
    StandardDialogResponseTriggerEntry	SD2RTT_trigger2;
} StandardDialog2ResponseTriggerTable;

typedef struct {
    word				SD3RTT_numTriggers;
    StandardDialogResponseTriggerEntry	SD3RTT_trigger1;
    StandardDialogResponseTriggerEntry	SD3RTT_trigger2;
    StandardDialogResponseTriggerEntry	SD3RTT_trigger3;
} StandardDialog3ResponseTriggerTable;

typedef struct {
    word				SD4RTT_numTriggers;
    StandardDialogResponseTriggerEntry	SD4RTT_trigger1;
    StandardDialogResponseTriggerEntry	SD4RTT_trigger2;
    StandardDialogResponseTriggerEntry	SD4RTT_trigger3;
    StandardDialogResponseTriggerEntry	SD4RTT_trigger4;
} StandardDialog4ResponseTriggerTable;

/* parameters for MSG_GEN_APPLICATION_BUILD_DIALOG */

typedef struct {
    CustomDialogBoxFlags	SDOP_customFlags;
    optr 			SDOP_customString;
    optr 			SDOP_stringArg1;
    optr 			SDOP_stringArg2;
    optr 			SDOP_customTriggers;
    optr    			SDOP_helpContext;
} StandardDialogOptrParams;

extern word /*XXX*/
    _pascal UserDoDialog(optr dialogBox);

extern optr /*XXX*/
    _pascal UserCreateDialog(optr dialogBox);

extern void /*XXX*/
    _pascal UserDestroyDialog(optr dialogBox);

extern word   /*XXX*/
    _pascal UserStandardDialog(char *helpContext,
			       char *customTriggers,
			       char *arg2,
			       char *arg1,
			       char *string,
			       CustomDialogBoxFlags dialogFlags);

extern word
    _pascal UserStandardDialogOptr(char *helpContext,
				   void *customTriggers,
				   optr arg2,
				   optr arg1,
				   optr string,
				   CustomDialogBoxFlags dialogFlags);

#ifdef __HIGHC__
pragma Alias(UserDoDialog, "USERDODIALOG");
pragma Alias(UserStandardDialog, "USERSTANDARDDIALOG");
pragma Alias(UserStandardDialogOptr, "USERSTANDARDDIALOGOPTR");
pragma Alias(UserCreateDialog, "USERCREATEDIALOG");
pragma Alias(UserDestroyDialog, "USERDESTROYDIALOG");
#endif

#endif
