Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY lobdas_top IS
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
	RSV1		: out std_logic;
	TP1		: out std_logic;
	TP2		: out std_logic;
	ESPRST	: out std_logic
);
END lobdas_top;

ARCHITECTURE RTL OF lobdas_top IS

component i2c_slave
port (
	-- generic ports
	 XRESET  : in  std_logic;                     -- System Reset
	 sysclk	: in	std_logic;
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
end component;

component i2c_inout
PORT(
	a  :  IN STD_LOGIC;  	-- Output Data Signal (to INOUT pin)
	en	:  IN STD_LOGIC;  	-- Output Enable Signal
	b  :  INOUT STD_LOGIC;  -- INOUT Port
	c  :  OUT STD_LOGIC  	-- Input Signal (from INOUT pin)
);
end component;

component reg_ctrl
PORT(
	reset		: in  std_logic;                     	-- System Reset
	sysclk	: in std_logic;
	start   	: in std_logic;                     	-- start of the i2c cycle
	stop    	: in std_logic;                     	-- stop the i2c cycle
	r_w     	: in std_logic;                     	-- read/write signal to the reg_map bloc
	data_vld	: in std_logic;                     	-- data valid from i2c
	data_in	: in  std_logic_vector(7 DOWNTO 0);  	-- data from i2c_slave
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
	OPT0		: in std_logic;
	OPT1		: in std_logic;
	PLUGED	: in std_logic;
	D256_512	: in std_logic;
	D64_128	: in std_logic;
	DSDON		: in std_logic;
	F			: in std_logic_vector(3 downto 0);	
	BCK16		: in std_logic;
	ready		: out  std_logic;                     	-- back end system ready signal
	data_out	: out std_logic_vector(7 DOWNTO 0); 	--data to i2c_slave module
	INSELO	: out std_logic_vector(1 downto 0);
	RSV2		: out std_logic;
	RSV1		: out std_logic;
	MCLKEN	: out std_logic
);
end component;

component detect_fs
PORT(
		CLK49M		: in std_logic;
		XDSD			: in std_logic;
		MCLK			: in std_logic;
		BCK			: in std_logic;
		LRCK			: in std_logic;
		CK_SEL		: in std_logic;
		CPOK			: IN std_logic;
--		ov96k			: out std_logic;
		DSD64_128	: OUT std_logic;
		DSD256_512	: OUT std_logic;
		FS				: OUT std_logic_vector(3 downto 0);
		BCK16			: OUT std_logic);
END component;

component detdsd
PORT(
		xrst			: in std_logic;
		mclk			: in std_logic;
		bclk			: in std_logic;
		lrck			: in std_logic;
		dp				: out std_logic
);
END component;

component dop
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
END component;

component select_in
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
END component;

component fs44_48
PORT(
		XRST			: in std_logic;
		CLK49M		: in std_logic;
		XDSD			: in std_logic;
		LRCK			: in std_logic;
		CK_SEL		: out std_logic
);
END component;

component espReset
PORT(
		XRST			: in std_logic;
		CLK49M		: in std_logic;
		ESPRST		: out std_logic
);
END component;

signal rst					: std_logic;
signal clk_msec 			: std_logic;
signal scl_oe				: std_logic;
signal ina					: std_logic;
signal sda_in				: std_logic;
signal ready				: std_logic;
signal start				: std_logic;
signal stop					: std_logic;
signal data_in				: std_logic_vector(7 downto 0);
signal data_out			: std_logic_vector(7 downto 0);
signal r_w					: std_logic;
signal data_vld			: std_logic;
signal sda_oe				: std_logic;
signal usb_fs				: std_logic_vector(3 downto 0);
signal usb_dp				: std_logic;
signal usb_d64				: std_logic;
signal det_fs				: std_logic_vector(3 downto 0);
signal det_dp				: std_logic;
signal det_d256			: std_logic;
signal det_d64				: std_logic;
signal xdsd					: std_logic;
signal imclk1				: std_logic;
signal ibclk1				: std_logic;
signal ilrck1				: std_logic;
signal ck_sel				: std_logic;
signal ov96k				: std_logic;
signal id256_512			: std_logic;
signal id64_128			: std_logic;
signal idp					: std_logic;
signal ifs					: std_logic_vector(3 downto 0);
signal inselo				: std_logic_vector(1 downto 0);
signal ibclk2				: std_logic;
signal imclk2				: std_logic;
signal mclken				: std_logic;
signal bck16				: std_logic;
signal DIV_BBB_MCLK		: std_logic;
signal ex_mclk				: std_logic;

begin

scl_out <= '0' when scl_oe = '1' else 'Z';
sda_out <= 'Z';
ina <= '0';

rst <= not xrst;

I1	: i2c_inout port map(a=>ina,en=>sda_oe,b=>sda,c=>sda_in);

S1	: i2c_slave port map(XRESET=>rst,sysclk=>clk49m,ready=>ready,start=>start,stop=>stop,
								data_in=>data_out,data_out=>data_in,r_w=>r_w,data_vld=>data_vld,
								scl_in=>scl_in,scl_oe=>scl_oe,sda_in=>sda_in,sda_oe=>sda_oe);

R1 : reg_ctrl port map(reset=>rst, sysclk=>clk49m, start=>start, stop=>stop, r_w=>r_w, 
							  data_vld=>data_vld, data_in=>data_in, DEM=>dem, DSDD=>dsdd, 
							  DSDF=> dsdf, MONO1=>mono1, MONO0=>mono0, DSDSEL1=>dsdsel1, 
							  DSDSEL0=>dsdsel0, DIF2=>dif2, DIF1=>dif1, DIF0=>dif0, 
							  DSDPATH=>dsdpath, GC1=>gc1, GC0=>gc0, DEVNAME=>devname, CHLR=>chlr, 
							  INSEL=>insel, OPT0=>opt0, OPT1=>opt1, PLUGED=>pluged, D256_512=>id256_512, D64_128=>id64_128,
							  DSDON=>idp, F=>ifs, BCK16=>bck16, ready=>ready,data_out=>data_out, INSELO=>inselo,
							  RSV2=>rsv2, RSV1=>rsv1, MCLKEN=>mclken);

SEL : select_in port map(xrst=>xrst, INSELO=>inselo, BBB_MCLK=>ex_mclk, BBB_BCLK=>bbb_bclk, 
								 BBB_LRCK=>bbb_lrck, BBB_DATA=>bbb_data, RJ4_DATA=>rj4_data, 
								 RJ4_BCLK=>rj4_bclk, RJ4_LRCK=>rj4_lrck, RJ4_MCLK=>rj4_mclk, 
								 USB_DATA=>usb_data, USB_MCLK=>usb_mclk, USB_BCLK=>usb_bclk, 
								 USB_LRCK=>usb_lrck, USB_FS=>f, USB_DP=>dsdon, USB_D64=>d64_128,
								 DET_FS=>det_fs, DET_DP=>det_dp, DET_D256=> det_d256, DET_D64=>det_d64, CHLR=>chlr, LRCK1=>ilrck1,
								 DATA1=>data1, BCLK1=>ibclk1, MCLK1=>imclk1, LRCK2=>lrck2, DATA2=>data2,
								 BCLK2=>ibclk2, MCLK2=>imclk2, FS=>ifs, DP=>idp, D256_512=>id256_512, D64_128=>id64_128); 

DET1 : detect_fs port map(CLK49M=>clk49m, XDSD=>xdsd, MCLK=>imclk1, BCK=>ibclk1, LRCK=>ilrck1, CK_SEL=>ck_sel, 
								  CPOK=>xrst, DSD64_128=>det_d64, DSD256_512=>det_d256, FS=>det_fs, BCK16=>bck16);
								  
DET2 : detdsd port map(xrst=>xrst, mclk=>imclk1, bclk=>ibclk1, lrck=>ilrck1, dp=>det_dp);

FS1 : fs44_48 port map(XRST=>xrst, CLK49M=>clk49m, XDSD=>xdsd, LRCK=>ilrck1, CK_SEL=>ck_sel);

ESP : espReset PORT map(XRST =>xrst, CLK49M=>clk49m, ESPRST=>esprst);

--MCLK1 <= imclk1;
BCLK1 <= ibclk1;
BCLK2 <= ibclk2;
LRCK1 <= ilrck1;
DP <= idp;
xdsd <= not idp;

--TP1 <= inselo(0);
--TP2 <= inselo(1);

process(DEVNAME, idp, ibclk1, ibclk2, imclk1, imclk2, mclken) begin
	if (DEVNAME(2 downto 0) = "011") then	-- BD34301EKV
		if (mclken = '1') then
			if (idp = '1') then
				MCLK1 <= ibclk1;
				MCLK2 <= ibclk2;
			else
				MCLK1 <= imclk1;
				MCLK2 <= imclk2;
			end if;
		else
			MCLK1 <= '0';
			MCLK2 <= '0';
		end if;
	else
		MCLK1 <= imclk1;
		MCLK2 <= imclk2;
	end if;
end process;

process(BBB_MCLK, xrst) begin
	if (xrst = '0') then
		DIV_BBB_MCLK <= '0';
	elsif (BBB_MCLK'event and BBB_MCLK='1') then
		DIV_BBB_MCLK <= not DIV_BBB_MCLK;
	end if;
end process;

ex_mclk <= BBB_MCLK when insel(0) = '1' else DIV_BBB_MCLK;

end RTL;