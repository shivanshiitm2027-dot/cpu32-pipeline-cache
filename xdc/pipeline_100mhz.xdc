## 5-Stage Pipeline CPU - 100 MHz Clock Constraint
## 100 MHz = 10 ns period

create_clock -period 10.000 -name clk [get_ports clk]

## Reset false path
set_false_path -from [get_ports rst]