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
    
    return FALSE;
}

Boolean test_function__I4D() {
    
    return FALSE;
}

Boolean test_function__CHP() {
    
    return FALSE;
}

Boolean test_scenario__U4M(unsigned long factor1, unsigned long factor2, unsigned long exceptedValue) {
    return ((factor1 * factor2) == exceptedValue) && ((factor2 * factor1) == exceptedValue);
}

Boolean test_scenario__I4M(long factor1, long factor2, long exceptedValue) {
    return ((factor1 * factor2) == exceptedValue) && ((factor2 * factor1) == exceptedValue);
}
