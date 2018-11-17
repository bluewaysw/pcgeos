########################################################################
#
#      Copyright (c) Gerd Boerrigter 1997 -- All Rights Reserved
#
# PROJECT:      FROTZ for GEOS - an interpreter for all Infocom games.
# MODULE:
# FILE:         frotz.gp
#
# AUTHOR:       Gerd Boerrigter
#
# RCS STAMP:
#   $Id: FROTZ.GP,v 1.2 1997/07/14 12:47:05 gerdb Exp $
#
# DESCRIPTION:
#   Geode definitions for the Frotz interpreter.
#
# REVISION HISTORY:
#   Date      Name      Description
#   --------  --------  -----------
#   97-02-19  GerdB     Initial Version.
#
########################################################################

name frotz.app
longname "GeoFrotz"
tokenchars "FROZ"
#tokenid 16460
tokenid 16431

type    appl, process, single

class   FrotzProcessClass
appobj  FrotzApp

stack 4000

heapspace 12k

library geos
library ui
library ansic
library text

#ifdef PRODUCT_NOKIA9000
#  platform N9000V20
#  library foam
#else
  platform GEOS201
#endif

resource APPLICATIONRESOURCE            ui-object
resource INTERFACERESOURCE              ui-object
resource MENURESOURCE                   ui-object
# resource DOCUMENTUI                     object

resource MONIKERRESOURCE  data object
resource STRINGRESOURCE  data object
resource LOGORESOURCE  data object

#export FrotzViewClass
export FrotzInputTextClass
export FrotzOutputTextClass

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

