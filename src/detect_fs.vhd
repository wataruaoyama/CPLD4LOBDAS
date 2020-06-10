Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY detect_fs IS
PORT(
		CLK49M		: in std_logic;
		XDSD			: in std_logic;
		MCLK			: in std_logic;
		BCK			: in std_logic;
		LRCK			: in std_logic;
		CK_SEL		: in std_logic;
		CPOK			: IN std_logic;
		DSD64_128	: OUT std_logic;
		DSD256_512	: OUT std_logic;
		FS				: OUT std_logic_vector(3 downto 0));
END detect_fs;

ARCHITECTURE RTL OF detect_fs IS

signal slrck : std_logic;
signal d64_128,d256_512,iDSD64_128,cken : std_logic;
signal fcount : std_logic_vector(8 downto 0);
signal q,f : std_logic_vector(3 downto 0);
signal sreg : std_logic_vector(1 downto 0);
signal dcount : std_logic_vector(3 downto 0);
signal dbck : std_logic_vector(2 downto 0);
signal ebck : std_logic;

BEGIN

process(MCLK) begin
	if MCLK'event and MCLK='1' then
		sreg <= sreg(0) & LRCK;
	end if;
end process;

slrck <= sreg(1);

process(CPOK,MCLK,XDSD) BEGIN
	if(CPOK = '0' or XDSD = '0') then
		fcount <= "000000000";
	elsif(MCLK'event and MCLK='1') then
		if slrck = '1' then
			fcount <= fcount + '1';
		else
			fcount <= "000000000";
		end if;
	end if;
end process;

process(CPOK,XDSD,fcount,CK_SEL) begin
	if(CPOK = '0' or XDSD = '0') then
		q <= "0000";
	else	
		if CK_SEL = '0' then
			case fcount is
				when "011111111" => q <= "0001";	--44.1kHz
				when "001111111" => q <= "0011";	--88.2kHz
				when "000111111" => q <= "0101";	--176.4kHz
				when "000011111" => q <= "0111";	--352.8kHz
				when others => q <= "XXXX";
			end case;
		else
			case fcount is
				when "101111111" => q <= "0000";	--32kHz
				when "011111111" => q <= "0010";	--48kHz
				when "001111111" => q <= "0100";	--96kHz
				when "000111111" => q <= "0110";	--192kHz
				when "000011111" => q <= "1000";	--384kHz
				When others => q <= "XXXX";
			end case;
		end if;
	end if;
end process;

cken <= sreg(1) and not sreg(0);

process(MCLK) begin
	if MCLK'event and MCLK='0' then
		if cken = '1' then
			if q="0000" then
				f <= "0000";
			elsif q="0001" then
				f <= "0001";
			elsif q="0010" then
				f <= "0010";
			elsif q="0011" then
				f <= "0011";
			elsif q="0100" then
				f <= "0100";
			elsif q="0101" then
				f <= "0101";
			elsif q="0110" then
				f <= "0110";
			elsif q="0111" then
				f <= "0111";
			elsif q="1000" then
				f <= "1000";
			end if;
		else
			f <= f;
		end if;
	end if;
end process;

FS <= f;

process(CLK49M) begin
	if CLK49M'event and CLK49M='1' then
		dbck <= dbck(1 downto 0) & BCK;
	end if;
end process;

ebck <= dbck(2) and not dbck(1);

process(CPOK,CLK49M,XDSD) begin
	if CPOK = '0' or XDSD = '1' then
		dcount <= "0000";
	elsif CLK49M'event and CLK49M='1' then
		if dbck(2) = '0' then
			dcount <= "0000";
		else
			dcount <= dcount + '1';
		end if;
	end if;
end process;

--process(MCLK) begin
--	if MCLK'event and MCLK='1' then
--		dbck <= dbck(1 downto 0) & BCK;
--	end if;
--end process;
--
--ebck <= dbck(2) and not dbck(1);
--
--process(CPOK,MCLK,XDSD) begin
--	if CPOK = '0' or XDSD = '1' then
--		dcount <= "0000";
--	elsif MCLK'event and MCLK='1' then
--		if dbck(2) = '0' then
--			dcount <= "0000";
--		else
--			dcount <= dcount + '1';
--		end if;
--	end if;
--end process;

--process(CPOK,MCLK) begin
--	if CPOK = '0' then
--		d64_128 <= '0';
--	elsif MCLK'event and MCLK='1' then
--		if ebck = '1' then
--			if dcount = "0001" then
--				d64_128 <= '1';
--			elsif dcount = "0011" then
--				d64_128 <= '0';
--			end if;
--		else
--			d64_128 <= d64_128;
--		end if;
--	end if;
--end process;

process(CPOK,CLK49M,dcount) begin
	if CPOK = '0' then
		d256_512 <= '0';
		d64_128 <= '0';
	elsif CLK49M'event and CLK49M='1' then
		if ebck = '1' then
			if dcount = "0000" then			-- DSD512
				d256_512 <= '1';
				d64_128 <= '1';
			elsif dcount = "0010" then		-- DSD256
--			if dcount = "0010" then		-- DSD256
				d256_512 <= '1';
				d64_128 <= '0';
			elsif dcount = "0100" then		-- DSD128
				d256_512 <= '0';
				d64_128 <= '1';
			elsif dcount = "1000" then		-- DSD64
				d256_512 <= '0';
				d64_128 <= '0';
			end if;
		else
			d256_512 <= d256_512;
			d64_128 <= d64_128;
		end if;
	end if;
end process;

DSD64_128 <= d64_128;
DSD256_512 <= d256_512;

end RTL;
			
				