/***************************************************************************

                Copyright (c) Breadbox Computer Company 1998
                         -- All Rights Reserved --

  PROJECT:      Generic Database System
  MODULE:       Standard Field Types
  FILE:         bdbTypes.h

  AUTHOR:       Gerd Boerrigter

  $Header: /Home Bulletin Board/Includes/BDBTYPES.H 7     7/21/97 18:25 Gerdb $

  DESCRIPTION:
    This file defines some common data types for the use in various
    databases.

***************************************************************************/

#ifndef __BDBTYPES_H
#define __BDBTYPES_H

/** This structure is used to set up an RTCM event, therefore it is in
    the correct format.
 */
typedef struct {
    FileDate            DRDAT_date;
    byte                DRDAT_hour;
    byte                DRDAT_minute;
} DBaseRtcmDateAndTime;

typedef WordFlags DBaseRecordFlags;
#define DRF_private     0x8000
// #define DRF_private     0x8000


/**
   Some standard field types which describe which data structure is
   stored in that field.
 */
typedef enum {
    /** The field countains some data of something else. */
    DST_UNKNOWN = 0,

    /** The field contains the date and time information for the RTCM
        of the type C<DBaseRtcmDateAndTime>. */
    DST_RTCM_DATE_AND_TIME,

    /** The field contains record infos (like user ID, private, ...). */
    DST_INFO,

    /** The field countains an array of TCHAR (=> string).  It is
    I<not> '\0' terminated. */
    DST_TEXT,

    /** The field contains C<TimerDateAndTime>. */
    DST_DATE_AND_TIME,

} DBaseStandardType;


/**
   Some standard field category types which describe what kind of
   information is stored in that field.
 */
typedef enum {
    /** The field countains some data of something else. */
    DSC_UNKNOWN = 0,

    /** */
    DSC_SUBJECT,

    /** */
    DSC_OWNER,

    /** */
    DSC_NOTES,

    /** The first value which can be used by an application/library. */
    DSC_FIRST_APPLICATION_CATEGORY = 0x8000

} DBaseStandardCategory;


#endif /* __BDBTYPES_H */