Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY espreset IS
PORT(
		XRST			: in std_logic;
		CLK49M		: in std_logic;
		ESPRST		: out std_logic
);
END espreset;

ARCHITECTURE RTL OF espreset IS

signal rstcnt : std_logic_vector(11 downto 0);
signal iesprst : std_logic;

BEGIN

process(CLK49M,xrst) begin
	if xrst = '0' then
		rstcnt <= "000000000000";
	elsif CLK49M'event and CLK49M='1' then
		if rstcnt = "111111111111" then
			rstcnt <= rstcnt;
		else
			rstcnt <= rstcnt + 1;
		end if;
	end if;
end process;

process(CLK49M,xrst,rstcnt) begin
	if xrst = '0' then
		iesprst <= '1';
	elsif CLK49M'event and CLK49M='1' then
		if rstcnt = "011111111111" then
			iesprst <= '0';
		elsif rstcnt = "111111111111" then
			iesprst <= '1';
		else
			iesprst <= iesprst;
		end if;
	end if;
end process;

esprst <= iesprst;

end RTL;
			
				