########################################################################
#
#     Copyright (c) Dirk Lausecker 1997 -- All Rights Reserved
#
# PROJECT:      BestSound
# MODULE:       -
# FILE:         prefsndn.gp
#
# AUTHOR:       Dirk Lausecker
#
#
# DESCRIPTION:
#   Geode definitions for the PREFMIX-Library.
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   08.07.97  DL        Initial Version.
#   14.09.97  DL	new name (prefsndc)
#   21.10.98	DL	Mixermodul
#   21.08.2000	DL	Ableitung PREFSNDN fuer ND
#
########################################################################

name prefsndn.lib
longname "Sound Module"
tokenchars "PREF"
tokenid 0

type    library, single, c-api

#
# Libraries: list which libraries are used by the application.
#
library geos
library ui
library ansic
library config
library sound

#exempt ansic

#
# Resources
#
resource BASEINTERFACE          object read-only shared discardable
resource MONIKERRESOURCE        lmem read-only shared
resource REBOOTSTRINGRESOURCE	lmem read-only shared

#
# Routines
#
export  PREFGETOPTRBOX
export  PREFGETMODULEINFO

#
# Export classes
#       These are the classes exported by the library
#
export  PrefDialogMMClass
export	PrefItemGroupMMClass

usernotes "\xa9 1998-2000 Dirk Lausecker"

