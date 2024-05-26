LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
use work.game_type_pkg.ALL;

ENTITY pipes IS
    PORT
    (
        clk, vert_sync : IN std_logic;
        pixel_row, pixel_column : IN std_logic_vector(9 DOWNTO 0);
        input_state : IN std_logic_vector(3 DOWNTO 0); -- Input state for FSM
        output_on : OUT std_logic;
        RGB : OUT std_logic_vector(11 DOWNTO 0);
        p1_x_pos, p2_x_pos, p3_x_pos : OUT signed(10 DOWNTO 0);
        p1_gap_center, p2_gap_center, p3_gap_center : OUT signed(9 DOWNTO 0);
        blue_box_x_pos : OUT signed(10 DOWNTO 0);
        blue_box_y_pos : OUT signed(9 DOWNTO 0);
        ball_x_pos, ball_y_pos : IN signed(10 DOWNTO 0); -- Add ball position inputs
        ball_size : IN signed(9 DOWNTO 0); -- Add ball size input
        red_box_x_pos : OUT signed(10 DOWNTO 0);
        red_box_y_pos : OUT signed(9 DOWNTO 0);
        reset_red_box : IN std_logic
    );
END pipes;

ARCHITECTURE behavior OF pipes IS
    SIGNAL p1_on : std_logic;
    SIGNAL p1_x_pos_internal : signed(10 DOWNTO 0) := to_signed(213, 11); 
    SIGNAL p1_gap_center_internal : signed(9 DOWNTO 0) := to_signed(240, 10);

    SIGNAL p2_on : std_logic;
    SIGNAL p2_x_pos_internal : signed(10 DOWNTO 0) := to_signed(426, 11);
    SIGNAL p2_gap_center_internal : signed(9 DOWNTO 0) := to_signed(360, 10);

    SIGNAL p3_on : std_logic;
    SIGNAL p3_x_pos_internal : signed(10 DOWNTO 0) := to_signed(640, 11);
    SIGNAL p3_gap_center_internal : signed(9 DOWNTO 0) := to_signed(100, 10);

    SIGNAL pipe_x_size : signed(9 DOWNTO 0) := to_signed(30, 10);
    SIGNAL start_move : std_logic := '0';

    SIGNAL random_value : std_logic_vector(9 DOWNTO 0);

    SIGNAL blue_box_on : std_logic := '0';
    SIGNAL blue_box_x_pos_internal : signed(10 DOWNTO 0) := to_signed(1000, 11);
    SIGNAL blue_box_y_pos_internal : signed(9 DOWNTO 0);

    SIGNAL blue_box_size : signed(9 DOWNTO 0) := to_signed(32, 10); -- size of the blue box
    SIGNAL blue_box_visible : std_logic := '1'; -- Visibility of the blue box

    SIGNAL red_box_on : std_logic := '0';
    SIGNAL red_box_x_pos_internal : signed(10 DOWNTO 0) := to_signed(800, 11);
    SIGNAL red_box_y_pos_internal : signed(9 DOWNTO 0);

    SIGNAL red_box_size : signed(9 DOWNTO 0) := to_signed(32, 10); -- size of the red box
    SIGNAL red_box_visible : std_logic := '1'; -- Visibility of the red box

    SIGNAL coin_color, heart_color : STD_LOGIC_VECTOR(11 DOWNTO 0);
    SIGNAL coin_address, heart_address : STD_LOGIC_VECTOR(9 DOWNTO 0);
    SIGNAL selected_color : STD_LOGIC_VECTOR(11 DOWNTO 0);

    SIGNAL coin_active : std_logic := '0';
    SIGNAL red_box_active : std_logic := '0';
	 
	 SIGNAL power_state : integer range 0 to 3;

    COMPONENT galois_lfsr
        PORT
        (
            clk : IN std_logic;
            state_in : IN std_logic_vector(3 DOWNTO 0);
            random_value : OUT std_logic_vector(9 DOWNTO 0)
        );
    END COMPONENT;
    
    COMPONENT coin_rom
        PORT
        (
            clk : IN STD_LOGIC;
				powerup_selected : IN integer range 0 to 3;
            coin_address : IN STD_LOGIC_VECTOR(9 DOWNTO 0);
            coin_data_out : OUT STD_LOGIC_VECTOR(11 DOWNTO 0)
        );
    END COMPONENT;

