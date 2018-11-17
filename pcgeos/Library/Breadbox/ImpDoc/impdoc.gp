##############################################################################
#
# PROJECT:      browser
# FILE:         impdoc.gp
#
# AUTHOR:       Brian Chin
#
##############################################################################
name impdoc.lib

longname "Breadbox Doc Import Library"

type library, single, c-api
entry LIBRARYENTRY

tokenchars "MIMD"
tokenid 16431

library geos
library ansic
library ui

#
# standard MIMD entry points
#
export MIMEDRVNOTHING
export MIMEDRVINFO
export MIMEDRVMAIN

usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

