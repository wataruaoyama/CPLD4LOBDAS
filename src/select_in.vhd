Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY select_in IS
PORT(
		xrst		: in std_logic;
		INSELO	: in std_logic_vector(1 downto 0);
		BBB_MCLK	: in std_logic;
		BBB_BCLK	: in std_logic;
		BBB_LRCK	: in std_logic;
		BBB_DATA	: in std_logic;
		RJ4_DATA	: in std_logic;
		RJ4_BCLK	: in std_logic;
		RJ4_LRCK	: in std_logic;
		RJ4_MCLK	: in std_logic;
		USB_DATA	: in std_logic;
		USB_BCLK	: in std_logic;
		USB_LRCK	: in std_logic;
		USB_MCLK	: in std_logic;
		USB_FS	: in std_logic_vector(3 downto 0);
		USB_DP	: in std_logic;
		USB_D64	: in std_logic;
		DET_FS	: in std_logic_vector(3 downto 0);
--		DET_DP	: in std_logic;
		DET_D256	: in std_logic;
		DET_D64	: in std_logic;
		CHLR		: in std_logic;
		LRCK1		: out std_logic;
		DATA1		: out std_logic;
		BCLK1		: out std_logic;
		MCLK1		: out std_logic;
		LRCK2		: out std_logic;
		DATA2		: out std_logic;
		BCLK2		: out std_logic;
		MCLK2		: out std_logic;
		FS			: out std_logic_vector(3 downto 0);
		DP			: out std_logic;
		D256_512	: out std_logic;
		D64_128	: out std_logic
	);
END select_in;

ARCHITECTURE RTL OF select_in IS

component detdsd
PORT(
		xrst			: in std_logic;
--		mclk			: in std_logic;
		bclk			: in std_logic;
		lrck			: in std_logic;
		dp				: out std_logic
);
END component;

signal iMCLK1,iBCLK1,iLRCK1,iDATA1	: std_logic;
signal iMCLK2,iBCLK2,iLRCK2,iDATA2	: std_logic;
signal DET_DP : std_logic;

BEGIN

D1 : detdsd port map(xrst=>xrst, bclk=>iBCLK1, lrck=>iLRCK1, dp=>DET_DP);

process(BBB_MCLK,BBB_BCLK,BBB_LRCK,BBB_DATA,RJ4_MCLK,RJ4_BCLK,RJ4_LRCK,RJ4_DATA,
		  USB_MCLK,USB_BCLK,USB_LRCK,USB_DATA,INSELO) begin
	if inselo = "00" then
		if USB_DP = '1' then
			iMCLK1 <= USB_MCLK;
			iMCLK2 <= USB_MCLK;
			iBCLK1 <= USB_BCLK;
			iBCLK2 <= USB_BCLK;
			iLRCK1 <= USB_DATA;
			iLRCK2 <= USB_DATA;
			iDATA1 <= USB_LRCK;
			iDATA2 <= USB_LRCK;
		else
			iMCLK1 <= USB_MCLK;
			iMCLK2 <= USB_MCLK;
			iBCLK1 <= USB_BCLK;
			iBCLK2 <= USB_BCLK;
			iLRCK1 <= USB_LRCK;
			iLRCK2 <= USB_LRCK;
			iDATA1 <= USB_DATA;
			iDATA2 <= USB_DATA;
		end if;
	elsif inselo = "01" then
		iMCLK1 <= RJ4_MCLK;
		iMCLK2 <= RJ4_MCLK;
		iBCLK1 <= RJ4_BCLK;
		iBCLK2 <= RJ4_BCLK;
		iLRCK1 <= RJ4_LRCK;
		iLRCK2 <= RJ4_LRCK;
		iDATA1 <= RJ4_DATA;
		iDATA2 <= RJ4_DATA;
	elsif inselo = "10" then
		iMCLK1 <= BBB_MCLK;
		iMCLK2 <= BBB_MCLK;
		iBCLK1 <= BBB_BCLK;
		iBCLK2 <= BBB_BCLK;
		iLRCK1 <= BBB_LRCK;
		iLRCK2 <= BBB_LRCK;
		iDATA1 <= BBB_DATA;
		iDATA2 <= BBB_DATA;
	elsif inselo = "11" then
		iMCLK1 <= USB_MCLK;
		iMCLK2 <= USB_MCLK;
		iBCLK1 <= USB_BCLK;
		iBCLK2 <= USB_BCLK;
		iLRCK1 <= USB_LRCK;
		iLRCK2 <= USB_LRCK;
		iDATA1 <= USB_DATA;
		iDATA2 <= USB_DATA;
	end if;
end process;

process (iLRCK1,iDATA1,iLRCK2,iDATA2,DET_DP,CHLR) begin
	if CHLR = '1' then
		LRCK1 <= iLRCK1;
		LRCK2 <= iLRCK2;
		DATA1 <= iDATA1;
		DATA2 <= iDATA2;
	else
		if DET_DP = '0' then
			LRCK1 <= iLRCK1;
			LRCK2 <= iLRCK2;
			DATA1 <= iDATA1;
			DATA2 <= iDATA2;
		else
			LRCK1 <= iDATA1;
			LRCK2 <= iDATA2;
			DATA1 <= iLRCK1;
			DATA2 <= iLRCK2;
		end if;
	end if;
end process;

MCLK1 <= iMCLK1;
BCLK1 <= iBCLK1;
MCLK2 <= iMCLK2;
BCLK2 <= iBCLK2;
--LRCK1 <= iLRCK1;
--LRCK2 <= iLRCK2;
--DATA1 <= iDATA1;
--DATA2 <= iDATA2;

--process(USB_FS,USB_DP,DET_FS,DET_D256,DET_D64,DET_DP,INSELO) begin
--	if inselo = "00" or inselo = "11" then
--		FS <= USB_FS;
--		DP <= USB_DP;
--		D256_512 <= DET_D256;
--		D64_128 <= DET_D64;
--	elsif inselo = "01" or inselo = "10" then
--		FS <= DET_FS;
--		DP <= DET_DP;
--		D256_512 <= DET_D256;
--		D64_128 <= DET_D64;
--	else
--		FS <= USB_FS;
--		DP <= USB_DP;
--		D256_512 <= DET_D256;
--		D64_128 <= DET_D64;
--	end if;
--end process;

FS <= DET_FS;
DP <= DET_DP or USB_DP;
D256_512 <= DET_D256;
D64_128 <= DET_D64;
		
end RTL;
			
				