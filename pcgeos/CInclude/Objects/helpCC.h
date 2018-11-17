/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1993 -- All Rights Reserved
 *
 * PROJECT:	  GEOS
 * FILE:	  helpCC.h
 *
 * AUTHOR:  	  Jenny Greenwood, Sept 3, 1993
 *
 * REVISION HISTORY:
 *	Name	  Date	    Description
 *	----	  ----	    -----------
 *	jenny     9/03/93   Initial version (broke out of helpCC.goh)
 *
 * DESCRIPTION:
 *	
 *      Constants and structures for the help library.
 *
 * 	$Id: helpCC.h,v 1.1 97/04/04 15:52:26 newdeal Exp $
 *
 ***********************************************************************/

#ifndef __HELPCC_H
#define __HELPCC_H

#include <file.h>

/******************************************************************************
 *	HelpControlClass
 *****************************************************************************/

/*
 * Constants and structures
 */

typedef ByteEnum HelpType;
#define HT_NORMAL_HELP 0
#define HT_FIRST_AID 1
#define HT_STATUS_HELP 2
#define HT_SIMPLE_HELP 3
#define HT_SYSTEM_HELP 4
#define HT_SYSTEM_MODAL_HELP 5

typedef WordFlags HPCFeatures;
#define HPCF_HELP   	  	0x0100
#define HPCF_TEXT   	    	0x0080
#define HPCF_CONTENTS	    	0x0040
#define HPCF_HISTORY	    	0x0020
#define HPCF_GO_BACK	    	0x0010
#define HPCF_CLOSE	    	0x0008
#define HPCF_INSTRUCTIONS   	0x0004
#define HPCF_FIRST_AID_GO_BACK	0x0002
#define HPCF_FIRST_AID	    	0x0001

#define MAX_CONTEXT_NAME_SIZE	20
#define CONTEXT_NAME_BUFFER_SIZE 22
/* allow for NULL, word-align */

typedef char ContextName[CONTEXT_NAME_BUFFER_SIZE];

typedef struct {
    HelpType	    NHCC_type;
    ContextName	    NHCC_context;
    FileLongName    NHCC_filename;
    FileLongName    NHCC_filenameTOC;
} NotifyHelpContextChange;

#endif

