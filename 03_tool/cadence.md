# Waveform
## Command
* View wave:
```bash
    simvision -64BIT
```
## Cadence Simvision db

```verilog
$shm_open("waves.shm");
$shm_probe[( scope1, "node_specifier1", scope2, "node_specifier2", ... )];

// example
// $shm_probe(top.dut1, top.dut2);
// $shm_probe(top.dut1, "S", top.dut2, "AC");
```
| specifier  | decription |
| -- | --|
| "A" | input, output, inout, wire, reg,... excluding memories |
| "S" | input, output, inout, below instantiations, except libary cells |
| "C" | input, output, inout, below instantiations, including libary cells |
| "M" | input, output, inout, including memories |
| "T" | objects in task |
| "F" | objects in function |
# Merge coverage
## Command
```bash
imc -exec merge_cov.tcl
```
## Example merge_cov.tcl
```tcl
# Coverage merge
merge ./cov/*  -out ./merge -overwrite -message 1
# Loaded the merged coverage database.
load -run ./cov_work/merge
#show -run

# exclude unused instance
exclude -inst uvm_pkg -covergroup cg -comment "unused covergroup"
# exclude toggle signals
set inst_name "top.module_name"
exclude -inst $inst_name -toggle {addr[5-11]}

# Loaded the merged coverage database.
report_metrics -detail -inst -metrics all -out ./rp_cov/report_metrics -overwrite

# export csv (unused)
#csv_export -bins -out ./rp_cov/cov.csv -overwrite
# report in txt format
#report -detail -inst -uncovered -text -out ./rp_cov/report_detail.txt

exit
```

