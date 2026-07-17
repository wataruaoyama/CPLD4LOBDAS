Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY detect_fs_test IS
END detect_fs_test;

ARCHITECTURE detect_fs_test_bench OF detect_fs_test IS

COMPONENT detect_fs
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
END COMPONENT;
	
constant cycle	: Time := 40ns;
constant	half_cycle : Time := 20ns;
constant LRCK176 : Time := cycle*128;
constant half_LRCK176 : Time := cycle*64;
constant LRCK88 : Time := cycle*256;
constant half_LRCK88 : Time := cycle*128;
constant LRCK44 : Time := cycle*512;
constant half_LRCK44 : Time := cycle*256;
constant LRCK32 : Time := cycle*768;
constant half_LRCK32 : Time := cycle*384;
constant stb	: Time := 2ns;

constant i : integer := 0;

signal clk49m,XDSD,MCLK,BCK,LRCK,CPOK,CK_SEL:std_logic;
signal dsd64_128,dsd256_512 : std_logic;

BEGIN

	sm1: detect_fs port map (CLK49M=>clk49m, XDSD=>XDSD, MCLK=>MCLK, BCK=>BCK, LRCK=>LRCK, CK_SEL=>CK_SEL, CPOK=>CPOK, DSD64_128=>dsd64_128, DSD256_512=>dsd256_512);
	
	PROCESS BEGIN
		MCLK <= '0';
		wait for half_cycle;
		MCLK <= '1';
		wait for half_cycle;
	end PROCESS;
	
	PROCESS BEGIN
		CLK49M <= '0';
		wait for half_cycle;
		CLK49M <= '1';
		wait for half_cycle;
	end PROCESS;
	
	PROCESS BEGIN
		LRCK <= '0';
		wait for half_LRCK44;
		LRCK <= '1';
		wait for half_LRCK44;
	END PROCESS;
	
	-- for detct dsd samplinng frequency
	process begin
		BCK <= '0';
		wait for cycle*10;
		
		for i in 0 to 7 loop
			BCK <= '0';
			wait for cycle*4;
			BCK <= '1';
			wait for cycle*4;
		end loop;
		
		for i in 0 to 7 loop
			BCK <= '0';
			wait for cycle*2;
			BCK <= '1';
			wait for cycle*2;
		end loop;
		
		for i in 0 to 7 loop
			BCK <= '0';
			wait for cycle;
			BCK <= '1';
			wait for cycle;
		end loop;
		
		wait;
	end process;
		
	-- for detect PCM sampling frequencey
	PROCESS BEGIN
		CPOK <= '0'; XDSD <= '1'; CK_SEL <= '0';
		wait for cycle*10;
		wait for stb;
		CPOK <= '1'; XDSD <= '0';
		
		wait;
	end PROCESS;
end detect_fs_test_bench;

CONFIGURATION cfg_test of detect_fs_test IS
	for detect_fs_test_bench
	end for;
end cfg_test;