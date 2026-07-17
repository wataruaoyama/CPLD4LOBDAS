Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY lobdas_test IS
END lobdas_test;

ARCHITECTURE lobdas_test_bench OF lobdas_test IS

COMPONENT lobdas_top
PORT(
	XRST		: in std_logic;
	CLK49M	: in std_logic;
	DEM		: in std_logic;
	DSDD		: in std_logic;
	DSDF		: in std_logic;
	MONO1		: in std_logic;
	MONO0		: in std_logic;
	DSDSEL1	: in std_logic;
	DSDSEL0	: in std_logic;
	DIF2		: in std_logic;
	DIF1		: in std_logic;
	DIF0		: in std_logic;
	DSDPATH	: in std_logic;	
	GC1		: in std_logic;
	GC0		: in std_logic;
	DEVNAME	: in std_logic_vector(2 downto 0);
	CHLR		: in std_logic;
	INSEL		: in std_logic_vector(1 downto 0);
	BBB_MCLK	: in std_logic;
	BBB_BCLK	: in std_logic;
	BBB_LRCK	: in std_logic;
	BBB_DATA	: in std_logic;
	RJ45_MUTE: in std_logic;
	OPT0		: in std_logic;
	OPT1		: in std_logic;
	RJ4_DATA	: in std_logic;
	RJ4_BCLK	: in std_logic;
	RJ4_LRCK	: in std_logic;
	RJ4_MCLK	: in std_logic;
	USB_MUTE	: in std_logic;
	PLUGED	: in std_logic;
	USB_DATA	: in std_logic;
	USB_BCLK	: in std_logic;
	USB_LRCK	: in std_logic;
	USB_MCLK	: in std_logic;
	D64_128	: in std_logic;
	DSDON		: in std_logic;
	F			: in std_logic_vector(3 downto 0);
	scl_in	: in std_logic;
	scl_out	: out std_logic;
	sda		: inout std_logic;
	sda_out	: out std_logic;	-- dummy pin
	DP			: out std_logic;
	LRCK1		: out std_logic;
	DATA1		: out std_logic;
	BCLK1		: out std_logic;
	MCLK1		: out std_logic;
	LRCK2		: out std_logic;
	DATA2		: out std_logic;
	BCLK2		: out std_logic;
	MCLK2		: out std_logic;
	RSV2		: out std_logic;
	RSV1		: out std_logic
);
END COMPONENT;
	
constant cycle	: Time := 20ns;
constant	half_cycle : Time := 10ns;
constant double_cycle : Time := 40ns;
constant i : integer := 0;
constant j : integer := 0;
constant k : integer := 0;

type BYTE_DATA is array(0 to 7) of std_logic;
constant slaveaddr_w : BYTE_DATA := ('1','0','1','0','0','1','0','0');
constant slaveaddr_r : BYTE_DATA := ('1','0','1','0','0','1','0','1');

constant regaddr_000 : BYTE_DATA := ('0','0','0','0','0','0','0','0');	-- reg0
constant regaddr_001 : BYTE_DATA := ('0','0','0','0','0','0','0','1');	-- reg1
constant regaddr_010 : BYTE_DATA := ('0','0','0','0','0','0','1','0');	-- reg2
constant regaddr_011 : BYTE_DATA := ('0','0','0','0','0','0','1','1');	-- re3
constant regaddr_100 : BYTE_DATA := ('0','0','0','0','0','1','0','0');	-- 
constant regaddr_101 : BYTE_DATA := ('0','0','0','0','0','1','0','1');	-- 
constant regaddr_110 : BYTE_DATA := ('0','0','0','0','0','1','1','0');	-- 
constant regaddr_111 : BYTE_DATA := ('0','0','0','0','0','1','1','1');	-- 

constant regdata_55 : BYTE_DATA := ('0','1','0','1','0','1','0','1');
constant regdata_AA : BYTE_DATA := ('1','0','1','0','1','0','1','0');

constant regdata_48 : BYTE_DATA := ('0','0','0','0','0','0','0','0');	--
constant regdata_96 : BYTE_DATA := ('0','0','0','0','0','0','0','1');
constant regdata_192 : BYTE_DATA := ('0','0','0','0','0','0','1','0');
constant regdata_384 : BYTE_DATA := ('0','0','0','0','0','0','1','1');
constant regdata_32fs : BYTE_DATA := ('0','0','0','0','0','0','0','0');
constant regdata_64fs : BYTE_DATA := ('0','0','0','0','0','0','0','1');

constant regdata_rsv : BYTE_DATA := ('1','1','0','0','0','0','0','0');
constant regdata_input : BYTE_DATA := ('0','0','0','0','1','0','0','0');


type REGARRAY is array(0 to 3,0 to 7) of std_logic;
constant reg_map : REGARRAY := (('0','1','0','1','0','1','0','1'),
											('1','0','1','0','1','0','1','0'),
											('1','1','1','1','0','0','0','0'),
											('0','0','0','0','1','1','1','1'));

