//===========================================================================
//-- File Version    : 
//-- Date            : 
//-- Author          : kido
//-- example of coverages are common in design verification
//===========================================================================

// simple sample covergroup in class
class abc;
    bit [2:0] mode;
    bit [3:0] addr;
    
    // standard covergroup
    covergroup cg;
        cp_mode: coverpoint mode iff(!rst_n){
            // simple bins
            bins b1 = {0, 2};           // gen 1 bin {0, 2}
            bins b2[] = {[0 : 3]};      // gen 4 bins {0}, {1}, {2}, {3}
            bins b3[2] = {[0 : 3]};     // gen 2 bins {0, 1}, {2, 3}
            bins b5 = (1=>3=>0);        // transition bins
            bins b6 = (1,0=>0,1);       // gen 4 bins {1=>0}, {1=>1}, {0=>1}, {0=>0}
            // more complex
            bins b4 = {[1:$]};                      // mode must be more than 1
            bins b7[] = (4[*3]);                    // {4 => 4 => 4}
            bins b8[] = (4[*1:3]);                  // {4}, {4 => 4}, {4 => 4 => 4}, 
            bins b9[] = (5[->3]=>7);                // after the third of 5 must be 7, eg: 5=>2=>3=>5=>5=>7
            bins b10[] = (5[=3]=>7);                // after 3rd of 5 must be 7 but it can have gap, eg: 5=>2=>3=>5=>5=>2=>7
            bins b11[] = mode with {item % 3 == 0}; // mode is divisible by 3
            // ignore bins
            ignore_bins ig_b1 = {4, 5};
            // illegal bins
            illegal_bins il_b1 = {4};           // it can stop simulation if this bin hits
            // default bin
            bins b11 = default;                 // value that arent explicit above: {7}
            // wildcard bin
            wildcard bins b12[] = {3'b00?};    // {000}, {001}
        }
        cp_addr: coverpoint addr iff(!rst_n);
        cp_addr1: coverpoint addr iff(!rst_n){
            bins b_a[2] = {1, 2};
        }
        // cross bins
        mode_x_addr: cross cp_mode, cp_addr iff(!rst_n);
        mode_x_addr1: cross cp_mode, cp_addr{
            bins b1 = binsof(cp_mode.b1);                               // <b1, b_a[0]>, <b1, b_a[1]>
            bins b2 = binsof(cp_mode.b1) && binsof(cp_addr.b_a[1]);     // <b1, b_a[1]>
            bins b3 = binsof(cp_mode.b1) || binsof(cp_addr.b_a[1]);     // <b1, b_a[0]>, <b1, b_a[1]>, 
            // intersect (not used)
        }
        // some options
        option.per_instance = 1; // boolean, if true, this cg will contribute to overall coverage
    endgroup
    
    // parameterized and override sample
    covergroup cg_p(bit a, ref bit b) with sample(bit c);
        option.per_instance=1;
        cp1: coverpoint addr[1] {
            bins b1 = {a};
        }
        cp2: coverpoint b;
        cp_cross: cross cp1, cp2, c;
    endgroup
    // initialize
    function new();
        cg = new();
        cg_p = new(1, addr[0]);
    endfunction

    // sample covergroup
    function sample;
        cg.sample();
        cg_p.sample(addr[2]);
    end
endclass

// advance: covergroup outside class
// transition coverage in 1 of 128 bits
covergroup toggle_cg with function sample(bit eachbit); 
    option.per_instance = 0;
    type_option.merge_instances = 1; // merge all instances into one
    coverpoint eachbit {
        bins toggle = ( 1 => 0 => 1 };
    }
endgroup
    ...
    toggle_cg t_cg[128]
    bit [127:0] myvector;

    foreach(t_cg[i]) t_cg[i] = new();
    ...
    foreach(t_cg[i]) t_cg[i].sample(myvector[i]);
