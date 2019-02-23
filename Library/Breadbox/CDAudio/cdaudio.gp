########################################################################
#
#     Copyright (c) Jens-Michael Gross 1996-98 -- All Rights Reserved
#
# PROJECT:      Multimedia Extensions for GEOS
# MODULE:       CD audio access library
# FILE:         cdaudio.gp
#
# AUTHOR:       Jens-Michael Gross
#
# RCS STAMP:
#   $Id$
#
# DESCRIPTION:
#   Geode definitions for the CD audio access Library.
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   97-07-30  JMG       Initial Version.
#   98-11-28  JMG       final version for single application support,
#                       released with source code
#
########################################################################

name cdaudio.lib
longname "Breadbox CD Audio Library"
tokenchars "CDAL"
tokenid 16474

type    library, single, c-api

platform geos201

#
# Libraries: list which libraries are used by the application.
#

library geos
#library ui
library ansic
#library sound

#exempt ansic

#
# Export classes
#       These are the classes exported by the library
#



#
# Routines
#       These are the routines exported by the library
#
entry  LIBRARYENTRY
export CDLIB_RESET_VALID_FLAGS
export MSCDEX_GET_VERSION
export MSCDEX_GET_DRIVES
export MSCDEX_GET_DRIVE_LETTER
export CD_DRIVE_SET
export CD_DRIVE_RESET
export CD_DRIVE_GET_STATUS
export CD_DRIVE_GET_CHANGE
export CD_DRIVE_GET_VOLUME
export CD_DRIVE_SET_VOLUME
export CD_DRIVE_LOCK
export CD_DRIVE_DOOR
export CD_DRIVE_DOS_OPEN
export CD_DRIVE_DOS_CLOSE
export CD_GET_UPC
export CD_GET_LENGTH
export CD_GET_TRACKS
export CD_GET_TRACK_TYPE
export CD_GET_TRACK_START
export CD_GET_PLAY_POSITION
export CD_GET_PLAY_STATUS
export CD_PLAY_POSITION
export CD_PLAY_STOP
export CD_PLAY_RESUME

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

