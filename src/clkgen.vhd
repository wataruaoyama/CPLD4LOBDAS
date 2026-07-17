Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY clkgen IS
PORT(
		xrst			: in std_logic;
		clk			: in std_logic;
		clk_msec		: OUT std_logic
);
END clkgen;

ARCHITECTURE RTL OF clkgen IS

signal counter_msec : std_logic_vector(15 downto 0);

constant sim : integer := 0;

BEGIN

--Generate 1msec timer
COMPILE : if sim /= 1 generate
process(xrst,CLK) begin
	if(xrst = '0') then
		counter_msec <= "0000000000000000";
		clk_msec <= '0';
	elsif(CLK'event and CLK='1') then
		if counter_msec = "1001110001000000" then
			counter_msec <= "0000000000000000";
			CLK_msec <= '1';
		else
			counter_msec <= counter_msec + '1';
			clk_msec <= '0';
		end if;
	end if;
end process;
end generate;

SIMULATION : if sim = 1 generate
process(xrst,CLK) begin
	if(xrst = '0') then
		counter_msec <= "0000000000000000";
		clk_msec <= '0';
	elsif(CLK'event and CLK='1') then
		if counter_msec = "000000000100111" then
			counter_msec <= "0000000000000000";
			CLK_msec <= '1';
		else
			counter_msec <= counter_msec + '1';
			clk_msec <= '0';
		end if;
	end if;
end process;
end generate;

end RTL;