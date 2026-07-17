--   ==================================================================
--   >>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
--   ------------------------------------------------------------------
--   Copyright (c) 2013 by Lattice Semiconductor Corporation
--   ALL RIGHTS RESERVED 
--   ------------------------------------------------------------------
--
--   Permission:
--
--      Lattice SG Pte. Ltd. grants permission to use this code
--      pursuant to the terms of the Lattice Reference Design License Agreement. 
--
--
--   Disclaimer:
--
--      This VHDL or Verilog source code is intended as a design reference
--      which illustrates how these types of functions can be implemented.
--      It is the user's responsibility to verify their design for
--      consistency and functionality through the use of formal
--      verification methods.  Lattice provides no warranty
--      regarding the use or functionality of this code.
--
--   --------------------------------------------------------------------
--
--                  Lattice SG Pte. Ltd.
--                  101 Thomson Road, United Square #07-02 
--                  Singapore 307591
--
--
--                  TEL: 1-800-Lattice (USA and Canada)
--                       +65-6631-2000 (Singapore)
--                       +1-503-268-8001 (other locations)
--
--                  web: http:--www.latticesemi.com/
--                  email: techsupport@latticesemi.com
--
--   --------------------------------------------------------------------
--
--
--  Name:  i2c_slave.vhd
--
--  Description: Generic i2c slave module with 1 bidirectional data port
--    1.supports random write, random read, sequential read
--    and burst write / read
--
---------------------------------------------------------------------------
-- Code Revision History :
---------------------------------------------------------------------------
-- Ver: | Author |Mod. Date |Changes Made:
-- V1.1 | YF    |12/2009    |Init ver
-- V1.2 | cm    |7/2010     |update the file based on verilog ver 1.3
---------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
USE WORK.ALL;
use ieee.std_logic_unsigned.all;

entity i2c_slave IS
 port (
-- generic ports
 XRESET  : in  std_logic;                     -- System Reset
 sysclk	: in 	std_logic;
 ready   : in  std_logic;                     -- back end system ready signal
 start   : out std_logic;                     -- start of the i2c cycle
 stop    : out std_logic;                     -- stop the i2c cycle
 data_in : in  std_logic_vector(7 DOWNTO 0);  -- parallel data in
 data_out: out std_logic_vector(7 DOWNTO 0);  -- parallel data out
 r_w     : out std_logic;                     -- read/write signal to the reg_map bloc
 data_vld: out std_logic;                     -- data valid from i2c
-- i2c ports
 scl_in  : in std_logic;                      -- SCL clock line
 scl_oe  : out std_logic;                     -- controls scl output enable
 sda_in  : in std_logic;                      -- i2c serial data line in
 sda_oe  : out std_logic                      -- controls sda output enable
 );
end entity;
architecture arch of i2c_slave is
--*****************************************
-- Define states of the state machine
--*****************************************
constant I2C_SLAVE_ADDR : std_logic_vector(6 DOWNTO 0) := "1010010";
constant idle   : std_logic_vector(4 DOWNTO 0) := "00000";
constant addr7  : std_logic_vector(4 DOWNTO 0) := "00001";
constant addr6  : std_logic_vector(4 DOWNTO 0) := "00010";
constant addr5  : std_logic_vector(4 DOWNTO 0) := "00011";
constant addr4  : std_logic_vector(4 DOWNTO 0) := "00100";
constant addr3  : std_logic_vector(4 DOWNTO 0) := "00101";
constant addr2  : std_logic_vector(4 DOWNTO 0) := "00110";
constant addr1  : std_logic_vector(4 DOWNTO 0) := "00111";
constant det_rw : std_logic_vector(4 DOWNTO 0) := "01000";
constant ack    : std_logic_vector(4 DOWNTO 0) := "01001";
constant data7  : std_logic_vector(4 DOWNTO 0) := "01010";
constant data6  : std_logic_vector(4 DOWNTO 0) := "01011";
constant data5  : std_logic_vector(4 DOWNTO 0) := "01100";
constant data4  : std_logic_vector(4 DOWNTO 0) := "01101";
constant data3  : std_logic_vector(4 DOWNTO 0) := "01110";
constant data2  : std_logic_vector(4 DOWNTO 0) := "01111";
constant data1  : std_logic_vector(4 DOWNTO 0) := "10000";
constant data0  : std_logic_vector(4 DOWNTO 0) := "10001";

