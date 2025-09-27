
module opt_check (input a , input b , output y);
        assign y = a?b:0;
endmodule

For opt_check.v the assignment y = a?b:0 reduces to y = ab