BEGIN
    lfsr_inst: galois_lfsr
        PORT MAP (
            clk => clk,
            state_in => input_state,
            random_value => random_value
        );
    coin_inst: coin_rom
        PORT MAP (
            clk => clk,
				powerup_selected => power_state,
            coin_address => coin_address,
            coin_data_out => coin_color
        );
    p1_on <= '1' WHEN (p1_x_pos_internal + pipe_x_size > to_signed(0, 11) AND
                     to_integer(unsigned(pixel_column)) >= to_integer(p1_x_pos_internal) AND 
                     to_integer(unsigned(pixel_column)) < to_integer(p1_x_pos_internal) + to_integer(pipe_x_size) AND
                     (to_integer(unsigned(pixel_row)) < to_integer(p1_gap_center_internal) - 45 OR 
                      to_integer(unsigned(pixel_row)) > to_integer(p1_gap_center_internal) + 45))
             ELSE '0';

    p2_on <= '1' WHEN (p2_x_pos_internal + pipe_x_size > to_signed(0, 11) AND
                       to_integer(unsigned(pixel_column)) >= to_integer(p2_x_pos_internal) AND 
                       to_integer(unsigned(pixel_column)) < to_integer(p2_x_pos_internal) + to_integer(pipe_x_size) AND
                       (to_integer(unsigned(pixel_row)) < to_integer(p2_gap_center_internal) - 45 OR 
                        to_integer(unsigned(pixel_row)) > to_integer(p2_gap_center_internal) + 45))
                ELSE '0';

    p3_on <= '1' WHEN (p3_x_pos_internal + pipe_x_size > to_signed(0, 11) AND
                       to_integer(unsigned(pixel_column)) >= to_integer(p3_x_pos_internal) AND 
                       to_integer(unsigned(pixel_column)) < to_integer(p3_x_pos_internal) + to_integer(pipe_x_size) AND
                       (to_integer(unsigned(pixel_row)) < to_integer(p3_gap_center_internal) - 45 OR 
                        to_integer(unsigned(pixel_row)) > to_integer(p3_gap_center_internal) + 45))
                ELSE '0';

    Powerup_Display : PROCESS (clk, blue_box_visible, coin_active)
    BEGIN
        IF rising_edge(clk) THEN
            -- Handle Blue Box Display
            IF (blue_box_visible = '1' AND coin_active = '1') THEN
                IF (to_integer(unsigned(pixel_column)) >= to_integer(blue_box_x_pos_internal) AND 
                    to_integer(unsigned(pixel_column)) < to_integer(blue_box_x_pos_internal) + to_integer(blue_box_size) AND
                    to_integer(unsigned(pixel_row)) >= to_integer(blue_box_y_pos_internal) AND 
                    to_integer(unsigned(pixel_row)) < to_integer(blue_box_y_pos_internal) + to_integer(blue_box_size)) THEN
                    blue_box_on <= '1';
                    coin_address <= std_logic_vector(to_unsigned(
                        (to_integer(unsigned(pixel_row)) - to_integer(unsigned(blue_box_y_pos_internal))) * 32 +
                        (to_integer(unsigned(pixel_column)) - to_integer(unsigned(blue_box_x_pos_internal))), 10));
                    power_state <= 2;
                ELSE
                    blue_box_on <= '0';
                END IF;
            END IF;
            
            -- Handle Red Box Display
            IF (to_integer(unsigned(pixel_column)) >= to_integer(red_box_x_pos_internal) AND 
                to_integer(unsigned(pixel_column)) < to_integer(red_box_x_pos_internal) + to_integer(red_box_size) AND
                to_integer(unsigned(pixel_row)) >= to_integer(red_box_y_pos_internal) AND 
                to_integer(unsigned(pixel_row)) < to_integer(red_box_y_pos_internal) + to_integer(red_box_size)) THEN
                red_box_on <= '1';
                heart_address <= std_logic_vector(to_unsigned(
                    (to_integer(unsigned(pixel_row)) - to_integer(unsigned(red_box_y_pos_internal))) * 32 +
                    (to_integer(unsigned(pixel_column)) - to_integer(unsigned(red_box_x_pos_internal))), 10));
                power_state <= 1;
            ELSE
                red_box_on <= '0';
            END IF;
        END IF;
    END PROCESS Powerup_Display;
    
    PROCESS (blue_box_on, blue_box_visible, red_box_on, red_box_visible, coin_color, heart_color, p1_on, p2_on, p3_on)
    BEGIN
        IF blue_box_on = '1' AND coin_color /= "000100010001" THEN
            selected_color <= coin_color;
        ELSIF red_box_on = '1' AND red_box_visible = '1' THEN
            selected_color <= heart_color; -- Heart color
        ELSIF p1_on = '1' OR p2_on = '1' OR p3_on = '1' THEN
            selected_color <= "100010001000";
        ELSE
            selected_color <= "000000000000";
        END IF;
    END PROCESS;

    -- RGB and output enable logic
    RGB <= selected_color;
    output_on <= '1' WHEN selected_color /= "000000000000" ELSE '0';

    Move_pipe: PROCESS (vert_sync, blue_box_visible, red_box_visible)
        variable game_state : state_type;
    BEGIN
        IF rising_edge(vert_sync) THEN
            game_state := to_state_type(input_state);
            
            IF (game_state = RESET_GAME OR game_state = HOME) THEN
                -- Reset pipes to their original positions
                p1_x_pos_internal <= to_signed(213, 11);
                p1_gap_center_internal <= to_signed(240, 10);
                p2_x_pos_internal <= to_signed(426, 11);
                p2_gap_center_internal <= to_signed(360, 10);
                p3_x_pos_internal <= to_signed(640, 11);
                p3_gap_center_internal <= to_signed(100, 10);
                blue_box_x_pos_internal <= to_signed(1000, 11);
                blue_box_y_pos_internal <= to_signed(240, 10);
                red_box_x_pos_internal <= to_signed(800, 11);
                red_box_y_pos_internal <= to_signed(240, 10);
                coin_active <= '0';
                red_box_active <= '0';
                blue_box_visible <= '1'; -- Make the blue box visible again
                red_box_visible <= '1'; -- Make the red box visible again
				END IF;
            IF game_state = START THEN
                -- Move pipes
                IF (p1_x_pos_internal + pipe_x_size <= to_signed(0, 11)) THEN
                    p1_x_pos_internal <= to_signed(640, 11);
                    p1_gap_center_internal <= (signed(random_value) MOD to_signed(310, 10)) + to_signed(55, 10);
                    IF coin_active = '0' THEN
                        coin_active <= '1';
                        blue_box_x_pos_internal <= to_signed(640 + 50, 11); -- Coin appears 50 units after the pipe
                        blue_box_y_pos_internal <= (signed(random_value) MOD to_signed(310, 10)) + to_signed(55, 10);
                        blue_box_visible <= '1'; -- Make the blue box visible again
                    END IF;
                ELSE
                    p1_x_pos_internal <= p1_x_pos_internal - to_signed(1, 11);
                END IF;

                IF (p2_x_pos_internal + pipe_x_size <= to_signed(0, 11)) THEN
                    p2_x_pos_internal <= to_signed(640, 11);
                    p2_gap_center_internal <= (signed(random_value) MOD to_signed(310, 10)) + to_signed(55, 10);
                    IF coin_active = '0' THEN
                        coin_active <= '1';
                        blue_box_x_pos_internal <= to_signed(640 + 50, 11); -- Coin appears 50 units after the pipe
                        blue_box_y_pos_internal <= (signed(random_value) MOD to_signed(310, 10)) + to_signed(55, 10);
                        blue_box_visible <= '1'; -- Make the blue box visible again
                    END IF;
                ELSE
                    p2_x_pos_internal <= p2_x_pos_internal - to_signed(1, 11);
                END IF;

                IF (p3_x_pos_internal + pipe_x_size <= to_signed(0, 11)) THEN
                    p3_x_pos_internal <= to_signed(640, 11);
                    p3_gap_center_internal <= (signed(random_value) MOD to_signed(310, 10)) + to_signed(55, 10);
                    IF coin_active = '0' THEN
                        coin_active <= '1';
                        blue_box_x_pos_internal <= to_signed(640 + 50, 11); -- Coin appears 50 units after the pipe
                        blue_box_y_pos_internal <= (signed(random_value) MOD to_signed(310, 10)) + to_signed(55, 10);
                        blue_box_visible <= '1'; -- Make the blue box visible again
                    END IF;
                ELSE
                    p3_x_pos_internal <= p3_x_pos_internal - to_signed(1, 11);
                END IF;

                -- Move blue box (coin) independently if it is active
                IF coin_active = '1' THEN
                    IF blue_box_x_pos_internal + blue_box_size <= to_signed(0, 11) THEN
                        coin_active <= '0'; -- Coin moves off the screen and resets
								blue_box_visible <= '0';
                    ELSE
                        blue_box_x_pos_internal <= blue_box_x_pos_internal - to_signed(1, 11);
                    END IF;
                END IF;
                -- Move red box independently if it is active
                IF red_box_active = '1' THEN
                    IF red_box_x_pos_internal + red_box_size <= to_signed(0, 11) THEN
                        red_box_active <= '0'; -- Red box moves off the screen and resets
                    ELSE
                        red_box_x_pos_internal <= red_box_x_pos_internal - to_signed(1, 11);
                    END IF;
                ELSE
                    -- Activate red box at a random position
                    red_box_active <= '1';
                    red_box_x_pos_internal <= to_signed(640 + 100, 11); -- Red box appears 100 units after the pipe
                    red_box_y_pos_internal <= (signed(random_value) MOD to_signed(310, 10)) + to_signed(55, 10);
                    red_box_visible <= '1'; -- Make the red box visible again
                END IF;
            END IF;
            IF blue_box_visible = '1' AND (ball_x_pos + ball_size >= blue_box_x_pos_internal AND ball_x_pos <= blue_box_x_pos_internal + blue_box_size) AND 
               (ball_y_pos + ball_size >= blue_box_y_pos_internal AND ball_y_pos <= blue_box_y_pos_internal + blue_box_size) THEN
                blue_box_visible <= '0'; -- Make the blue box invisible when touched
            END IF;
            IF red_box_visible = '1' AND (ball_x_pos + ball_size >= red_box_x_pos_internal AND ball_x_pos <= red_box_x_pos_internal + red_box_size) AND 
               (ball_y_pos + ball_size >= red_box_y_pos_internal AND ball_y_pos <= red_box_y_pos_internal + red_box_size) THEN
                red_box_visible <= '0'; -- Make the red box invisible when touched
            END IF;
        END IF;
    END PROCESS Move_pipe;

    p1_x_pos <= p1_x_pos_internal;
    p1_gap_center <= p1_gap_center_internal;
    p2_x_pos <= p2_x_pos_internal;
    p2_gap_center <= p2_gap_center_internal;
    p3_x_pos <= p3_x_pos_internal;
    p3_gap_center <= p3_gap_center_internal;
    blue_box_x_pos <= blue_box_x_pos_internal;
    blue_box_y_pos <= blue_box_y_pos_internal;
    red_box_x_pos <= red_box_x_pos_internal;
    red_box_y_pos <= red_box_y_pos_internal;

END behavior;
