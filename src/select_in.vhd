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
		DET_DP	: in std_logic;
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

BEGIN
process(BBB_MCLK,BBB_BCLK,BBB_LRCK,BBB_DATA,RJ4_MCLK,RJ4_BCLK,RJ4_LRCK,RJ4_DATA,
		  USB_MCLK,USB_BCLK,USB_LRCK,USB_DATA,INSELO,CHLR,USB_DP) begin
	if inselo = "00" then
		if CHLR = '0' then		
			MCLK1 <= USB_MCLK;
			MCLK2 <= USB_MCLK;
			BCLK1 <= USB_BCLK;
			BCLK2 <= USB_BCLK;
			LRCK1 <= USB_LRCK;
			LRCK2 <= USB_LRCK;
			DATA1 <= USB_DATA;
			DATA2 <= USB_DATA;
		else
			if USB_DP = '1' then
				MCLK1 <= USB_MCLK;
				MCLK2 <= USB_MCLK;
				BCLK1 <= USB_BCLK;
				BCLK2 <= USB_BCLK;
				LRCK1 <= USB_DATA;
				LRCK2 <= USB_DATA;
				DATA1 <= USB_LRCK;
				DATA2 <= USB_LRCK;
			else
				MCLK1 <= USB_MCLK;
				MCLK2 <= USB_MCLK;
				BCLK1 <= USB_BCLK;
				BCLK2 <= USB_BCLK;
				LRCK1 <= USB_LRCK;
				LRCK2 <= USB_LRCK;
				DATA1 <= USB_DATA;
				DATA2 <= USB_DATA;
			end if;
		end if;
	elsif inselo = "01" then
		MCLK1 <= RJ4_MCLK;
		MCLK2 <= RJ4_MCLK;
		BCLK1 <= RJ4_BCLK;
		BCLK2 <= RJ4_BCLK;
		LRCK1 <= RJ4_LRCK;
		LRCK2 <= RJ4_LRCK;
		DATA1 <= RJ4_DATA;
		DATA2 <= RJ4_DATA;		
	elsif inselo = "10" then
		MCLK1 <= BBB_MCLK;
		MCLK2 <= BBB_MCLK;
		BCLK1 <= BBB_BCLK;
		BCLK2 <= BBB_BCLK;
		LRCK1 <= BBB_LRCK;
		LRCK2 <= BBB_LRCK;
		DATA1 <= BBB_DATA;
		DATA2 <= BBB_DATA;		
	elsif inselo = "11" then
		MCLK1 <= USB_MCLK;
		MCLK2 <= USB_MCLK;
		BCLK1 <= USB_BCLK;
		BCLK2 <= USB_BCLK;
		LRCK1 <= USB_LRCK;
		LRCK2 <= USB_LRCK;
		DATA1 <= USB_DATA;
		DATA2 <= USB_DATA;
	else
		MCLK1 <= USB_MCLK;
		MCLK2 <= USB_MCLK;
		BCLK1 <= USB_BCLK;
		BCLK2 <= USB_BCLK;
		LRCK1 <= USB_LRCK;
		LRCK2 <= USB_LRCK;
		DATA1 <= USB_DATA;
		DATA2 <= USB_DATA;		
	end if;
end process;

process(USB_FS,USB_DP,DET_FS,DET_D256,DET_D64,DET_DP,INSELO) begin
	if inselo = "00" or inselo = "11" then
		FS <= USB_FS;
		DP <= USB_DP;
		D256_512 <= DET_D256;
		D64_128 <= DET_D64;
--		D64_128 <= USB_D64;
	elsif inselo = "01" or inselo = "10" then
		FS <= DET_FS;
		DP <= DET_DP;
		D256_512 <= DET_D256;
		D64_128 <= DET_D64;
	else
		FS <= USB_FS;
		DP <= USB_DP;
		D256_512 <= DET_D256;
		D64_128 <= DET_D64;
--		D64_128 <= USB_D64;
	end if;
end process;
		
end RTL;
			
				