###########################################################################
#
#   Copyright (C) 1999  Breadbox Computer Company
#                       All Right Reserved
#
#   PROJECT:    Automatic Decoder Library
#   FILE:       ADL.gp
#   AUTHOR:     FR, 26th April, 1999
#
#   DESCRIPTION:
#       This is the Automatic Decoder Library linker file.
#
###########################################################################

name inetmsg.lib

longname "Breadbox Internet Msg Library"

###########################################################################

tokenchars "INML"
tokenid 16431

###########################################################################

type library, single, c-api

###########################################################################

library geos
library ui
library ansic
library extui

###########################################################################

resource StringResource data read-only shared discardable
resource MessageComposerUI ui-object read-only shared

###########################################################################

export ADCREATE             # ADCreate
export ADPUTLINE            # ADPutLine
export ADGETVAR             # ADGetVar
export ADDESTROY            # ADDestroy

export MessageComposerClass

export AELPROCESSDATA       # AELProcessData
export AELCREATESESSION     # AELCreateSession
export AELDESTROYSESSION    # AELDestroySession
export AELRECYCLEDATABLOCKS # AELRecycleDataBlocks


###########################################################################

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

###########################################################################
