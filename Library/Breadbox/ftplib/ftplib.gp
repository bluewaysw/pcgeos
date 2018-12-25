############################################################################
#
#               Copyright (c) Breadbox Computer Company 1998
#                        -- All Rights Reserved --
#
# PROJECT:      FTP Client
# MODULE:       FTP Library
# FILE:         ftplib.gp
#
# AUTHOR:       Gerd Boerrigter
#
# $Header: H:\\CVSROOT\\GEOS\\LIBRARY\\BREADBOX\\FTPLIB\\RCS\\ftplib.gp 1.2 1999/01/09 10:19:15 gerdb Exp $
#
# DESCRIPTION:
#   Geode definitions for the FTP library.
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   98-06-02  GerdB     Initial version.
#
############################################################################

name ftplib.lib
longname "Breadbox FTP Library"
tokenchars "FtpL"
tokenid 16431

#platform N9000C
platform geos20

type library, single, c-api

#
# Define library entry point
#
# entry

#
# Libraries: list which libraries are used by the geode.
#
library geos
library ui
library ansic

library socket
exempt  socket

#
# Resources
#
resource StatusStringResource           lmem discardable read-only shared

# Exported classes and routines
#
export FtpClass
# export FtpFileListClass

# export SENDSTATUSMESSAGE                    # SendStatusMessage

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

