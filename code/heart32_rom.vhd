LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE IEEE.NUMERIC_STD.all;

LIBRARY altera_mf;
USE altera_mf.all;

ENTITY heart32_rom IS
    PORT
    (
        clk             :   IN STD_LOGIC;
        heart32_address  :   IN STD_LOGIC_VECTOR(9 DOWNTO 0);
        heart32_color        :   OUT STD_LOGIC_VECTOR(11 DOWNTO 0) -- Updated to 12 bits
    );
END heart32_rom;

ARCHITECTURE HEART32_SYN OF heart32_rom IS

    COMPONENT altsyncram
    GENERIC (
        address_aclr_a          : STRING;
        clock_enable_input_a    : STRING;
        clock_enable_output_a   : STRING;
        init_file               : STRING;
        intended_device_family  : STRING;
        lpm_hint                : STRING;
        lpm_type                : STRING;
        numwords_a              : NATURAL;
        operation_mode          : STRING;
        outdata_aclr_a          : STRING;
        outdata_reg_a           : STRING;
        widthad_a               : NATURAL;
        width_a                 : NATURAL;
        width_byteena_a         : NATURAL
    );
    PORT (
        clock0      : IN STD_LOGIC ;
        address_a   : IN STD_LOGIC_VECTOR (9 DOWNTO 0);
        q_a         : OUT STD_LOGIC_VECTOR (11 DOWNTO 0) -- Updated to 12 bits
    );
    END COMPONENT;

BEGIN
    COIN_ROM1 : altsyncram
    GENERIC MAP (
        address_aclr_a => "NONE",
        clock_enable_input_a => "BYPASS",
        clock_enable_output_a => "BYPASS",
        init_file => "heart32.MIF", -- Heart32 MIF file with 12 bit color depth
        intended_device_family => "Cyclone V",
        lpm_hint => "ENABLE_RUNTIME_MOD=NO",
        lpm_type => "altsyncram",
        numwords_a => 1024, -- Depth of address
        operation_mode => "ROM",
        outdata_aclr_a => "NONE",
        outdata_reg_a => "UNREGISTERED",
        widthad_a => 10, -- Since depth of address is 1024, we need 2^10
        width_a => 12, -- 12-bit color
        width_byteena_a => 1
    )
    PORT MAP (
        clock0 => clk,
        address_a => heart32_address,
        q_a => heart32_color
    );

END HEART32_SYN;
