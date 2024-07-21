vmfiManager.obj \
vmfiManager.eobj: geos.def geode.def resource.def ec.def assert.def disk.def \
                file.def drive.def driver.def lmem.def heap.def char.def \
                Internal/heapInt.def Internal/semInt.def sysstats.def \
                vm.def chunkarr.def localize.def sllang.def \
                Internal/fidoiDr.def vmfi.def vmfiStrategy.asm \
                vmfiMain.asm

vmfiEC.geo vmfi.geo : geos.ldf 