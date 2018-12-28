INFFAST.obj \
INFFAST.eobj: zutil.h zlib.h zconf.h geos.h file.h ec.h resource.h \
                Ansi/string.h Ansi/stdlib.h inftrees.h infblock.h \
                infcodes.h infutil.h inffast.h
CRC32.obj \
CRC32.eobj: zlib.h zconf.h geos.h file.h ec.h
INFLATE.obj \
INFLATE.eobj: zutil.h zlib.h zconf.h geos.h file.h ec.h resource.h \
                Ansi/string.h Ansi/stdlib.h infblock.h inftrees.h \
                infcodes.h infutil.h
INFTREES.obj \
INFTREES.eobj: zutil.h zlib.h zconf.h geos.h file.h ec.h resource.h \
                Ansi/string.h Ansi/stdlib.h inftrees.h inffixed.h
INFBLOCK.obj \
INFBLOCK.eobj: zutil.h zlib.h zconf.h geos.h file.h ec.h resource.h \
                Ansi/string.h Ansi/stdlib.h infblock.h inftrees.h \
                infcodes.h infutil.h
INFCODES.obj \
INFCODES.eobj: zutil.h zlib.h zconf.h geos.h file.h ec.h resource.h \
                Ansi/string.h Ansi/stdlib.h inftrees.h infblock.h \
                infcodes.h infutil.h inffast.h
ZUTIL.obj \
ZUTIL.eobj: zutil.h zlib.h zconf.h geos.h file.h ec.h resource.h \
                Ansi/string.h Ansi/stdlib.h timer.h
INFUTIL.obj \
INFUTIL.eobj: zutil.h zlib.h zconf.h geos.h file.h ec.h resource.h \
                Ansi/string.h Ansi/stdlib.h infblock.h inftrees.h \
                infcodes.h infutil.h
GZIO.obj \
GZIO.eobj: Ansi/stdio.h geos.h zutil.h zlib.h zconf.h file.h ec.h \
                resource.h Ansi/string.h Ansi/stdlib.h
UNCOMPR.obj \
UNCOMPR.eobj: zlib.h zconf.h geos.h file.h ec.h
ADLER32.obj \
ADLER32.eobj: zlib.h zconf.h geos.h file.h ec.h
TREES.obj \
TREES.eobj: deflate.h zutil.h zlib.h zconf.h geos.h file.h ec.h \
                resource.h Ansi/string.h Ansi/stdlib.h trees.h
DEFLATE.obj \
DEFLATE.eobj: deflate.h zutil.h zlib.h zconf.h geos.h file.h ec.h \
                resource.h Ansi/string.h Ansi/stdlib.h
COMPRESS.obj \
COMPRESS.eobj: zlib.h zconf.h geos.h file.h ec.h

zlibEC.geo zlib.geo : geos.ldf ansic.ldf 