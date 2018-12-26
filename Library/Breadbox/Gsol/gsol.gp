##############################################################################
#
# PROJECT:      GSOL
# FILE:         gsol.gp
#
# AUTHOR:       Marcus Gr”ber
#
##############################################################################

name            gsol.lib
longname        "GString Owner Link library"
tokenchars      "GSOL"
tokenid         16424

type            library, single

platform        geos20

library         geos
library         ansic

export          GSOLMARKGSTRINGSTART
export          GSOLMARKGSTRINGEND
export          GSOLCHECKGSTRING
export          GSOLIDENTIFYGSTRING

resource ASM_FIXED code read-only shared fixed

