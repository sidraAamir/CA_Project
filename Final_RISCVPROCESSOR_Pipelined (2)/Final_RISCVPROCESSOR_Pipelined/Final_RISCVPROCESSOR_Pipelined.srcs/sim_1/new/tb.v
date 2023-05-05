module tb;
  reg Clk;
  reg Reset;
  
  Pipelined_Processor test(
  .clk(Clk),
  .reset(Reset)
);  
  initial
    begin
      Reset = 1'b1;
      Clk = 1'b0;
      #10
      Reset = 1'b0;
    end
  
  always
    begin
      #5 Clk = ~Clk;
    end
  
    initial
      begin
//        $monitor("Time = %d --> Clk = %d, Reset = %d ",$time, Clk, Reset);
      end
  
endmodule
