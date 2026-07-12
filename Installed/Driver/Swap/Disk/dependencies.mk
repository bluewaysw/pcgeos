disk.obj \
disk.eobj: geos.def heap.def geode.def resource.def ec.def driver.def \
                lmem.def sem.def system.def localize.def sllang.def \
                file.def initfile.def drive.def disk.def \
                Internal/heapInt.def Internal/semInt.def sysstats.def \
                Internal/fsDriver.def Internal/fsd.def \
                Internal/driveInt.def Internal/diskInt.def \
                Internal/fileInt.def fileEnum.def Internal/dos.def \
                Internal/dosFSDr.def Internal/interrup.def \
                Internal/swapDr.def Internal/swap.def

diskEC.geo disk.geo : geos.ldf swap.ldf 