signal reset,clk,scl_in,scl_out,sda_out : std_logic;
signal sda : std_logic;
signal sel : std_logic_vector(1 downto 0);
signal dummy : std_logic;

signal dem					: std_logic;
signal dsdd					: std_logic;
signal dsdf					: std_logic;
signal mono1,mono0		: std_logic;
signal dsdsel1,dsdsel0	: std_logic;
signal dif2,dif1,dif0	: std_logic;
signal dsdpath				: std_logic;
signal gc1,gc0				: std_logic;
signal devname				: std_logic_vector(2 downto 0);
signal chlr					: std_logic;
signal insel				: std_logic_vector(1 downto 0);
signal opt0,opt1			: std_logic;
signal pluged				: std_logic;
signal d64_128				: std_logic;
signal dsdon				: std_logic;
signal f						: std_logic_vector(3 downto 0);
signal bbb_mclk			: std_logic;
signal bbb_bclk			: std_logic;
signal bbb_lrck			: std_logic;
signal bbb_data			: std_logic;
signal rj45_mute			: std_logic;
signal rj4_data			: std_logic;
signal rj4_bclk			: std_logic;
signal rj4_lrck			: std_logic;
signal rj4_mclk			: std_logic;
signal usb_mute			: std_logic;
signal usb_data			: std_logic;
signal usb_bclk			: std_logic;
signal usb_lrck			: std_logic;
signal usb_mclk			: std_logic;

