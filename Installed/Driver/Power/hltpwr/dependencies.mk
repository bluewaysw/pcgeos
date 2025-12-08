hltpwr.obj \
hltpwr.eobj: geos.def heap.def lmem.def geode.def resource.def ec.def \
                Internal/heapInt.def Internal/semInt.def sysstats.def \
                powerGeode.def driver.def initfile.def timer.def \
                system.def localize.def sllang.def Internal/interrup.def \
                Internal/powerDr.def powerConstant.def powerVariable.def \
                powerCode.asm

hltpwrEC.geo hltpwr.geo : geos.ldf 