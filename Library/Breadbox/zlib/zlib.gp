##############################################################################
#
# PROJECT:      zlib
# FILE:         zlib.gp
#
# AUTHOR:       Marcus Gr”ber
#
##############################################################################

name            zlib.lib
longname        "zlib compression library"
tokenchars      "zlib"
tokenid         16424

type            library, single

platform        geos20

library         geos
library         ansic

export          ADLER32
export          COMPRESS
export          CRC32
export          DEFLATE
export          DEFLATECOPY
export          DEFLATEEND
export          DEFLATEINIT2_
export          DEFLATEINIT_
export          DEFLATEPARAMS
export          DEFLATERESET
export          DEFLATESETDICTIONARY
export          GZCLOSE
export          GZDOPEN
export          GZERROR
export          GZFLUSH
export          GZOPEN
export          GZREAD
export          GZWRITE
export          INFLATE
export          INFLATEEND
export          INFLATEINIT2_
export          INFLATEINIT_
export          INFLATERESET
export          INFLATESETDICTIONARY
export          INFLATESYNC
export          UNCOMPRESS
export          ZLIBVERSION
export          gzprintf
export          GZPUTC
export          GZGETC
export          GZSEEK
export          GZREWIND
export          GZTELL
export          GZEOF
export          GZSETPARAMS
export          ZERROR
export          INFLATESYNCPOINT
export          GET_CRC_TABLE
export          COMPRESS2
export          GZPUTS
export          GZGETS
