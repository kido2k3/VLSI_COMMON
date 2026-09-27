# Common command in projects

## sed

For file export, text capture

1. Delete lines having `error`
    ```sh
    sed '/error/d' in.txt > out.txt
    ```
2. Replace `error` with `warning`
    ```sh
    sed 's/error/warning/' in.txt > out.txt
    ```

3. Capture text and save into array
    ```sh
    set data = (`echo "Tom 25 Hanoi" | sed 's/\(Tom\) \(25\) \(Hanoi\)/\1 \2 \3/'`)
    set name = $data[1]
    set age = $data[2]
    set city = $data[3]
    ```
**Advance:**
* `.*`: ignore capturing text
* `\([0-9]*\)`: capture numbers
* `\([^0-9]\)`: capture all except numbers
* `\([^a-zA-Z]\)`: capture all except text
* `\([^,]*\)`: capture all before ,

## awk

For table, csv, directory

1. Get data from csv file
    ```sh
    awk -F',' '{print $1}' in.csv
    ```
**Advance:**
* `$0`: full line
* `$1`: column 1 (1st column)
* `$2`: column 2  ...
* `$NF`: last column
* `NF`: the current number of column
* `NR`: the number of row

2. Get data with condition
    ```sh
    awk -F',' '$1 == "#" && $2 == "imm reg" {print $0}' in.csv
    ```
3. Calculate
    ```sh
    awk -v mode="$mode" '
    BEGIN {
        sum=0
        prod=1
    }
    (mode=="skip"){
        next
    }
    {
        sum += $1
        prod *= $1
    }
    END {
        if(mode=="sum"){
            printf "sum = %d\n", sum
        }
        if(mode=="prod")
            print "prod =", prod
    }' in.csv
    ```
**Above code:**
* `BEGIN`: run once at the begin of file scan
* `END`: run once at the end of file scan
* `-v`: set variable inside awk code
* `next`: skip the current line, continue to next line

# seed generation
* bash:
```
seed=$(( $(od -An -N4 -tu4 /dev/urandom) & 0x7FFFFFFF ))
```
* csh:
```
set seed = `od -An -N3 -tu4 /dev/urandom`
```
