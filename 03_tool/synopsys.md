# Waveform

## Synopsys DVE db

```verilog
    $vcdplusfile ("filename.vpd");
    $vcdpluson(level|”LVL=integer_variable”,scope*,signal*);

    // example
    // $vcdpluson;
    // $vcdpluson(test.risc1.alureg);
```

## Synopsys Verdi db

```verilog
    $fsdbDumpfile("test.fsdb");
    $fsdbDumpvars(level,path);

    // example
    // $fsdbDumpvars(0,test);
    // $fsdbDumpvars;
```
# Merge coverage

