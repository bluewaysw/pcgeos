##############################################################################
#
#       Copyright (c) Jens-Michael Gross 1997 -- All Rights Reserved
#
# PROJECT:     MM-Projekt
# FILE:        cdados.gp
#              CDrom driver for (MS)CDEX supported CD drives
#
# AUTHOR:      Jens-Michael Gross
#
#
##############################################################################
#
# Specify the geode's permanent name
#
name	cdados.drvr

#
# Specify the type of geode (this is both a library, so other geodes can
# use the functions, and a driver, so it is allowed to access I/O ports).
# It may only be loaded once.
#
type driver, single

#
# Desktop-related things
#
longname        "Breadbox DOS CD Audio Driver"
tokenchars      "CDAD"
tokenid         16474

#
resource ResidentCode 		fixed code


usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"

