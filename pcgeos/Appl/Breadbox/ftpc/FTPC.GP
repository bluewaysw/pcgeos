##########################################################################
#
#              Copyright (c) Breadbox Computer Company 1998
#                       -- All Rights Reserved --
#
# PROJECT:      FTP Client
# MODULE:       FTP Application
# FILE:         ftpC.gp
#
# AUTHOR:       Gerd Boerrigter
#
# $Header: H:\\CVSROOT\\GEOS\\APPL\\BREADBOX\\FTPC\\RCS\\ftpc.gp 1.1 1998/12/11 16:53:16 gerdb Exp $
#
# DESCRIPTION:
#   Geode definitions for the FTP application.
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   98-08-26  GerdB     Initial version.
#
##########################################################################

name ftpc.app
longname "File Transfer"
tokenchars "ftpC"
tokenid 16431

platform geos201

stack   7000

type    appl, process
#, single
# originally wanted this app to multi-launchable, but must use single
# until global variables are used up.

class   FtpProcessClass
appobj  FtpApp

#
# Libraries: list which libraries are used by the geode.
#
library geos
library ui
library ansic

library extui
exempt  extui

library ftplib
exempt  ftplib

library flllib
exempt flllib

library sitelist
exempt sitelist

library parentc
exempt parentc

#
# Resources
#
resource APPLICATIONRESOURCE            ui-object
resource INTERFACERESOURCE              ui-object
resource MENURESOURCE                   ui-object
resource DIALOGRESOURCE                 ui-object
#resource COPYRIGHTOWNERMONIKERRESOURCE  ui-object
resource STATUSSTRINGRESOURCE           lmem discardable read-only shared

resource FTPTEMPLATERESOURCE            object shared read-only

ifdef TIMELOCK
resource TIMELOCKDIALOGRESOURCE         ui-object
endif

resource ERRORSTRINGRESOURCE            lmem discardable read-only shared

resource   EXPIREDIALOGRESOURCE ui-object

# Exported classes and routines

export FtpProcessClass
export FtpStatusTextClass
export FtpCancelButtonClass
export ExpireDialogClass
export FtpFileListClass
export GenTextLimitClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

