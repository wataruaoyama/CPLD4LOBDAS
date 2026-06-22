Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE IEEE.numeric_std.ALL;

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
signal fcount : unsigned(9 downto 0);--std_logic_vector(9 downto 0);
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
			fcount <= fcount + 1;
		else
			fcount <= "0000000000";
		end if;
	end if;
end process;

lach_en <= not slrck(1) and slrck(2);

--修正後--
process(XRST,CLK49M,XDSD) begin
	if (XRST= '0' or XDSD = '0') then
		f44_48 <= '0';
	elsif CLK49M'event and CLK49M='1' then
		if lach_en = '1' then
			if (fcount >= to_unsigned(509, 10) and fcount <= to_unsigned(515, 10)) then	
--			if (fcount = "0111111110" or fcount = "0111111111" or fcount = "1000000000" or fcount = "1000000001") then	
				f44_48 <= '1';
			elsif (fcount >= to_unsigned(253, 10) and fcount <= to_unsigned(259, 10)) then	
--			elsif (fcount = "0011111110" or fcount = "0011111111" or fcount = "0100000000" or fcount = "0100000001") then
				f44_48 <= '1';
			elsif (fcount >= to_unsigned(125, 10) and fcount <= to_unsigned(131, 10)) then	
--			elsif (fcount = "0001111101" or fcount = "0001111110" or fcount = "0001111111" or fcount = "0010000000" or fcount = "0010000001" or fcount = "0010000010" or fcount = "0010000011") then	-- 192kHz
				f44_48 <= '1';
			elsif (fcount >= to_unsigned(61, 10) and fcount <= to_unsigned(67, 10)) then	
--			elsif (fcount = "0000111110" or fcount = "0000111111" or fcount = "0001000000" or fcount = "0001000001") then
				f44_48 <= '1';
			elsif (fcount >= to_unsigned(29, 10) and fcount <= to_unsigned(33, 10)) then	
--			elsif (fcount = "0000011110" or fcount = "0000011111" or fcount = "0000100000" or fcount = "0000100001") then
				f44_48 <= '1';
--			elsif (fcount = "1000101010" or fcount = "1000101011" or fcount = "1000101100" or fcount = "1000101101" or fcount = "1000101110" or fcount = "1000101111") then
			elsif (fcount >= to_unsigned(555, 10) and fcount <= to_unsigned(561, 10)) then	
--			elsif (fcount = "1000101011" or fcount = "1000101100" or fcount = "1000101101" or fcount = "1000101110") then
				f44_48 <= '0';
			elsif (fcount >= to_unsigned(276, 10) and fcount <= to_unsigned(282, 10)) then	
--			elsif (fcount = "0100010101" or fcount = "0100010110" or fcount = "0100010110" or fcount = "0100010111") then
				f44_48 <= '0';
			elsif (fcount >= to_unsigned(136, 10) and fcount <= to_unsigned(142, 10)) then	
--			elsif (fcount = "0010001010" or fcount = "0010001011" or fcount = "0010001100" or fcount = "0010001101") then	-- 176.4kHz
				f44_48 <= '0';
			elsif (fcount >= to_unsigned(68, 10) and fcount <= to_unsigned(72, 10)) then	
--			elsif (fcount = "0001000101" or fcount = "0001000110" or fcount = "0001000111" or fcount = "0001001000") then	-- 352.8kHz
				f44_48 <= '0';
			elsif (fcount >= to_unsigned(34, 10) and fcount <= to_unsigned(38, 10)) then	
--			elsif (fcount = "0000100010" or fcount = "0000100011" or fcount = "0000100100" or fcount = "0000100101") then	-- 705.6kHz
				f44_48 <= '0';	
			end if;
		end if;
	end if;
end process;

CK_SEL <= f44_48;

end RTL;
			
				