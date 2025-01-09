module bench();
    reg xtal;
    wire resetn = 1;
    wire gpio;

    Soc dut(
        .xtal(xtal),
        .resetn(resetn),
        .gpio(gpio)
    );

    reg prev_gpio = 0;
    initial begin
        xtal = 0;
        forever begin
            #1 xtal = ~xtal;
            if (gpio != prev_gpio) begin
                $display("gpio: %b", gpio);
            end
            prev_gpio <= gpio;
        end
    end

endmodule