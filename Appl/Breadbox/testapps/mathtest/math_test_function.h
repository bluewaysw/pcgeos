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

#ifndef __MATH_TEST_FUNCTION_H
#define __MATH_TEST_FUNCTION_H

extern Boolean test_datatypesize();
extern Boolean test_function_push_pop();
extern Boolean test_function_compESDI();

Boolean test_function_float();
Boolean test_function_double();

#endif
