//===========================================================================
//-- File Version    : 
//-- Date            : 
//-- Author          : kido
//-- All assertions are common in design verification, and its explaination
//===========================================================================

// Function: check whether a is connecting to b
property a_connect_b;
    @(posedge clk) a == b;
endproperty
as_a_connect_b: assert property(a_connect_b)
    else $error("Assertion as_a_connect_b failed!");
