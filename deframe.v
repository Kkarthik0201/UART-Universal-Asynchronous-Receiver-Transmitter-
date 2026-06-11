
module DeFrame(
    input  wire [10:0] data_parll,     
    input  wire        recieved_flag,

    
    output wire        parity_bit,      
    output wire        start_bit,       
    output wire        stop_bit,        
    output wire        done_flag,       
    output wire [7:0]  raw_data         
);

   
    
    assign start_bit  = data_parll[0];
    assign raw_data   = data_parll[8:1];
    assign parity_bit = data_parll[9];
    assign stop_bit   = data_parll[10];

  
    assign done_flag  = recieved_flag;

endmodule