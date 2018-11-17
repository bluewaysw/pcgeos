
/***********************************************************************
 *
 *	Copyright (c) New Deal 1999 -- All Rights Reserved
 *
 * PROJECT:	NDO
 * FILE:	iapp.h
 * AUTHOR:	Gene Anderson: February 5, 1999
 *
 * DECLARER:	-
 *
 * DESCRIPTION:
 *      Definitions for IACP amongst Internet applications
 *
 *      $Id$
 *
 ***********************************************************************/

#ifndef __IAPP_H
#define __IAPP_H

/*
 * passed in ALB_extraData for MSG_META_IACP_NEW_CONNECTION
 */

typedef enum /* word */ {
    IADT_MAIL_TO,          /* e-mail address "address@newdealinc.com" */
    IADT_URL,              /* URL "http://www.newdealinc.com" */
    IADT_MAIL_ACCOUNT,     /* e-mail account */
    IADT_GET_NEW_MAIL      /* e-mail account */
} InternetAppDataType;

typedef struct {
    InternetAppDataType  IAB_type;
} InternetAppBlock;

#endif
