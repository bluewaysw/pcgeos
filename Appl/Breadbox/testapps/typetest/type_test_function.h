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

#ifndef __TYPE_TEST_FUNCTION_H
#define __TYPE_TEST_FUNCTION_H

#define ADD(a, b) ((a) + (b))
#define SUB(a, b) ((a) - (b))

extern Boolean test_datatype_float();
extern Boolean test_datatype_double();
extern Boolean test_datatype_longdouble();

void fill_float(float* toFill, float f);
void fill_double(double *toFill, double d);

#endif
