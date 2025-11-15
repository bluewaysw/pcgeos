##############################################################################
#
# PROJECT:      Startbar Utilities Module
# FILE:         sbarutil.gp
#
# AUTHOR:       Lysle Shields
#
##############################################################################

name            SBarUtil.lib
longname        "Startbar Utilities Module"
tokenchars      "SBrU"
tokenid         16431

type            library, single

library         geos
library         ui
library         ansic

platform        geos201

export          StartbarIconInteractionClass
export          StartbarRightClickMenuClass
export          StartbarHighlightBoxClass
export          StartbarUtilLoadApplication


# usernotes "Copyright 1994-2002  Breadbox Computer Company LLC  All Rights Reserved"