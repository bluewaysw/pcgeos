##############################################################################
#
#       Copyright (c) Geoworks 1992 -- All Rights Reserved
#
# PROJECT:     PC GEOS
# FILE:        dosreal.gp
#
# AUTHOR:      Todd Stumpf
#
#
#       $Id: dosreal.gp,v 1.1 97/04/18 11:44:07 newdeal Exp $
#       Bugfixed for 16 bit DMA by Disk Lausecker 00/05/07
#
##############################################################################
#
# Specify the geode's permanent name
#
name	dosrdma.lib
#
# Specify the type of geode (this is both a library, so other geodes can
# use the functions, and a driver, so it is allowed to access I/O ports).
# It may only be loaded once.
#
type driver, single

#
# Desktop-related things
#
longname        "DOS-Real mode DMA Driver"
tokenchars      "DMAD"
tokenid         0
#
resource ResidentCode 		fixed code

