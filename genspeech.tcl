# Open the input speech.txt file
set fp [open "./wbuart32/trunk/bench/cpp/speech.txt" r]
fconfigure $fp -translation lf
set content [read $fp]
close $fp

set processed_bytes {}
set len [string length $content]
for {set i 0} {$i < $len} {incr i} {
    set char [string index $content $i]
    if {$char == "\n"} {
        lappend processed_bytes 13
        lappend processed_bytes 10
    } else {
        binary scan $char c ascii_val
        set val [expr {$ascii_val & 0xff}]
        lappend processed_bytes $val
    }
}

# Write the formatted speech.hex file
set fout [open "./wbuart32/trunk/bench/verilog/speech.hex" w]
fconfigure $fout -translation lf
set addr 0
set i 0
set num_bytes [llength $processed_bytes]
while {$i < $num_bytes} {
    set line [format "@%08x " $addr]
    set linelen 10
    while {$i < $num_bytes && $linelen < 77} {
        set val [lindex $processed_bytes $i]
        set hex_val [format "%02x" $val]
        append line "$hex_val "
        incr addr
        incr i
        incr linelen 3
    }
    # Trim trailing space
    set line [string trimright $line]
    puts $fout $line
}
close $fout
puts "Successfully generated speech.hex"
