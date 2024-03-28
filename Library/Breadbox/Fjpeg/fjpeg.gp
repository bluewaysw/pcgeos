##############################################################################
#
# PROJECT:      FJPEG
# FILE:         FJPEG.gp
#
# AUTHOR:       Jens-Michael Gross
#
##############################################################################

name            fjpeg.lib
longname        "Fast JPEG Decomp Lib"
tokenchars      "FJPG"
tokenid         16474

type            library, single, c-api

library	geos
library ui
library ansic

entry FJPEGENTRY

# the following export matching the above one but are suffixed by fjpeg
# to allow the usage of IJGJPEG and FJPEG at the same time (used for
# progressive and multiscan jpg)
# I know its not a good way to do it, but the only working one without
# creating another library. 10/06/2000 FR

export FJPEG_CREATE_DECOMPRESS
export FJPEG_STDIO_SRC
export FJPEG_READ_HEADER
export FJPEG_START_DECOMPRESS
export FJPEG_READ_SCANLINES
export FJPEG_DESTROY_DECOMPRESS
export FJPEG_SMALLOCARR
export FJPEG_SMFREE

incminor

export FJPEG_INIT_LOADPROGRESS

# end of renameing functions here


usernotes "Copyright 2000 NewDeal Inc. All Rights Reserved."

