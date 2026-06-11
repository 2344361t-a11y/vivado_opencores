// Stand-alone 8-bit GPIO controller with a compact WISHBONE-style bus.
// Address 0: direction register. 1=output, 0=input.
// Address 1: line register. Write sets output value, read returns pin level.
module gpio_controller #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             wb_cyc,
    input  wire             wb_stb,
    input  wire             wb_addr,
    input  wire             wb_we,
    input  wire [7:0]       wb_wdata,
    output reg  [7:0]       wb_rdata,
    output reg              wb_ack,
    inout  wire [WIDTH-1:0] gpio,
    output reg  [WIDTH-1:0] direction_reg,
    output reg  [WIDTH-1:0] output_reg,
    output reg  [WIDTH-1:0] input_data,
    output reg              read_valid,
    output reg              done,
    output wire             busy,
    output wire             ready
);

    reg [WIDTH-1:0] gpio_sample_1;
    reg [WIDTH-1:0] gpio_sample_2;
    reg [WIDTH-1:0] read_value;

    wire bus_access = wb_cyc & wb_stb;
    wire bus_accept = bus_access & ~wb_ack;
    wire bus_write = bus_accept & wb_we;

    assign busy = bus_access & ~wb_ack;
    assign ready = ~busy;

    function [7:0] to_bus_data;
        input [WIDTH-1:0] value;
        begin
            to_bus_data = 8'h00;
            to_bus_data[WIDTH-1:0] = value;
        end
    endfunction

    genvar bit_index;
    generate
        for (bit_index = 0; bit_index < WIDTH; bit_index = bit_index + 1) begin : gpio_tristate
            assign gpio[bit_index] = direction_reg[bit_index] ? output_reg[bit_index] : 1'bz;
        end
    endgenerate

    initial begin
        if (WIDTH > 8) begin
            $display("[%0t] GPIO_CTRL INFO: WIDTH greater than 8 is not supported by the 8-bit bus", $time);
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            direction_reg <= {WIDTH{1'b0}};
            output_reg <= {WIDTH{1'b0}};
            input_data <= {WIDTH{1'b0}};
            gpio_sample_1 <= {WIDTH{1'b0}};
            gpio_sample_2 <= {WIDTH{1'b0}};
            read_value <= {WIDTH{1'b0}};
            wb_rdata <= 8'h00;
            wb_ack <= 1'b0;
            read_valid <= 1'b0;
            done <= 1'b0;
            $display("[%0t] GPIO_CTRL PATH: reset direction=00 output=00 wb_ack=0", $time);
        end else begin
            gpio_sample_1 <= gpio;
            gpio_sample_2 <= gpio_sample_1;
            wb_ack <= bus_accept;
            read_valid <= 1'b0;
            done <= 1'b0;
            wb_rdata <= wb_addr ? to_bus_data(gpio_sample_2) : to_bus_data(direction_reg);

            if (bus_write) begin
                done <= 1'b1;
                if (wb_addr) begin
                    output_reg <= wb_wdata[WIDTH-1:0];
                    $display("[%0t] GPIO_CTRL PATH: write_line addr=01 wb_wdata=%02h output=%02h",
                             $time, wb_wdata, wb_wdata[WIDTH-1:0]);
                end else begin
                    direction_reg <= wb_wdata[WIDTH-1:0];
                    $display("[%0t] GPIO_CTRL PATH: write_direction addr=00 wb_wdata=%02h direction=%02h",
                             $time, wb_wdata, wb_wdata[WIDTH-1:0]);
                end
            end else if (bus_accept) begin
                done <= 1'b1;
                if (wb_addr) begin
                    read_value = gpio_sample_2;
                    input_data <= read_value;
                    wb_rdata <= to_bus_data(read_value);
                    read_valid <= 1'b1;
                    $display("[%0t] GPIO_CTRL DATA: read_line addr=01 gpio_sample=%02h wb_rdata=%02h",
                             $time, gpio_sample_2, to_bus_data(read_value));
                end else begin
                    wb_rdata <= to_bus_data(direction_reg);
                    $display("[%0t] GPIO_CTRL DATA: read_direction addr=00 direction=%02h wb_rdata=%02h",
                             $time, direction_reg, to_bus_data(direction_reg));
                end
            end
        end
    end

endmodule
