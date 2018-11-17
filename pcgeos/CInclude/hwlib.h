#ifndef __HWLIB_H__
#define __HWLIB_H__

#ifdef DO_HW_CHECKSUM_CHECKING
extern void _cdecl HWChecksumCheck(void) ;
extern void _cdecl HWLowMemCheckOn(void) ;
extern void _cdecl HWLowMemCheckOff(void) ;
#else
#define HWChecksumCheck()
#define HWLowMemCheckOn()
#define HWLowMemCheckOff()
#endif

#endif
