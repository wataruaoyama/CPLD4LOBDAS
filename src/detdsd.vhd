Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY detdsd IS
PORT(
		xrst			: in std_logic;
		mclk			: in std_logic;
		bclk			: in std_logic;
		lrck			: in std_logic;
		dp				: out std_logic
);
END detdsd;

ARCHITECTURE RTL OF detdsd IS

signal dp_int	: std_logic;
signal cnt		: std_logic_vector(2 downto 0);
signal count	: std_logic_vector(4 downto 0);
signal sreg		: std_logic_vector(15 downto 0);

BEGIN

process(bclk) begin
	if(bclk'event and bclk = '1') then
		sreg <= sreg(14 downto 0) & lrck;
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

process (bclk,xrst) begin
	if xrst = '0' then
		cnt <= "000";
	elsif bclk'event and bclk= '1' then
		if count = "11111" then
			cnt <= cnt + 1;
		elsif cnt = "011" then
			cnt <= "000";
		else
			cnt <= cnt;
		end if;
	end if;
end process;


process(bclk,xrst) begin
	if xrst = '0' then
		dp_int <= '0';
	elsif bclk'event and bclk = '1' then
		if dp_int = '0' then
			if sreg = "0110100101101001" then
				dp_int <= '1';
			elsif sreg = "0101010101010101" then
				dp_int <= '1';
			elsif sreg = "0011001100110011" then
				dp_int <= '1';
			else
				dp_int <= dp_int;
			end if;
		elsif dp_int = '1' then
--			if count = "11111" then
			if cnt = "011" then
				dp_int <= '0';
			else
				dp_int <= dp_int;
			end if;
		end if;
	end if;
end process;

dp <= dp_int;

end RTL;