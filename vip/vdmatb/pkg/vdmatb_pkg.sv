`ifndef __VDMATB_PKG_SV__
`define __VDMATB_PKG_SV__


package vdmatb_pkg;
  
  `vdmatb_import_core_pkg


  // TODO:ANDA_WORKING -- make those as "function"
  class checkItemsByType #(parameter type T =int);
     static function bit compareItem (string header, string item, int num, T actual, T expected, bit displayOn = 0);
        bit error;
        //displayOn = 1;
        if (actual !== expected) begin
           if (displayOn == 1)
          `uvm_info ($sformatf("CHECKER_%s_ERROR",header), $sformatf("compare %s : %0d actual %0h, expected %0h", item, num, actual, expected), UVM_LOW);
          error = 1'b1;
        end else  begin
           if (displayOn == 1)
          `uvm_info ($sformatf("CHECKER_%s_OK   ",header), $sformatf("compare %s : %0d actual %0h, expected %0h", item, num, actual, expected), UVM_MEDIUM);
          error = 1'b0;
        end
        return (error);
     endfunction:compareItem
  endclass:checkItemsByType

  class checkItems #(parameter int WIDTH = 512);
     static function bit compareItem (string header, string item, int num, logic [WIDTH-1:0] actual, logic [WIDTH-1:0] expected, bit displayOn = 0);
        bit error;
        //displayOn = 1;
        if (actual !== expected) begin
           if (displayOn == 1)
          `uvm_info ($sformatf("CHECKER_%s_ERROR",header), $sformatf("compare %s : %0d actual %0h, expected %0h", item, num, actual, expected), UVM_LOW);
          error = 1'b1;
        end else  begin
           if (displayOn == 1)
          `uvm_info ($sformatf("CHECKER_%s_OK   ",header), $sformatf("compare %s : %0d actual %0h, expected %0h", item, num, actual, expected), UVM_MEDIUM);
          error = 1'b0;
        end
        return (error);
     endfunction:compareItem
  
     static function bit compareItemWithStrb (string header, string item, int num, logic [WIDTH-1:0] actual, logic [WIDTH-1:0] expected, logic [WIDTH/8-1:0] strb, bit displayOn = 0);
        bit error;
  
        for (int i =0; i <WIDTH; i++) begin
          actual[i]   = actual[i]   & strb[i/8];
          expected[i] = expected[i] & strb[i/8];
        end
  
        error = compareItem(header, item, num, actual, expected, displayOn);
  
        return (error);
     endfunction:compareItemWithStrb
  
     static function bit compareItemWithMask (string header, string item, int num, logic [WIDTH-1:0] actual, logic [WIDTH-1:0] expected, logic [WIDTH-1:0] mask, bit displayOn = 0);
        bit error;
  
        error = compareItem(header, item, num, actual&mask, expected&mask, displayOn);
  
        return (error);
     endfunction:compareItemWithMask
  
     static function int countOnes(logic [WIDTH-1:0] inData);
        int count;
  
        for (int i =0; i <WIDTH; i++) begin
          count = count + inData[i];
        end
        return (count);
     endfunction:countOnes
  
     static function logic [WIDTH-1:0] andWithStrb(logic [WIDTH-1:0] inData, bit [WIDTH/8-1:0] strb);
        logic [WIDTH-1:0] outData;
        for (int i =0; i <WIDTH; i++) begin
          outData[i] = inData[i] & strb[i/8];
        end
        return (outData);
     endfunction:andWithStrb
  
  endclass:checkItems



endpackage:vdmatb_pkg

`endif  // __VDMATB_PKG_SV__
