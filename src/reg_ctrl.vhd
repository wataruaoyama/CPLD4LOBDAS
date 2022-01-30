Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE WORK.ALL;
USE IEEE.std_logic_unsigned.ALL;

ENTITY reg_ctrl IS
PORT(
	reset		: in std_logic;                     	-- System Reset
	sysclk	: in std_logic;
	start   	: in std_logic;                     	-- start of the i2c cycle
	stop    	: in std_logic;                     	-- stop the i2c cycle
	r_w     	: in std_logic;                     	-- read/write signal to the reg_map bloc
	data_vld	: in std_logic;                     	-- data valid from i2c
	data_in		: in  std_logic_vector(7 DOWNTO 0);  	-- data from i2c_slave
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
	data_out	: out std_logic_vector(7 DOWNTO 0);  	--data to i2c_slave module
	INSELO	: out std_logic_Vector(1 downto 0);
	RSV2		: out std_logic;
	RSV1		: out std_logic;
	MCLKEN	: out std_logic
);
END reg_ctrl;

ARCHITECTURE RTL OF reg_ctrl IS

--	signal dstart		: std_logic;
	signal dstop		: std_logic;
	signal ddata_vld	: std_logic;
	signal dr_w			: std_logic;
	signal rd			: std_logic;
	signal addr_reg	: std_logic_vector(1 downto 0);
	signal dreg			: std_logic_vector(2 downto 0);	--(3 downto 0);
	signal ddreg		: std_logic_vector(2 downto 0);	--(3 downto 0);
	signal dddreg		: std_logic_vector(2 downto 0);	--(3 downto 0);
	signal rd_reg0		: std_logic_vector(7 downto 0);
	signal rd_reg1		: std_logic_vector(7 downto 0);
	signal rd_reg2		: std_logic_vector(7 downto 0);
	signal rd_reg3		: std_logic_vector(7 downto 0);
	signal wr_reg0		: std_logic_vector(7 downto 0);	-- := "00001000";	-- Caution!! Change BD34301.ino
	signal wr_reg3		: std_logic_vector(7 downto 0);
--	signal dummy_reg	: std_logic_vector(7 downto 0);

	type states IS (idle,address,data);
	signal present_state: states;
	signal next_state: states;

begin

	
	----------------------
	-- Protect meta-stable
	----------------------
	process(sysclk,reset) begin
		if reset = '1' then
			dreg <= "000";	--"0000";
		elsif(sysclk'event and sysclk = '1') then
--			dreg(3) <= start;
			dreg(2) <= stop;
			dreg(1) <= r_w;
			dreg(0) <= data_vld;
		end if;
	end process;
	
	process(sysclk,reset) begin
		if reset = '1' then
			ddreg <= "000";	--"0000";
		elsif (sysclk'event and sysclk = '1') then
			ddreg <= dreg;
		end if;
	end process;
	
	process(sysclk,reset) begin
		if reset = '1' then
			dddreg <= "000";	--"0000";
		elsif (sysclk'event and sysclk = '1') then
			dddreg <= ddreg;
		end if;
	end process;
		
	dr_w <= ddreg(1);
	
	----------------------
	-- Detect rising egde
	----------------------
--	dstart <= ddreg(3) and not dddreg(3);
	dstop <= ddreg(2) and not dddreg(2);
	rd <= ddreg(1) and not dddreg(1);
	ddata_vld <= ddreg(0) and not dddreg(0);


	-----------------
	-- State machine
	-----------------
	process(sysclk,reset) begin
		if (reset = '1') then
			present_state <= idle;
		elsif (sysclk'event and sysclk = '1') then
			present_state <= next_state;
		end if;
	end process;
	
	process(present_state,dstop,ddata_vld) begin
		case present_state is
			when idle =>
				if ddata_vld = '1' then
					next_state <= address;
				else
					next_state <= present_state;
				end if;
			when address =>
				if ddata_vld = '1' then
					next_state <= data;
				else
					next_state <= present_state;
				end if;
			when data =>
				if ddata_vld = '1' then
					next_state <= data;
				elsif dstop = '1' then
					next_state <= idle;
				else
					next_state <= present_state;
				end if;
		end case;
	end process;
		
	---------------------------
	-- Register address counter
	---------------------------
	process(sysclk) begin
		if (sysclk'event and sysclk = '1') then
			if ((present_state = address) and (dr_w = '0')) then
				addr_reg <= data_in(1 downto 0);
			elsif ((dr_w = '1') and (rd = '1')) then
				addr_reg <= data_in(1 downto 0);
			elsif ((present_state = address) or (present_state = data)) then
				if ddata_vld = '1' then
					if addr_reg = "11" then
						addr_reg <= addr_reg;
					else
						addr_reg <= addr_reg + 1;
					end if;
				end if;
			end if;
		end if;
	end process;
		
	-----------
	-- Register
	-----------
	process(sysclk,addr_reg) begin
		if (sysclk'event and sysclk = '1') then
			if ((present_state = data) and (dr_w = '0')) then
				case addr_reg is
					when "00" =>
						wr_reg0 <= data_in;
					when "11" =>
						wr_reg3 <= data_in;
					when others => null; --dummy_reg <= data_in;
				end case;
			end if;
		end if;
	end process;
	
	inselo(1) <= wr_reg0(4);
	inselo(0) <= wr_reg0(3);
	rsv2 <= wr_reg3(7);
	rsv1 <= wr_reg3(6);
	mclken <= wr_reg3(0);
	
	-- Configuration Register
	rd_reg0(7) <= OPT1;
	rd_reg0(6) <= OPT0;
	rd_reg0(5) <= PLUGED;
	rd_reg0(4) <= '0';
	rd_reg0(3) <= '0';
	rd_reg0(2) <= devname(2);
	rd_reg0(1) <= devname(1);
	rd_reg0(0) <= devname(0);
	
	rd_reg1(7) <= mono1;
	rd_reg1(6) <= mono0;
	rd_reg1(5) <= dif2;
	rd_reg1(4) <= dif1;
	rd_reg1(3) <= dif0;
	rd_reg1(2) <= dsdpath;	-- PHC
	rd_reg1(1) <= gc1;	-- INPOL1
	rd_reg1(0) <= gc0;	-- INPOL2
	
	rd_reg2(7) <= CHLR;
	rd_reg2(6) <= insel(1);	-- PAC
	rd_reg2(5) <= insel(0);	-- DIVMCLK
	rd_reg2(4) <= dem;
	rd_reg2(3) <= dsdsel1;	-- OSR1
	rd_reg2(2) <= dsdsel0;	-- OSR0
	rd_reg2(1) <= dsdd;	-- DSDF1
	rd_reg2(0) <= dsdf;	-- DSDF0

	rd_reg3(7) <= BCK16;
	rd_reg3(6) <= d256_512;	-- DSD256/512
	rd_reg3(5) <= F(3);
	rd_reg3(4) <= F(2);
	rd_reg3(3) <= F(1);
	rd_reg3(2) <= F(0);
	rd_reg3(1) <= d64_128;
	rd_reg3(0) <= dsdon;
	
	process(sysclk,addr_reg) begin
		if (sysclk'event and sysclk = '1') then
			if (dr_w = '1') then
				if ((present_state = address) or (present_state = data)) then
					case addr_reg is
						when "00" => data_out <= rd_reg0;
						when "01" => data_out <= rd_reg1;
						when "10" => data_out <= rd_reg2;
						when "11" => data_out <= rd_reg3;
						when others => null; --data_out <= "XXXXXXXX";
					end case;
				end if;		
			end if;					
		end if;
	end process;
	
	ready <= '1';
	
end RTL;