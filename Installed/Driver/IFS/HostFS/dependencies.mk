hostfsManager.obj \
hostfsManager.eobj: hostfsGeode.def geos.def heap.def geode.def resource.def \
                ec.def lmem.def system.def localize.def sllang.def \
                drive.def disk.def file.def driver.def timedate.def \
                sem.def timer.def initfile.def gcnlist.def \
                Objects/metaC.def object.def chunkarr.def geoworks.def \
                graphics.def fontID.def font.def color.def \
                Internal/semInt.def Internal/interrup.def \
                Internal/fileInt.def fileEnum.def Internal/dos.def \
                Internal/driveInt.def Internal/diskInt.def \
                Internal/fsd.def Internal/heapInt.def sysstats.def \
                Internal/fsDriver.def hostfsConstant.def \
                hostfsVariable.def hostfsEntry.asm hostfsCall.asm \
                hostfsInit.asm hostfsDisk.asm hostfsPath.asm hostfsIO.asm

hostfsEC.geo hostfs.geo : geos.ldf 