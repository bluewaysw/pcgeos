modemCManager.obj \
modemCManager.eobj: geos.def ec.def driver.def lmem.def geode.def heap.def \
                library.def resource.def object.def system.def \
                localize.def sllang.def assert.def disk.def file.def \
                drive.def modemCConstant.def Internal/streamDr.def \
                Internal/modemDr.def Internal/strDrInt.def \
                Internal/semInt.def Internal/serialDr.def modemC.asm \
                modemCEci.asm

modemcEC.geo modemc.geo : geos.ldf 