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
 
#include "wcc_test_function.h"

Boolean test_function__U4M() {
    
    Boolean result = TRUE;

    //test with elements of the equivalence classes: 0, 1 and 4294967295
    result = result && test_scenario__U4M( (unsigned long) 0, (unsigned long) 0, (unsigned long) 0);
    result = result && test_scenario__U4M( (unsigned long) 1, (unsigned long) 0, (unsigned long) 0);
    result = result && test_scenario__U4M( (unsigned long) 1, (unsigned long) 1, (unsigned long) 1);
    result = result && test_scenario__U4M( (unsigned long) 4294967295, (unsigned long) 1, (unsigned long) 4294967295);
    
    //test with prime number that do not fit into a 16bit x86 register pair
    result = result && test_scenario__U4M( (unsigned long) 0, (unsigned long) 69997, (unsigned long) 0);
    result = result && test_scenario__U4M( (unsigned long) 1, (unsigned long) 69997, (unsigned long) 69997);
    result = result && test_scenario__U4M( (unsigned long) 41, (unsigned long) 69997, (unsigned long) 2869877);
    
    //test with factors whose product does not fit into a 32bit register set
    result = result && test_scenario__U4M( (unsigned long) 65536, (unsigned long) 65536, (unsigned long) 0);
    result = result && test_scenario__U4M( (unsigned long) 65537, (unsigned long) 65537, (unsigned long) 131073);
    
    return result;
}

Boolean test_function__I4M() {
    
    Boolean result = TRUE;
    
     //test with elements of the equivalence classes: -2147483648, -1, 0, 1 and 2147483647
    result = result && test_scenario__I4M( (long) 0, (long) 0, (long) 0);
    result = result && test_scenario__I4M( (long) 1, (long) 0, (long) 0);
    result = result && test_scenario__I4M( (long) 1, (long) 1, (long) 1);
    result = result && test_scenario__I4M( (long) -1, (long) 0, (long) 0);
    result = result && test_scenario__I4M( (long) -1, (long) -1, (long) 1);
    result = result && test_scenario__I4M( (long) -2147483648, (long) 0, (long) 0);
    result = result && test_scenario__I4M( (long) -2147483648, (long) 1, (long) -2147483648);
    result = result && test_scenario__I4M( (long) 2147483647, (long) 0, (long) 0);
    result = result && test_scenario__I4M( (long) 2147483647, (long) 1, (long) 2147483647);
    result = result && test_scenario__I4M( (long) 2147483647, (long) -1, (long) -2147483647);
    
    //test with prime number that do not fit into a 16bit x86 register
    result = result && test_scenario__I4M( (long) 0, (long) -69997, (long) 0);
    result = result && test_scenario__I4M( (long) 0, (long) 69997, (long) 0);
    result = result && test_scenario__I4M( (long) 1, (long) -69997, (long) -69997);
    result = result && test_scenario__I4M( (long) -1, (long) -69997, (long) 69997);
    result = result && test_scenario__I4M( (long) 41, (long) -69997, (long) -2869877);
    result = result && test_scenario__I4M( (long) -41, (long) -69997, (long) 2869877);
    
    //test with factors whose product does not fit into a 32bit register set
    result = result && test_scenario__I4M( (long) 65536, (long) 65536, (long) 0);
    result = result && test_scenario__I4M( (long) 65537, (long) 65537, (long) 131073);
    
    return result;
}

Boolean test_function__U4D() {

    Boolean result = TRUE;

    result = result && test_scenario__U4D( (unsigned long) 0, (unsigned long) 1, (unsigned long) 0, (unsigned long) 0);
    result = result && test_scenario__U4D( (unsigned long) 1, (unsigned long) 1, (unsigned long) 1, (unsigned long) 0);
    result = result && test_scenario__U4D( (unsigned long) 1000, (unsigned long) 201, (unsigned long) 4, (unsigned long) 196);
    result = result && test_scenario__U4D( (unsigned long) 201, (unsigned long) 1000, (unsigned long) 0, (unsigned long) 201);
    
    result = result && test_scenario__U4D( (unsigned long) 4294967295, (unsigned long) 69997, (unsigned long) 61359, (unsigned long) 21372);
    result = result && test_scenario__U4D( (unsigned long) 69997, (unsigned long) 4294967295, (unsigned long) 0, (unsigned long) 69997);
    result = result && test_scenario__U4D( (unsigned long) 4294967295, (unsigned long) 4294967295, (unsigned long) 1, (unsigned long) 0);

    return result;
}

Boolean test_function__I4D() {

    Boolean result = TRUE;

    result = result && test_scenario__I4D( (long) 0, (long) 1, (long) 0, (long) 0);
    result = result && test_scenario__I4D( (long) 1, (long) 1, (long) 1, (long) 0);
    result = result && test_scenario__I4D( (long) -1, (long) 1, (long) -1, (long) 0);
    result = result && test_scenario__I4D( (long) 1, (long) -1, (long) -1, (long) 0);
    result = result && test_scenario__I4D( (long) 0, (long) -1, (long) 0, (long) 0);
    result = result && test_scenario__I4D( (long) 1000, (long) 201, (long) 4, (long) 196);
    result = result && test_scenario__I4D( (long) -1000, (long) 201, (long) -4, (long) -196);
    result = result && test_scenario__I4D( (long) -111111, (long) 111111, (long) -1, (long) 0);

    result = result && test_scenario__I4D( (long) 2147483647, (long) 69997, (long) 30679, (long) 45684);
    result = result && test_scenario__I4D( (long) 69997, (long) 2147483647, (long) 0, (long) 69997);
    result = result && test_scenario__I4D( (long) -2147483648, (long) 69997, (long) -30679, (long) -45685);
    result = result && test_scenario__I4D( (long) 69997, (long) -2147483648, (long) 0, (long) 69997);

    return result;
}

Boolean test_function__CHP() {

    Boolean result = TRUE;
    
    result = result && test_scenario__CHP( (long double) .001, (long) 0);
    result = result && test_scenario__CHP( (long double) .999, (long) 0);
    result = result && test_scenario__CHP( (long double) 99.9, (long) 99);
    result = result && test_scenario__CHP( (long double) -0.001, (long) 0);
    result = result && test_scenario__CHP( (long double) -0.999, (long) 0);
    result = result && test_scenario__CHP( (long double) -99.9, (long) -99);
    
    return result;
}

Boolean test_scenario__U4M(unsigned long factor1, unsigned long factor2, unsigned long expectedValue) {
    return ((factor1 * factor2) == expectedValue) && ((factor2 * factor1) == expectedValue);
}

Boolean test_scenario__I4M(long factor1, long factor2, long expectedValue) {
    return ((factor1 * factor2) == expectedValue) && ((factor2 * factor1) == expectedValue);
}

Boolean test_scenario__U4D(unsigned long dividend, unsigned long divisor, unsigned long expectedQutient, unsigned long expectedRemainder) {
    return( (dividend / divisor == expectedQutient) && (dividend % divisor == expectedRemainder));
}

Boolean test_scenario__I4D(long dividend, long divisor, long expectedQutient, long expectedRemainder) {
    return( (dividend / divisor == expectedQutient) && (dividend % divisor == expectedRemainder));
}

Boolean test_scenario__CHP(long double number, long expectedValue) {
    return ((long) number) == expectedValue;
}
