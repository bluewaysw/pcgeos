/***********************************************************************
 *
 *	Copyright (c) GeoWorks 1992 -- All Rights Reserved
 *
 * PROJECT:	  WIZARD/BA
 * FILE:	  iclas.h
 *
 * AUTHOR:  	  Chung Liu: Oct 26, 1992
 *
 * REVISION HISTORY:
 *	Name	Date		Description
 *	----	----		-----------
 *	CL	10/26/92   	Initial version
 *
 * DESCRIPTION:
 *	This file defines iclas related constants and structures for Wizard.
 *
 * 	$Id: iclas.h,v 1.1 97/04/04 15:57:37 newdeal Exp $
 *
 ***********************************************************************/
#ifndef _ICLAS_H_
#define _ICLAS_H_

#define USER_FULL_NAME_LENGTH    38
#define USER_ID_LENGTH           10
#define USER_PADDED_ID_LENGTH    12
#define USER_OTHER_INFO_LENGTH   3
#define CLASS_ID_LENGTH          8

typedef struct {
    char teacherID[USER_ID_LENGTH];
    char classID[CLASS_ID_LENGTH];
    char studentID[USER_ID_LENGTH];
    char firstName[USER_ID_LENGTH];
    char lastName[USER_ID_LENGTH];
    char day;
    char month;
    char minute;
    char hour;
    word crlf;
} AutoLoginLine;

typedef struct {
    char msgFlag;
    char maxStations;
} WorkstationFile;

#define WORKSTATION_FILE_NAME "Z:\\LOGIN\\AUTOLOG2\\SYSDEFLT.CLS"
#define DEFAULT_MAX_STATIONS 50

typedef ByteEnum UserType;
#define UT_GENERIC 'G'
#define UT_STUDENT 'S'
#define UT_ADMIN   'A'
#define UT_TEACHER 'T'
#define UT_OFFICE  'O'

extern Boolean
    _pascal IclasLoginUser();
extern void
    _pascal IclasInitOtherVariables();
extern void
    _pascal IclasInitUserVariables();
extern Boolean
    _pascal IclasSetupUserHome();
extern void
    _pascal IclasEnterUserHome();
extern void
    _pascal IclasLeaveUserHome();
extern void
    _pascal IclasRemapDOSDrive();
extern Boolean
    _pascal IclasGetUserVolumeName(char *id, char *buf, word bufLen);
extern void
    _pascal IclasSetSearchDriveCount(word count);

extern void
    _pascal IclasRecursiveDelete();

#ifdef __HIGHC__
pragma Alias(IclasLoginUser, "ICLASLOGINUSER");
pragma Alias(IclasInitOtherVariables, "ICLASINITOTHERVARIABLES");
pragma Alias(IclasInitUserVariables, "ICLASINITUSERVARIABLES");
pragma Alias(IclasSetupUserHome, "ICLASSETUPUSERHOME");
pragma Alias(IclasEnterUserHome, "ICLASENTERUSERHOME");
pragma Alias(IclasLeaveUserHome, "ICLASLEAVEUSERHOME");
pragma Alias(IclasGetUserVolumeName, "ICLASGETUSERVOLUMENAME");
pragma Alias(IclasRemapDOSDrive, "ICLASREMAPDOSDRIVE");
pragma Alias(IclasSetSearchDriveCount, "ICLASSETSEARCHDRIVECOUNT");
pragma Alias(IclasRecursiveDelete, "ICLASRECURSIVEDELETE");
#endif

#endif /* _ICLAS_H_ */