BEGIN

	U2: lobdas_top port map (XRST=>reset, CLK49M=>clk, DEM=>dem,	DSDD=>dsdd,	DSDF=>dsdf,	MONO1=>mono1, MONO0=>mono0, 
									 DSDSEL1=>dsdsel1, DSDSEL0=>dsdsel0, DIF2=>dif2, DIF1=>dif1, DIF0=>dif0, DSDPATH=>dsdpath,
									 GC1=>gc1, GC0=>gc0,	DEVNAME=>devname,	CHLR=>chlr, INSEL=>insel, BBB_MCLK=>bbb_mclk,
									 BBB_BCLK=>bbb_bclk, BBB_LRCK=>bbb_lrck, BBB_DATA=>bbb_data, RJ45_MUTE=>rj45_mute, OPT0=>opt0,
									 OPT1=>opt1, RJ4_DATA=>rj4_data, RJ4_BCLK=>rj4_bclk, RJ4_LRCK=>rj4_lrck, RJ4_MCLK=>rj4_mclk,
									 USB_MUTE=>usb_mute, PLUGED=>pluged, USB_DATA=>usb_data, USB_BCLK=>usb_bclk, 	USB_LRCK=>usb_lrck,
									 USB_MCLK=>usb_mclk, D64_128=>d64_128, DSDON=>dsdon, F=>f, scl_in=>scl_in, scl_out=>scl_out,
									 sda=>sda_out, sda_out=>dummy);

 
	PROCESS BEGIN
		clk <= '0';
		wait for half_cycle;
		clk <= '1';
		wait for half_cycle;
	end PROCESS;

	-- RJ45 I2S
	process begin
		rj4_mclk <= '0';
		wait for cycle;
		rj4_mclk <= '1';
		wait for cycle;
	end process;
		
	process begin		
		wait for cycle*10;
		wait for cycle*8;
		
		for j in 0 to 9 loop
			wait for cycle*256;
			rj4_lrck <= '0';
			wait for cycle*256;
			rj4_lrck <= '1';
		end loop;
		
		wait;
	end process;
	
	process begin
		wait for cycle*10;
		
		for k in 0 to 99 loop
			wait for cycle*8;
			rj4_bclk <='0';
			wait for cycle*8;
			rj4_bclk <= '1';
		end loop;
		
		wait;
	end process;
		
	-- USB I2S
	process begin
		usb_mclk <= '0';
		wait for cycle;
		usb_mclk <= '1';
		wait for cycle;
	end process;
		
	process begin		
		wait for cycle*10;
		wait for cycle*8;
		
		for j in 0 to 9 loop
			wait for cycle*128;
			usb_lrck <= '0';
			wait for cycle*128;
			usb_lrck <= '1';
		end loop;
		
		wait;
	end process;
	
	process begin
		wait for cycle*10;
		
		for k in 0 to 99 loop
			wait for cycle*4;
			usb_bclk <='0';
			wait for cycle*4;
			usb_bclk <= '1';
		end loop;
		
		wait;
	end process;
	
	
	PROCESS BEGIN
		reset <= '0';
		scl_in <= '1';
		sda_out <= '1';
		
		wait for cycle*10;
		reset <= '1';
		dem <= '1';
		dsdf <= '1';
		mono1 <= '0';
		mono0 <= '0';
		dsdsel1 <= '1';
		dsdsel0 <= '0';
		dif2 <= '1';
		dif1 <= '1';
		dif0 <= '1';
		dsdpath <= '1';
		gc1 <= '0';
		gc0 <= '0';
		devname <= "000";
		chlr <= '0';
		insel <= "10";
		f <= "1010";
		dsdon <= '1';
		d64_128 <= '0';
		opt0 <= '1';
		opt1 <= '0';
		pluged <= '1';

	--========================
	-- Single write operation
	--========================
		--*****************
		-- START condition
		--*****************
		wait for cycle*10;
		sda_out <= '0';
		
		wait for cycle*5;	
		scl_in <= '0';		-- start
		
		--********************
		-- Send slave address
		--********************
		for i in 0 to 7 loop		
		wait for cycle*5;
			sda_out <= slaveaddr_w(i);
			
			wait for cycle*5;
			scl_in <= '1';
			
			wait for cycle*10;
			scl_in <= '0';
		end loop;
		
		wait for cycle*5;
		sda_out <= '0';
		
		wait for cycle*5;
		scl_in <= '1';
		
		wait for cycle*10;
		scl_in <= '0';
		
		--*****************************
		-- Send register address(write)
		--*****************************
		for i in 0 to 7 loop		
			wait for cycle*5;
			sda_out <= regaddr_000(i);
			
			wait for cycle*5;
			scl_in <= '1';
			
			wait for cycle*10;
			scl_in <= '0';
		end loop;
		
		wait for cycle*5;
		sda_out <= '0';
		
		wait for cycle*5;
		scl_in <= '1';
				
		wait for cycle*10;
		scl_in <= '0';
		
		--******************
		-- Send register data
		--*******************
		for i in 0 to 7 loop		
		wait for cycle*5;
			sda_out <= regdata_input(i);
			
			wait for cycle*5;
			scl_in <= '1';
			
			wait for cycle*10;
			scl_in <= '0';
		end loop;
		
		wait for cycle*5;
		sda_out <= '0';
		
		wait for cycle*5;
		scl_in <= '1';
		
		wait for cycle*10;
		scl_in <= '0';
		
		--****************
		-- STOP confition
		--****************
		wait for cycle*10;
		scl_in <= '1';
		
		wait for cycle*5;
		sda_out <= '1';
		
		wait for cycle*5;
		scl_in <= '0';
		
		wait for cycle*10;
		scl_in <= '1';
		
		wait for cycle*100;

	--=======================
	-- Single read operation
	--=======================
		--*****************
		-- START condition
		--*****************
		wait for cycle*10;
		sda_out <= '0';
		
		wait for cycle*5;	
		scl_in <= '0';		-- start
		
		--********************
		-- Send slave address
		--********************
		for i in 0 to 7 loop		
		wait for cycle*5;
			sda_out <= slaveaddr_w(i);
			
			wait for cycle*5;
			scl_in <= '1';
			
			wait for cycle*10;
			scl_in <= '0';
		end loop;
		
		wait for cycle*5;
		sda_out <= '0';
		
		wait for cycle*5;
		scl_in <= '1';
		
		wait for cycle*10;
		scl_in <= '0';

		--*********************
		-- Send register address
		--*********************
		for i in 0 to 7 loop		
		wait for cycle*5;
			sda_out <= regaddr_011(i);
			
			wait for cycle*5;
			scl_in <= '1';
			
			wait for cycle*10;
			scl_in <= '0';
		end loop;
		
		--*************************
		--repeated START condition
		--*************************
		wait for cycle*5;
		sda_out <= '1';
		
		wait for cycle*5;
		scl_in <= '1';
		
		wait for cycle*5;
		sda_out <= '0';
				
		wait for cycle*5;
		scl_in <= '0';
		
		wait for cycle*5;
		sda_out <= '1';
		
		wait for cycle*5;
		scl_in <= '1';
		
		wait for cycle*5;
		sda_out <= '0';
		
		wait for cycle*5;
		scl_in <= '0';

		--*************************
		-- Send slave address(read)
		--*************************
		for i in 0 to 7 loop		
		wait for cycle*5;
			sda_out <= slaveaddr_r(i);
			
			wait for cycle*5;
			scl_in <= '1';
			
			wait for cycle*10;
			scl_in <= '0';
		end loop;
		
		wait for cycle*5;
		sda_out <= '0';
		
		wait for cycle*5;
		scl_in <= '1';
		
		wait for cycle*10;
		scl_in <= '0';
		
		--***************************
		--SCL for read data transfer
		--***************************
		for i in 0 to 8 loop
			wait for cycle*10;
			scl_in <= '1';
			wait for cycle*10;
			scl_in <= '0';
		end loop;
		
		--****************
		-- STOP confition
		--****************
		wait for cycle*10;
		scl_in <= '1';
		
		wait for cycle*5;
		sda_out <= '1';
		
		wait for cycle*5;
		scl_in <= '0';
		
		wait for cycle*10;
		scl_in <= '1';
		
		wait for cycle*100;
		
		wait;
	end PROCESS;
	
end lobdas_test_bench;

CONFIGURATION cfg_test of lobdas_test IS
	for lobdas_test_bench
	end for;
end cfg_test;