#ifndef __REGIONT_H__
#define __REGIONT_H__


/* Define here the two diferent types we use in the code depending on if */
/* we use huge arrays or chunk arrays */
#if COMPILE_OPTION_HUGE_ARRAY_REGIONS
typedef dword T_regionArrayHandle ;
#define RAH_file(rah)  ((VMFileHandle)(((word *)&(rah))[1]))
#define RAH_block(rah)  ((VMBlockHandle)(((word *)&(rah))[0]))
#define RegionArrayConstruct(oself, pself)  \
            ConstructOptr(pself->VTI_vmFile, pself->VLTI_regionArray)
#define RegionArrayStartAccess(rah)  /* Do nothing */
#define RegionArrayEndAccess(rah)    /* Do nothing */
#define RegionLock(rah, index, pp_region, p_size)\
  HAL_EC(HugeArrayLock(RAH_file(rah), RAH_block(rah), index, ((void **)(pp_region)), (p_size)))
#define RegionDirty(p_region)  HugeArrayDirty(p_region)
#define RegionUnlock(p_region)  HugeArrayUnlock(p_region)
#define RegionArrayGetCount(rah)  HugeArrayGetCount(RAH_file(rah), RAH_block(rah))
#define RegionDelete(rah, index)  HugeArrayDelete(RAH_file(rah), RAH_block(rah), 1, index)
void IRegionPurgeCache(optr textObj) ;
#define RegionPurgeCache(obj)   IRegionPurgeCache(obj)
#define RegionNext(pp_region, p_size)   HugeArrayNext((pp_region), (p_size))
#else
typedef optr T_regionArrayHandle ;
#define RAH_mem(rah)    OptrToHandle(rah)
#define RAH_chunk(rah)  OptrToChunk(rah)
#define RegionPurgeCache(oself)   /* Do nothing */
#define RegionArrayConstruct(oself, pself)  ConstructOptr(OptrToHandle(oself), pself->VLTI_regionArray)
#define RegionArrayStartAccess(rah)  ObjLockObjBlock(RAH_mem(rah))
#define RegionArrayEndAccess(rah)    MemUnlock(RAH_mem(rah))
#define RegionLock(rah, index, pp_region, p_size)  \
            (*pp_region) = ChunkArrayElementToPtr(rah, index, (p_size))
#define RegionDirty(p_region)   /* Do nothing */
#define RegionUnlock(p_region)  /* Do nothing */
#define RegionArrayGetCount(rah)  ChunkArrayGetCount(rah)
#define RegionDelete(rah, index)  \
            ChunkArrayDelete(rah, ChunkArrayElementToPtr(rah, index, NULL))
#define RegionNext(pp_region, p_size)   ((*pp_region)++)
#endif

#endif /* __REGIONT_H__ */
