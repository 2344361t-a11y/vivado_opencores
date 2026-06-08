`include "timescale.v"

module generic_dpram
#(
    parameter aw = 8,
    parameter dw = 8
)
(
    input              rclk,
    input              rrst,
    input              rce,
    input              oe,
    input  [aw-1:0]    raddr,
    output reg [dw-1:0] do,

    input              wclk,
    input              wrst,
    input              wce,
    input              we,
    input  [aw-1:0]    waddr,
    input  [dw-1:0]    di
);

reg [dw-1:0] mem [0:(1<<aw)-1];

always @(posedge wclk) begin
    if (wce && we) begin
        mem[waddr] <= di;
    end
end

always @(posedge rclk) begin
    if (rce && oe) begin
        do <= mem[raddr];
    end
end

endmodule