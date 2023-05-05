module tb();

reg clk, reset;
wire [63:0] element1,element2,element3,element4;

processor p0(
	.clk(clk),
	.reset(reset),
	.element1(element1),.element2(element2),.element3(element3),.element4(element4)
);

always
#5 clk = ~clk;

initial
begin
	clk = 0;
	reset = 1;
	#10 reset = 0;
end

endmodule;