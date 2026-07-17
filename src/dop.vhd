Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY dop IS
PORT(
		xrst			: in std_logic;
		mclk			: in std_logic;
		bclk			: in std_logic;
		lrck			: in std_logic;
		data			: in std_logic;
		bckdsdclk	: out std_logic;
		lrck_dsdr	: out std_logic;
		data_dsdl	: out std_logic
);
END dop;

ARCHITECTURE RTL OF dop IS

signal mrk,detmrk,dp			: std_logic;
signal mrkrcnt,mrklcnt		: std_logic_vector(4 downto 0);
signal dsdclk					: std_logic;
signal dsdr,dsdl				: std_logic;
signal div						: std_logic_vector(1 downto 0);
signal count					: std_logic_vector(5 downto 0);
signal detcnt					: std_logic_vector(5 downto 0);
signal sreg						: std_logic_vector(23 downto 0);
signal dsdregl,p2sl			: std_logic_vector(15 downto 0);
signal dsdregr,p2sr			: std_logic_vector(15 downto 0);
signal delay8					: std_logic_vector(7 downto 0);
signal dsdzero					: std_logic;
signal selzero					: std_logic;
signal zerocnt					: std_logic_vector(6 downto 0);
signal ddp						: std_logic;

BEGIN

process(bclk) begin
	if(bclk'event and bclk = '1') then
		sreg <= sreg(22 downto 0) & data;
	end if;
end process;

process(bclk,lrck) begin
	if lrck = '0' then
		mrkrcnt <= "00000";
	elsif bclk'event and bclk='1' then
		mrkrcnt <= mrkrcnt +1;
	end if;
end process;

process(bclk,lrck) begin
	if lrck = '1' then
		mrklcnt <= "00000";
	elsif bclk'event and bclk='1' then
		mrklcnt <= mrklcnt + 1;
	end if;
end process;

process(bclk,xrst) begin
	if xrst = '0' then
		detmrk <= '0';
	elsif bclk'event and bclk= '1' then
		if mrklcnt = "11001" or mrkrcnt = "11001" then
			detmrk <= '1';
		else
			detmrk <= '0';
		end if;
	end if;
end process;
			

--process(bclk,xrst) begin
--	if xrst = '0' then
--		mrk <= '0';
--	elsif bclk'event and bclk = '1' then
--		if sreg(23 downto 16) = "00000101" then
--			if lrck = '0' then
--				mrk <= '1';
--				dsdregl <= sreg(15 downto 0);
--			else
--				mrk <= '1';
--				dsdregr <= sreg(15 downto 0);
--			end if;
--		elsif sreg(23 downto 16) = "11111010" then
--			if lrck = '0' then
--				mrk <= '1';
--				dsdregl <= sreg(15 downto 0);
--			else
--				mrk <= '1';
--				dsdregr <= sreg(15 downto 0);
--			end if;
--		else
--			mrk <= '0';
--		end if;
--	end if;
--end process;

process(bclk,xrst) begin
	if xrst = '0' then
		mrk <= '0';
	elsif bclk'event and bclk = '1' then
		if lrck = '0' and mrklcnt = "11001" then
			if sreg(23 downto 16) = "00000101" then
				mrk <= '1';
				dsdregl <= sreg(15 downto 0);
			elsif sreg(23 downto 16) = "11111010" then
				mrk <= '1';
				dsdregl <= sreg(15 downto 0);
			end if;
		elsif lrck = '1' and mrkrcnt = "11001" then
			if sreg(23 downto 16) = "00000101" then
				mrk <= '1';
				dsdregr <= sreg(15 downto 0);
			elsif sreg(23 downto 16) = "11111010" then
				mrk <= '1';
				dsdregr <= sreg(15 downto 0);
			end if;
		else
			mrk <= '0';
		end if;
	end if;
end process;

process(bclk,xrst,detmrk,mrk,count) begin
	if xrst = '0' then
		dp <= '0';
		count <= "000000";
	elsif bclk'event and bclk='1' then
		if (detmrk = '1' and mrk = '1')then
			count <= count + '1';
		elsif (detmrk = '1' and mrk = '0') then
			dp <= '0';
			count <= "000000";
		elsif count = "000100" then
			dp <= '1';
			count <= "000000";
		end if;
	else
		count <= count;
	end if;
end process;

process(dsdclk) begin
	if dsdclk'event and dsdclk='0' then
		ddp <= dp;
	end if;
end process;
	

process(bclk,xrst) begin
	if xrst = '0' then
		div <= "00";
	elsif bclk'event and bclk='1' then
		div <= div + '1';
	end if;
end process;

dsdclk <= div(1);

process(dsdclk,mrk,lrck,dsdregl(15 downto 0),dsdregr(15 downto 0)) begin
	if (mrk = '1' and lrck = '0') then
		p2sl <= dsdregl(15 downto 0);
	elsif (mrk = '1' and lrck = '1') then
		p2sr <= dsdregr(15 downto 0);
	elsif dsdclk'event and dsdclk='0' then
		p2sl <= p2sl(14 downto 0) & p2sl(15);
		p2sr <= P2sr(14 downto 0) & p2sr(15);
	end if;
end process;

--insert DSD Zero DATA
process(dsdclk) begin
	if ddp = '0' then
		dsdzero <= '0';
	elsif dsdclk'event and dsdclk='0' then
		dsdzero <= not dsdzero;
	end if;
end process;

process(dsdclk) begin
	if ddp = '0' then
		selzero <= '0';
		zerocnt <= "0000000";
	elsif dsdclk'event and dsdclk= '1' then
		if zerocnt = "0001000" then
			selzero <= '0';
			zerocnt <= zerocnt;
		else
			selzero <= '1';
			zerocnt <= zerocnt + 1;
		end if;
	end if;
end process;

dsdr <= p2sr(15) when selzero = '0' else dsdzero;
--

process(dsdclk) begin
	if dsdclk'event and dsdclk='0' then
		delay8 <= delay8(6 downto 0) & p2sl(15);
	end if;
end process;

dsdl <= delay8(7);

lrck_dsdr <= lrck when ddp = '0' else dsdr;
data_dsdl <= data when ddp = '0' else dsdl;
bckdsdclk <= bclk when ddp = '0' else dsdclk;


end RTL;