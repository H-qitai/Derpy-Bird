library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.game_type_pkg.ALL;

entity Game_FSM is
    PORT(
        clk, pb2, pb3, pb4, dead : IN STD_LOGIC;
        state_out: OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
end entity Game_FSM;

architecture structural of Game_FSM is
    signal game_state : state_type := HOME;
    signal prev_pb2 : std_logic := '1';
    signal s_pause, s_start, s_reset : std_logic := '0';

begin

    s_start <= not pb3;
    s_reset <= not pb4;

    -- Process to select state
    output_state_decode : process (clk)
    begin
        if rising_edge(clk) then
            case game_state is
                when HOME =>
                    if (s_start = '1') then
                        game_state <= START;
                    else
                        game_state <= HOME;
                    end if;
                when START =>
                    if (s_reset = '1') then
                        game_state <= HOME;
                    elsif (s_pause = '1') then
                        game_state <= PAUSE;
                    elsif (dead = '1') then
                        game_state <= GAME_END;
                    else
                        game_state <= START;
                    end if;
                when PAUSE =>
                    if (s_pause = '0') then
                        game_state <= START;
                    else
                        game_state <= PAUSE;
                    end if;
                when GAME_END =>
                    if (s_reset = '1') then
                        game_state <= HOME;
                    else
                        game_state <= GAME_END;
                    end if;
                when others =>
                    game_state <= HOME;
            end case;
            state_out <= to_slv(game_state);
        end if;
    end process;

    -- Process to handle pause button (pb2)
    Pb_Check : process (clk)
    begin
        if rising_edge(clk) then
            if (pb2 = '0' and prev_pb2 = '1' and (game_state = START OR game_state = PAUSE)) then
                s_pause <= not s_pause;
            end if;
            prev_pb2 <= pb2;
        end if;
    end process;

end architecture structural;
