imps2.obj \
imps2.eobj: ../mouseCommon.asm geos.def heap.def lmem.def geode.def \
                resource.def ec.def assert.def disk.def file.def \
                drive.def driver.def initfile.def char.def timer.def \
                input.def graphics.def fontID.def font.def color.def \
                hwr.def timedate.def sem.def Internal/im.def \
                Internal/semInt.def Objects/processC.def \
                Objects/metaC.def object.def chunkarr.def geoworks.def \
                Internal/heapInt.def sysstats.def Internal/interrup.def \
                Internal/kbdMap.def Objects/uiInputC.def localize.def \
                sllang.def Internal/kbdDr.def Internal/mouseDr.def \
                Internal/dos.def fileEnum.def system.def

imps2EC.geo imps2.geo : geos.ldf 