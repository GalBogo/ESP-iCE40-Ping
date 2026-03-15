module leds_buzzers_notifi (
    input logic         clk,
    input logic         rst_n,
    input logic [1:0]   current_state,
    
    output logic [8:0] leds,
    output logic buzzer1,
    output logic buzzer2
);

    localparam S_IDLE = 2'b00;
    localparam S_CALL = 2'b01;
    localparam S_MSG  = 2'b10;

    // Leds part

    localparam led_call_state_1 = 4000000;  // 0.33 second
    localparam led_call_state_2 = 8000000;  // 0.66 second
    localparam led_call_state_3 = 12000000;  // 1 second
    localparam led_call_state_4 = 16000000; // 1.3 second

    logic [23:0] led_counter;

    // Buzzer part

    localparam buzzer_toggle = 2000;        // for making the buzzer "bip" in 3kHz (12M / 3K devided by 2 for the toggle)
    logic [15:0] buzzer_counter = 0;
    logic      buzzer_enable;               // Logic decides when to let the buzzer sound
    logic      tone_bit;

    assign buzzer1 = buzzer_enable? tone_bit : 1'b0;
    assign buzzer2 = buzzer_enable? tone_bit : 1'b0;

    //================================================
    //          Sequential Logic For Leds
    //================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            led_counter <= 0;
        end else begin
            if (current_state == S_CALL) begin
                if (led_counter < led_call_state_3) led_counter <= led_counter + 1;
                else led_counter <= 0;
            end else if (current_state == S_MSG) begin
                if (led_counter < led_call_state_4) led_counter <= led_counter + 1;
                else led_counter <= 0;
            end else begin
                led_counter <= 0;
            end
        end
    end

    //================================================
    //          Sequential Logic For Buzzers
    //================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            buzzer_counter <= 0;
            tone_bit <= 0;
        end else begin
            if (buzzer_counter >= buzzer_toggle) begin
                buzzer_counter <= 0;
                tone_bit <= ~tone_bit;
            end else begin
                buzzer_counter <= buzzer_counter + 1;
            end
        end
    end
    
    //================================================
    //          Combinational Logic For Leds
    //================================================

    always_comb begin
        leds = 9'b0;

        case (current_state)
            S_IDLE: begin
            end

            S_CALL: begin
                if (led_counter <= led_call_state_1) begin
                    leds = 9'b0_0100_1001;
                end else if (led_counter <= led_call_state_2) begin
                    leds = 9'b0_1001_0010;
                end else begin
                    leds = 9'b1_0010_0100;
                end
            end

            S_MSG: begin
                if (led_counter <= led_call_state_1) begin
                    leds = 9'b1_1111_1111; 
                end else if (led_counter <= led_call_state_2) begin
                    leds = 9'b0;            
                end else if (led_counter <= led_call_state_3) begin
                    leds = 9'b1_1111_1111;
                end else begin
                    leds = 9'b0;           
                end
            end
        endcase
    end

    //================================================
    //          Combinational Logic For Buzzers
    //================================================    

    always_comb begin
        buzzer_enable = 1'b0;

        case (current_state)
            S_IDLE: begin
            end

            S_CALL: begin
                if (led_counter <= led_call_state_2) begin
                    buzzer_enable = 1'b1;
                end else begin
                    buzzer_enable = 1'b0;
                end
            end

            S_MSG: begin
                if (led_counter <= led_call_state_1) begin
                    buzzer_enable = 1'b1;
                end else if (led_counter <= led_call_state_2) begin
                    buzzer_enable = 1'b0;
                end else if (led_counter <= led_call_state_3) begin
                    buzzer_enable = 1'b1;
                end else begin
                    buzzer_enable = 1'b0;
                end
            end
        endcase
    end

endmodule