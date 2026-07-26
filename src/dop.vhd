Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE WORK.ALL;

ENTITY dop IS
PORT(
		xrst			: in std_logic;
		mclk			: in std_logic;
		bclk			: in std_logic;
		lrck			: in std_logic;
		data			: in std_logic;
		bck_dsdck	: out std_logic;
		lrck_dsdr	: out std_logic;
		data_dsdl	: out std_logic;
		dsd_valid	: out std_logic;
		dop_locked	: out std_logic
);
END dop;

ARCHITECTURE RTL OF dop IS

begin

bck_dsdck <= bclk;
lrck_dsdr <= lrck;
data_dsdl <= data;

end RTL;