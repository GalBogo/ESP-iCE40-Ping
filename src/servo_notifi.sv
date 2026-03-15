module servo_notifi (
    input  logic       clk,
    input  logic       rst_n,
    input  logic [1:0] current_state,
    
    output logic       servo_pwm
);

    localparam S_IDLE = 2'b00;
    localparam S_CALL = 2'b01;
    localparam S_MSG  = 2'b10;

    localparam PWM_PERIOD = 240000;   
    localparam DEG_0      = 12000;   
    localparam DEG_45     = 15000;  
    localparam DEG_180    = 24000;    

    localparam STEP_CALL = 100;      
    localparam STEP_MSG  = 120;    

    logic [17:0] pwm_counter;
    logic [15:0] duty_cycle;
    logic        dir_up;          

    //================================================
    //          Combinational Logic (PWM Generation)
    //================================================
    always_comb begin
        if (current_state == S_IDLE) begin
            servo_pwm = 1'b0;     
        end else begin
            servo_pwm = (pwm_counter < duty_cycle) ? 1'b1 : 1'b0;
        end
    end

    //================================================
    //          Sequential Logic (Counters & Sweeping)
    //================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pwm_counter <= 0;
            duty_cycle  <= DEG_0;
            dir_up      <= 1'b1;
        end else begin
            if (current_state == S_IDLE) begin
                pwm_counter <= 0;
                duty_cycle  <= DEG_0; 
                dir_up      <= 1'b1;
            end else begin
                if (pwm_counter < PWM_PERIOD - 1) begin
                    pwm_counter <= pwm_counter + 1;
                end else begin
                    pwm_counter <= 0; 

                    if (current_state == S_CALL) begin
                        if (dir_up) begin
                            if (duty_cycle + STEP_CALL >= DEG_180) dir_up <= 1'b0;
                            else duty_cycle <= duty_cycle + STEP_CALL;
                        end else begin
                            if (duty_cycle - STEP_CALL <= DEG_0) dir_up <= 1'b1; 
                            else duty_cycle <= duty_cycle - STEP_CALL;
                        end
                    end 
                    else if (current_state == S_MSG) begin
                        if (dir_up) begin
                            if (duty_cycle + STEP_MSG >= DEG_45) dir_up <= 1'b0;   
                            else duty_cycle <= duty_cycle + STEP_MSG;
                        end else begin
                            if (duty_cycle - STEP_MSG <= DEG_0) dir_up <= 1'b1;  
                            else duty_cycle <= duty_cycle - STEP_MSG;
                        end
                    end
                end
            end
        end
    end

endmodule