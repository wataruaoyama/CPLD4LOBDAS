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
		BCK			: in std_logic;
		CK_SEL		: out std_logic;
		FS				: out std_logic_vector(3 downto 0);
		DSD64_128	: out std_logic;
		DSD256_512	: out std_logic
);
END fs44_48;

ARCHITECTURE RTL OF fs44_48 IS

signal dlrck : std_logic;
signal fcount : unsigned(9 downto 0);--std_logic_vector(9 downto 0);
signal slrck : std_logic_vector(2 downto 0);
signal lach_en : std_logic;
signal f44_48 : std_logic;

signal dcount : std_logic_vector(3 downto 0);
signal dbck : std_logic_vector(2 downto 0);
signal ebck : std_logic;
signal d64_128	: std_logic;
signal d256_512 : std_logic;
signal iDSD64_128 : std_logic;


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

process(XRST,CLK49M,XDSD) begin
	if (XRST= '0' or XDSD = '0') then
		f44_48 <= '0';
		fs <= "0000";
	elsif CLK49M'event and CLK49M='1' then
		if lach_en = '1' then
			if (fcount >= to_unsigned(765, 10) and fcount <= to_unsigned(771, 10)) then		-- 32kHz
				f44_48 <= '1';
				fs <= "0000";
			elsif (fcount >= to_unsigned(509, 10) and fcount <= to_unsigned(515, 10)) then	-- 48kHz
				f44_48 <= '1';
				fs <= "0010";
			elsif (fcount >= to_unsigned(253, 10) and fcount <= to_unsigned(259, 10)) then	-- 96kHz
				f44_48 <= '1';
				fs <= "0100";
			elsif (fcount >= to_unsigned(125, 10) and fcount <= to_unsigned(131, 10)) then	-- 192kHz
				f44_48 <= '1';
				fs <= "0110";
			elsif (fcount >= to_unsigned(61, 10) and fcount <= to_unsigned(67, 10)) then		-- 384kHz
				f44_48 <= '1';
				fs <= "1000";
			elsif (fcount >= to_unsigned(29, 10) and fcount <= to_unsigned(33, 10)) then		-- 768kHz
				f44_48 <= '1';
			elsif (fcount >= to_unsigned(554, 10) and fcount <= to_unsigned(561, 10)) then	-- 44.1kHz
				f44_48 <= '0';
				fs <= "0001";
			elsif (fcount >= to_unsigned(276, 10) and fcount <= to_unsigned(282, 10)) then	-- 88kHz
				f44_48 <= '0';
				fs <= "0011";
			elsif (fcount >= to_unsigned(136, 10) and fcount <= to_unsigned(142, 10)) then	-- 176.4kHz
				f44_48 <= '0';
				fs <= "0101";
			elsif (fcount >= to_unsigned(68, 10) and fcount <= to_unsigned(72, 10)) then		--352.8kHz
				f44_48 <= '0';
				fs <= "0111";
			elsif (fcount >= to_unsigned(34, 10) and fcount <= to_unsigned(38, 10)) then		-- 705.6kHz
				f44_48 <= '0';	
			end if;
		end if;
	end if;
end process;

CK_SEL <= f44_48;

process(CLK49M) begin
	if CLK49M'event and CLK49M='1' then
		dbck <= dbck(1 downto 0) & BCK;
	end if;
end process;

ebck <= dbck(2) and not dbck(1);

process(XRST,CLK49M,XDSD) begin
	if XRST = '0' or XDSD = '1' then
		dcount <= "0000";
	elsif CLK49M'event and CLK49M='1' then
		if dbck(2) = '0' then
			dcount <= "0000";
		else
			dcount <= dcount + '1';
		end if;
	end if;
end process;

process(XRST,CLK49M,dcount) begin
	if XRST = '0' then
		d256_512 <= '0';
		d64_128 <= '0';
	elsif CLK49M'event and CLK49M='1' then
		if ebck = '1' then
			if dcount = "0000" then			-- DSD512
				d256_512 <= '1';
				d64_128 <= '1';
			elsif dcount = "0010" then		-- DSD256
				d256_512 <= '1';
				d64_128 <= '0';
			elsif dcount = "0100" then		-- DSD128
				d256_512 <= '0';
				d64_128 <= '1';
			elsif dcount = "1000" then		-- DSD64
				d256_512 <= '0';
				d64_128 <= '0';
			end if;
		end if;
	end if;
end process;

DSD64_128 <= d64_128;
DSD256_512 <= d256_512;

end RTL;
			
				