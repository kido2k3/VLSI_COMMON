//===========================================================================
//-- File Version    : 
//-- Date            : 
//-- Author          : kido
//-- All assertions are common in design verification, and its explaination
//===========================================================================

// Checker: a is connecting to b
property a_connect_b;
    @(posedge clk) disable iff(!rst_n)
    a == b;
endproperty

// Checker: enqueued packets must be dequeued within 100 cycles
property dequeued_100;
    logic [31 : 0]p_data;
    int p_id;
    @(posedge clk) disable iff(!rst_n)
    ($rose(load), p_data = i_data, p_id = i_id) |=>
    ##[0 : 100] o_dout && o_id == p_id |->
    o_data == p_data;
endproperty

// Checker: if en hold, b needn't happen if c true. If c doesnt occur b must hold for no more than 4 cycles
property prop;
    @(posedge clk) en |-> b[*0 : 4] ##1 c;
endproperty

// Checker: if en hold, b need to occur 2 times, then c occurs
property prop;
    @(posedge clk) en |-> b[=2] ##1 c; // this fail only if the third occurence of b but c doesn't yet occur
endproperty

// Checker: if en hold, b need to occur 2 times, then c occurs as soon as the second occurence of b
property prop;
    @(posedge clk) en |-> b[->2] ##1 c; 
endproperty

// Checker: within window of time starting with (go) and ending with (done), slave must transfer 2 loads using handshake signals (request) and (accepted)
property prop;
    @(posedge clk) (##[0 : $] $rose(request) ##1 (##[0 : 3] ##1 accepted)[*2]) within 
    (go ##[1 : 20] done);
endproperty

// Checker: (request) is followed by (ack) something within the next cycle and up to 4 cycles later. (ack) is followed by (done). Througout (ack) and (done), (enable) must be asserted
property prop;
    @(posedge clk) $rose(request) |-> ##[1:4] (enable) throughout (ack ##[1:$] done);
endproperty

// Checker: sta is true and must remain true until ready goes true
// ready must go true within 4 clock cycles
// After ready goes true, both sta and ready must go to 0 in the next clock cycle
property prop;
    @(posedge clk) $rose(sta) |-> ((sta) throughout (##[1:4] ready)) ##1 !sta && !ready;
endproperty