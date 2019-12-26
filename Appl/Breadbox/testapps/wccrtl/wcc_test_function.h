#include <geos.h>

#ifndef __WCC_TEST_FUNCTION_H
#define __WCC_TEST_FUNCTION_H

extern Boolean test_function__U4M();
extern Boolean test_function__I4M();
extern Boolean test_function__U4D();
extern Boolean test_function__I4D();
extern Boolean test_function__CHP();

Boolean test_scenario__U4M(unsigned long factor1, unsigned long factor2, unsigned long exceptedValue);
Boolean test_scenario__I4M(long factor1, long factor2, long exceptedValue);

#endif
