Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY fs44_48 IS
PORT(
		XRST			: in std_logic;
		CLK49M		: in std_logic;
		XDSD			: in std_logic;
		LRCK			: in std_logic;
		CK_SEL		: out std_logic
);
END fs44_48;

ARCHITECTURE RTL OF fs44_48 IS

signal dlrck : std_logic;
signal fcount : std_logic_vector(9 downto 0);
signal slrck : std_logic_vector(2 downto 0);
signal lach_en : std_logic;
signal f44_48 : std_logic;

BEGIN

process(CLK49M,slrck) begin
	if CLK49M'event and CLK49M='1' then
		slrck <= slrck(1 downto 0) & lrck;
	end if;
end process;

dlrck <= slrck(2);
	
process(XRST,CLK49M,XDSD) BEGIN
	if(XRST = '0' or XDSD = '0') then
		fcount <= "0000000000";
	elsif(CLK49M'event and CLK49M='1') then
		if dlrck = '1' then
			fcount <= fcount + '1';
		else
			fcount <= "0000000000";
		end if;
	end if;
end process;

lach_en <= not slrck(1) and slrck(2);

process(XRST,CLK49M,XDSD) begin
	if (XRST= '0' or XDSD = '0') then
		f44_48 <= '0';
	elsif CLK49M'event and CLK49M='1' then
		if lach_en = '1' then
			if (fcount = "0111111110" or fcount = "0111111111" or fcount = "1000000000" or fcount = "1000000001") then
				f44_48 <= '1';
			elsif (fcount = "0011111110" or fcount = "0011111111" or fcount = "0100000000" or fcount = "0100000001") then
				f44_48 <= '1';
			elsif (fcount = "0001111110" or fcount = "0001111111" or fcount = "0010000000" or fcount = "0010000001") then
				f44_48 <= '1';
			elsif (fcount = "0000111110" or fcount = "0000111111" or fcount = "0010000000" or fcount = "0001000001") then
				f44_48 <= '1';
			elsif (fcount = "0000011110" or fcount = "0000011111" or fcount = "0001000000" or fcount = "0000100001") then
				f44_48 <= '1';
--			elsif (fcount = "1000101010" or fcount = "1000101011" or fcount = "1000101100" or fcount = "1000101101" or fcount = "1000101110" or fcount = "1000101111") then
			elsif (fcount = "1000101011" or fcount = "1000101100" or fcount = "1000101101" or fcount = "1000101110") then
				f44_48 <= '0';
			elsif (fcount = "0100010101" or fcount = "0100010110" or fcount = "0100010110" or fcount = "0100010111") then
				f44_48 <= '0';
			elsif (fcount = "0010001010" or fcount = "0010001011" or fcount = "0010001011" or fcount = "0010001011") then
				f44_48 <= '0';
			elsif (fcount = "0001000101" or fcount = "0001000101" or fcount = "0001000101" or fcount = "0001000101") then
				f44_48 <= '0';
			elsif (fcount = "0000100010" or fcount = "0000100010" or fcount = "0000100010" or fcount = "0000100010") then
				f44_48 <= '0';	
			end if;
		end if;
	end if;
end process;

CK_SEL <= f44_48;

end RTL;
			
				