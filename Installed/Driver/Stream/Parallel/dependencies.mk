# DO NOT DELETE THIS LINE
parallelInit.eobj \
parallelInit.obj: Internal/dos.def Internal/interrup.def\
                  Internal/parallDr.def Internal/semInt.def\
                  Internal/strDrInt.def Internal/streamDr.def driver.def\
                  ec.def file.def fileEnum.def geode.def geos.def heap.def\
                  initfile.def lmem.def localize.def parallel.def\
                  parallelInit.asm resource.def sllang.def sysstats.def\
                  system.def timedate.def timer.def
parallelInt.eobj \
parallelInt.obj : Internal/diskInt.def Internal/dos.def\
                  Internal/dosFSDr.def Internal/driveInt.def\
                  Internal/fileInt.def Internal/fsDriver.def\
                  Internal/fsd.def Internal/interrup.def\
                  Internal/parallDr.def Internal/semInt.def\
                  Internal/strDrInt.def Internal/streamDr.def disk.def\
                  drive.def driver.def ec.def file.def fileEnum.def\
                  geode.def geos.def heap.def lmem.def localize.def\
                  parallel.def parallelInt.asm resource.def sllang.def\
                  sysstats.def system.def thread.def timer.def
parallelMain.eobj \
parallelMain.obj: Internal/dos.def Internal/interrup.def\
                  Internal/parallDr.def Internal/powerDr.def\
                  Internal/semInt.def Internal/strDrInt.def\
                  Internal/streamDr.def driver.def ec.def file.def\
                  fileEnum.def geode.def geos.def heap.def lmem.def\
                  localize.def parallel.def parallelMain.asm resource.def\
                  sllang.def sysstats.def system.def timer.def
parallelec.geo parallel.geo: geos.ldf stream.ldf