signal data_int : std_logic_vector(7 DOWNTO 0);     -- internal data register
signal start_t, stop_t : std_logic;             -- start and stop detection of I2C cycles
signal sm_state : std_logic_vector(4 DOWNTO 0);     -- state machine
signal shift : std_logic_vector(7 DOWNTO 0);      -- shift register attached to I2C controller
signal r_w_t : std_logic;            -- indicate read/write operation
signal ack_out : std_logic;        -- acknowledge output from slave to master
signal sda_en : std_logic;         -- OE control of sda signal, could use open drain feature
signal vld_plse  : std_logic;          -- data valid pulse
signal start_rst :  std_logic;       -- reset signals for START and STOP bits
signal start_async_rst :  std_logic;
signal stop_async_rst :  std_logic;

signal sda_f,sda_clk		: std_logic;

signal shift_sda : std_logic_vector(2 downto 0);

begin

--*****************************************
-- Generate reset signals for start and stop
--*****************************************
start_rst <= '1' when ((sm_state = addr7)) else '0'; -- used to reset the start register after we move to addr7
start_async_rst <= start_rst or XRESET;           -- oring the reset signal external and internal
stop_async_rst <= start_t or XRESET;           -- same for stop reset

--******************************************
-- register to delay SDA
-- prevents false start/re-starts from syncronized 
-- falling edges (sda and scl)
--******************************************
--sda_clk <= sda_f xor sda_in after 1 ns;

process(start_async_rst,sysclk) begin
	if (start_async_rst = '1') then
		shift_sda <= "111";
	elsif (rising_edge(sysclk)) then
		shift_sda <= shift_sda(1 downto 0) & sda_in;
	end if;
end process;
sda_clk <= shift_sda(1) xor shift_sda(2);

process(sda_clk, start_async_rst)
begin
	if (start_async_rst = '1') then
	        sda_f <= sda_in;
	elsif (rising_edge(sda_clk)) then
		sda_f <= sda_in;
	end if;
end process;	

--*****************************************
-- Detect I2C Cycle Start
--*****************************************
--process(sda_in,start_async_rst)
process(sda_f,start_async_rst)
begin
  if (start_async_rst = '1') then
    start_t <= '0';
  elsif (falling_edge(sda_f)) then
    start_t <= scl_in;
  end if;
end process;

--*****************************************
--Detect I2C Cycle Stop
--*****************************************
process(sda_in,stop_async_rst)
begin
  if stop_async_rst = '1' then
     stop_t <= '0';
  elsif rising_edge(sda_in) then
     stop_t <= scl_in;
  end if;
end process;

--*****************************************
--FSM check the addr byte and track rw opp
--*****************************************
process(scl_in,XRESET)
begin
  if (XRESET = '1') then
    sm_state <=  idle;                                     -- reset fsm to idle
    r_w_t      <=  '1';           -- initial value for read
    vld_plse <=  '0';
  elsif rising_edge(scl_in) then
    case sm_state is
      when idle =>
        vld_plse <=  '0';
        if (start_t = '1') then     -- start the I2C addr cycle
          sm_state <= addr7;
        elsif (stop_t = '1') then       -- stop and go to idle
          sm_state <=  idle;
        else
          sm_state <=  idle;
        end if;
      when addr7 => 
        if (shift(0) = I2C_SLAVE_ADDR(6)) then        -- checking the slave addr
          sm_state <=  addr6;
        else
          sm_state <=  idle;
        end if;
      when addr6 =>
        if (shift(0) = I2C_SLAVE_ADDR(5)) then
          sm_state <=  addr5;
        else
          sm_state <=  idle;
        end if;
      when addr5 =>
        if (shift(0) = I2C_SLAVE_ADDR(4)) then
          sm_state <=  addr4;
        else
          sm_state <=  idle;
        end if;
      when addr4 =>
        if (shift(0) = I2C_SLAVE_ADDR(3)) then
          sm_state <=  addr3;
        else
          sm_state <=  idle;
        end if;
      when addr3 =>
        if (shift(0) = I2C_SLAVE_ADDR(2)) then
          sm_state <=  addr2;
        else
          sm_state <=  idle;
        end if;
      when addr2 =>
        if (shift(0) = I2C_SLAVE_ADDR(1)) then
          sm_state <=  addr1;
        else
          sm_state <=  idle;
        end if;
      when addr1 =>
        if (shift(0) = I2C_SLAVE_ADDR(0)) then
          sm_state <=  det_rw;
          r_w_t      <=  sda_in;         -- store the read / write direction bit
        else
          sm_state <=  idle;
        end if;
      when det_rw =>
        sm_state <=  ack;
      when ack => 
        if (ready = '1') then
          sm_state <=  data7;
          vld_plse <=  '0';
        else
          sm_state <= idle;
          vld_plse <= '0';
        end if;
      when data7 =>
        if (stop_t = '1') then
          sm_state <= idle;         -- detect stop signal from Master
        elsif (start_t = '1') then
          sm_state <= addr7;             -- detect RESTART signal from Master
        else
          sm_state <= data6;
        end if;
      when data6 => sm_state <= data5;
      when data5 => sm_state <= data4;
      when data4 => sm_state <= data3;
      when data3 => sm_state <= data2;
      when data2 => sm_state <= data1;
      when data1 => 
        sm_state <= data0;
        vld_plse <= '1';
      when data0 =>
        vld_plse <= '0';   -- detect repeated read, write or read/write
        if ((sda_in = '0') and (r_w_t = '0')) then -- 0 means acknowledged
          sm_state <= ack;
        elsif ((sda_in = '0') and (r_w_t = '1')) then -- 0 means acknowledged
          sm_state <= ack;
        else
          sm_state <= idle;
        end if;
      when others =>
        sm_state <= idle;  -- default state
    end case;
  end if;        
