Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY i2c_inout IS
PORT(
	a  :  IN STD_LOGIC;  -- Output Data Signal (to INOUT pin)
	en	:  IN STD_LOGIC;  -- Output Enable Signal
	b  :  INOUT STD_LOGIC;  -- INOUT Port
	c  :  OUT STD_LOGIC  -- Input Signal (from INOUT pin)
);
END i2c_inout;

ARCHITECTURE RTL OF i2c_inout IS

begin
	b <= a WHEN en = '1' ELSE 'Z';
	c <= b ;
end RTL;