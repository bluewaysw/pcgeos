eph_cmd.obj \
eph_cmd.eobj: config.h geos.h heap.h geode.h resource.h file.h object.h \
                lmem.h timer.h driver.h streamC.h serialDr.h parallDr.h \
                Ansi/stdio.h Ansi/stdlib.h Ansi/string.h eph_io.h \
                photopc.h eph_priv.h
eph_err.obj \
eph_err.eobj: config.h geos.h heap.h geode.h resource.h file.h object.h \
                lmem.h timer.h driver.h streamC.h serialDr.h parallDr.h \
                Ansi/stdio.h Ansi/stdlib.h Ansi/string.h eph_io.h \
                photopc.h eph_priv.h
eph_io.obj \
eph_io.eobj: config.h geos.h heap.h geode.h resource.h file.h object.h \
                lmem.h timer.h driver.h streamC.h serialDr.h parallDr.h \
                Ansi/stdio.h Ansi/stdlib.h Ansi/string.h eph_io.h \
                photopc.h eph_priv.h
eph_iob.obj \
eph_iob.eobj: config.h geos.h heap.h geode.h resource.h file.h object.h \
                lmem.h timer.h driver.h streamC.h serialDr.h parallDr.h \
                Ansi/stdio.h Ansi/stdlib.h Ansi/string.h eph_io.h \
                photopc.h
eph_open.obj \
eph_open.eobj: config.h geos.h heap.h geode.h resource.h file.h object.h \
                lmem.h timer.h driver.h streamC.h serialDr.h parallDr.h \
                Ansi/stdio.h Ansi/stdlib.h Ansi/string.h eph_io.h \
                photopc.h eph_priv.h
eph_read.obj \
eph_read.eobj: config.h geos.h heap.h geode.h resource.h file.h object.h \
                lmem.h timer.h driver.h streamC.h serialDr.h parallDr.h \
                Ansi/stdio.h Ansi/stdlib.h Ansi/string.h eph_io.h \
                photopc.h
photopc.obj \
photopc.eobj: config.h geos.h heap.h geode.h resource.h file.h object.h \
                lmem.h timer.h driver.h streamC.h serialDr.h parallDr.h \
                Ansi/stdio.h Ansi/stdlib.h Ansi/string.h eph_io.h \
                photopc.h

photopcEC.geo photopc.geo : geos.ldf streamc.ldf ansic.ldf 