end process;

--********************************************
-- Read cycle (slave trasmit, master receive)
-- Write Cycle (slave receive, master transmit)
-- Slave generate ACKOUT during write cycle
--********************************************

process(scl_in,XRESET)
begin                                      -- data should be ready on SDA line when SCL is high
  if (XRESET = '1') then
    ack_out <= '0';
  elsif falling_edge(scl_in) then
    if (sm_state = det_rw) then
      ack_out <= '1';
    elsif (sm_state = data0) then
      if (r_w_t = '0') then              		-- if slave is rx, acknowledge after successful receive
        ack_out <= '1';
      else                                     -- if slave is tx, acknowledge comes from Master
        ack_out <= '0';
      end if;
    else
      ack_out <= '0';
    end if;
  end if;
end process;

--********************************************
-- Enable starting from ACK state
--********************************************
process(scl_in,XRESET)
begin
  if (XRESET = '1') then
   sda_en <= '0';
  elsif falling_edge(scl_in) then
    if (r_w_t = '1' and (sm_state = ack)) then
      sda_en <= not data_in(7);
    elsif (r_w_t = '1' and ((sm_state > ack) and (sm_state < data0))) then
      sda_en <= not shift(6);
    else
      sda_en <= '0';
    end if;
  end if;
end process;

--********************************************
-- SDA OE cntr gen '1' will pull the line low
--********************************************
sda_oe <= '1' when ((ack_out = '1') or (sda_en = '1')) else '0';  -- sda_out is logic '0' at the top level
scl_oe <= '1' when ((sm_state = ack) and (ready = '0')) else '0'; -- if scl_oe = 1, then scl is pulled down

--*******************************
-- Shift operation for READ data
--*******************************

process(scl_in,XRESET)
begin
 if (XRESET = '1') then  -- Reset added to make it work
   shift <= (others => '0');
 elsif falling_edge(scl_in) then
   if ((sm_state = idle) and (start_t = '1')) then
     shift(0) <= sda_in;
   elsif ((sm_state >= addr7) and (sm_state <= addr1)) then
     shift(0) <= sda_in;
   elsif (r_w_t = '1' and (sm_state = ack)) then  -- 2nd version
     shift <= data_in;                -- load the GPIO data into shift registers
   elsif ((sm_state > ack) and (sm_state <= data0)) then -- start shift the data out to SDA line
      shift(7 downto 1) <= shift(6 downto 0);
      shift(0) <= sda_in;
   end if;
 end if;
end process;
--********************************************
-- data output register
--********************************************
process(scl_in,XRESET)
begin
  if (XRESET = '1') then
    data_int <= (others => '0');
  elsif rising_edge(scl_in) then
    if (r_w_t = '0' and ack_out = '1' and vld_plse = '1') then
      data_int <= shift;
    end if;
  end if;
end process;

data_out <= data_int;
data_vld <= vld_plse; 
r_w <= r_w_t;
start <= start_t;
stop <= stop_t;
end arch;
