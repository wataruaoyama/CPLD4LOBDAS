Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY detdsd IS
PORT(
		xrst			: in std_logic;
--		mclk			: in std_logic;
		bclk			: in std_logic;
		lrck			: in std_logic;
		dp				: out std_logic
);
END detdsd;

ARCHITECTURE RTL OF detdsd IS

signal dp_int	: std_logic;
signal count	: std_logic_vector(4 downto 0);
signal sreg		: std_logic_vector(31 downto 0);

BEGIN

process(bclk) begin
	if(bclk'event and bclk = '1') then
		sreg <= sreg(30 downto 0) & lrck;
	end if;
end process;

process(bclk,xrst) begin
	if xrst = '0' then
		count <= "00000";
	elsif bclk'event and bclk = '1' then
		if dp_int = '1' then
			if lrck = '1' then
				count <= count + 1;
			else
				count <= "00000";
			end if;
		end if;
	end if;
end process;


process(bclk,xrst) begin
	if xrst = '0' then
		dp_int <= '0';
	elsif bclk'event and bclk = '1' then
		if dp_int = '0' then
			if sreg = "01101001011010100110100101101010" then
				dp_int <= '1';
			elsif sreg = "01010101010101010101010101010101" then
				dp_int <= '1';
			elsif sreg = "00110011001100110011001100110011" then
				dp_int <= '1';
			else
				dp_int <= dp_int;
			end if;
		elsif dp_int = '1' then
			if count = "11111" then
				dp_int <= '0';
			else
				dp_int <= dp_int;
			end if;
		end if;
	end if;
end process;

dp <= dp_int;

end RTL;