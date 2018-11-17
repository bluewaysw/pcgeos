##############################################################################
#
# PROJECT:      zlib
# FILE:         zlib.gp
#
# AUTHOR:       Marcus Gr”ber
#
##############################################################################

name            minizip.lib
longname        "zlib ZIP file support"
tokenchars      "mzip"
tokenid         16480

type            library, single

platform        geos20

library         geos
library         ansic
library 	ui

library         zlib
exempt          zlib

incminor
export          UNZINITUNZDESC
export          UNZDESTROYUNZDESC
export          UNZGETGLOBALINFO
export          UNZGETCURRENTFILEINFO
export          UNZGOTOFIRSTFILE
export          UNZGOTONEXTFILE
export          UNZOPENCURRENTFILE
export          UNZREADCURRENTFILE
export          UNZTELL
export          UNZEOF
export          UNZCLOSECURRENTFILE
export          UNZGETGLOBALCOMMENT
export          UNZSTRINGFILENAMECOMPARE
export          UNZLOCATEFILE
export          UNZGETLOCALEXTRAFIELD

export          UNZGETGOTOATINFO
export          UNZGOTOFILEAT

incminor
export          ZIPCREATENEWZIPDESC
export          ZIPOPENNEWFILEINZIP
export          ZIPWRITEINFILEINZIP
export          ZIPCLOSEFILEINZIP
export          ZIPCLOSEARCHIVE

export		ZIPOPENFILEFORZIP
export		ZIPGETFULLDOSPATH
export 		ZIPWRITEFILETOZIP
export          ZIPWRITEPATHTOZIP
export          ZIPGETZIPFILEINFO

export		ZIPFDATTODOSDATE
export		UNZDOSDATETOFDAT
export          UNZSETNEWFILEHANDLE

incminor
export 		ZIPCANCELCLOSEFILEINZIP

