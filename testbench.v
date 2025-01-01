module bench();
    reg xtal;
    wire resetn = 1;

    Soc dut(
        .xtal(xtal),
        .resetn(resetn)
    );

    initial begin
        xtal = 0;
        forever begin
            #1 xtal = ~xtal;
        end
    end

endmodule