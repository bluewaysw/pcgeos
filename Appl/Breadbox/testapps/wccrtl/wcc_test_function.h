/*
 * Copyright 2020   Jirka Kunze
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * 
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

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
Boolean test_scenario__U4D(unsigned long dividend, unsigned long divisor, unsigned long expectedQutient, unsigned long expectedRemainder);
Boolean test_scenario__I4D(long dividend, long divisor, long expectedQutient, long expectedRemainder);
Boolean test_scenario__CHP(long double number, long exceptedValue);

#endif
