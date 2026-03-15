module top_notifi_project (
    input  logic        clk,      
    input  logic        rst_n,

    // inputs from ESP32
    input  logic        msg_in,
    input  logic        call_in,
    
    // Servo
    output logic        servo_pwm,
    
    // Leds and Buzzers
    output logic [8:0]  leds,
    output logic        buzzer1,
    output logic        buzzer2
);

    // states
    typedef enum logic [1:0] {
        S_IDLE  = 2'b00,                 // waiting for the ESP32 to signal
        S_MSG   = 2'b10,                 // got a message
        S_CALL  = 2'b01                  // someone is calling
    } state_t;

    state_t current_state, next_state;
    
    localparam msg_limit = 16000000;
    logic [24:0] msg_counter = 0;

    // =========================================================
    //                Leds and Buzzers
    // =========================================================
    leds_buzzers_notifi u_leds_buzzers (
        .clk(clk),
        .rst_n(rst_n),
        .current_state(current_state), 
        .leds(leds),              
        .buzzer1(buzzer1),      
        .buzzer2(buzzer2)
    );

    //==========================================================
    //                  Servo
    //==========================================================
    servo_notifi u_servo (
    .clk(clk),
    .rst_n(rst_n),
    .current_state(current_state),
    .servo_pwm(servo_pwm)
);
    // =========================================================
    //   Responsible for accuracy and stability of the system
    // =========================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state  <= S_IDLE;
            msg_counter <= 0;
        end else begin
            current_state <= next_state;

            if (current_state == S_MSG) begin
                msg_counter <= msg_counter + 1;
            end else begin
                msg_counter <= 0;
            end
        end
    end

    // =========================================================
    //                      Next State Logic
    // =========================================================
    always_comb begin
        next_state = current_state; 

        case (current_state)
            S_IDLE: begin
                if (call_in == 1) next_state = S_CALL;
                else if (msg_in == 1) next_state = S_MSG;
            end

            S_CALL: begin
                if (call_in == 0) begin
                    next_state = S_IDLE;
                end
            end

            S_MSG: begin
                if (msg_counter >= msg_limit) begin
                    next_state = S_IDLE;
                end else if (call_in == 1) begin
                    next_state = S_CALL;
                end
            end
        endcase
    end

endmodule