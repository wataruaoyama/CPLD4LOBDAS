Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE WORK.ALL;

ENTITY reg_ctrl IS
PORT(
    reset    : in std_logic;                       -- System Reset, active high
    sysclk   : in std_logic;

    start    : in std_logic;                       -- 1 sysclk pulse from i2c_slave
    stop     : in std_logic;                       -- 1 sysclk pulse from i2c_slave
    r_w      : in std_logic;                       -- 0: write, 1: read
    data_vld : in std_logic;                       -- write byte valid
    data_in  : in std_logic_vector(7 DOWNTO 0);    -- data from i2c_slave

    DEM      : in std_logic;
    DSDD     : in std_logic;
    DSDF     : in std_logic;
    MONO1    : in std_logic;
    MONO0    : in std_logic;
    DSDSEL1  : in std_logic;
    DSDSEL0  : in std_logic;
    DIF2     : in std_logic;
    DIF1     : in std_logic;
    DIF0     : in std_logic;
    DSDPATH  : in std_logic;
    GC1      : in std_logic;
    GC0      : in std_logic;
    DEVNAME  : in std_logic_vector(2 downto 0);
    CHLR     : in std_logic;
    INSEL    : in std_logic_vector(1 downto 0);
    OPT0     : in std_logic;
    OPT1     : in std_logic;
    PLUGED   : in std_logic;
	 DOP_VLD	 : in std_logic;

    ready    : out std_logic;
    data_out : out std_logic_vector(7 DOWNTO 0);

    INSELO   : out std_logic_Vector(1 downto 0);
    RSV2     : out std_logic;
    RSV1     : out std_logic;
    MCLKEN   : out std_logic;
	 MUTE_REQ : out std_logic;
	 DSD_MODE : out std_logic
);
END reg_ctrl;

ARCHITECTURE RTL OF reg_ctrl IS

    --------------------------------------------------------------------
    -- Register address map
    --
    -- Write:
    --   1st write byte : register address
    --   2nd write byte : register data
    --
    -- Read:
    --   previous address byte is held across STOP,
    --   so Arduino Wire.endTransmission(); Wire.requestFrom(...);
    --   works.
    --------------------------------------------------------------------
    type wr_phase_type is (WR_ADDR, WR_DATA);
    signal wr_phase : wr_phase_type;

    signal addr_reg : std_logic_vector(1 downto 0);

    signal rd_reg0  : std_logic_vector(7 downto 0);
    signal rd_reg1  : std_logic_vector(7 downto 0);
    signal rd_reg2  : std_logic_vector(7 downto 0);
    signal rd_reg3  : std_logic_vector(7 downto 0);

    signal wr_reg0  : std_logic_vector(7 downto 0);
    signal wr_reg3  : std_logic_vector(7 downto 0);

    signal data_out_i : std_logic_vector(7 downto 0);

    -- 必要に応じて初期値を変更
    constant WR_REG0_RESET : std_logic_vector(7 downto 0) := "00001000";
    constant WR_REG3_RESET : std_logic_vector(7 downto 0) := "00000000";

BEGIN

    --------------------------------------------------------------------
    -- Always ready
    --------------------------------------------------------------------
    ready <= '1';


    --------------------------------------------------------------------
    -- I2C write parser
    --------------------------------------------------------------------
    process(sysclk, reset)
    begin
        if reset = '1' then
            wr_phase <= WR_ADDR;
            addr_reg <= "00";

            wr_reg0  <= WR_REG0_RESET;
            wr_reg3  <= WR_REG3_RESET;

        elsif rising_edge(sysclk) then

            -- 新しいトランザクション開始時は、
            -- 次のwrite byteをregister addressとして扱う。
            -- ただしaddr_reg自体は消さない。
            -- Read transactionではdata_vldが来ないので、保持されたaddr_regで読む。
            if start = '1' then
                wr_phase <= WR_ADDR;
            end if;

            -- STOP後もaddr_regは保持する。
            -- Arduino側の i2cRead() が
            --   write regadr + STOP
            --   read 1 byte + STOP
            -- だから。
            if stop = '1' then
                wr_phase <= WR_ADDR;
            end if;

            if (data_vld = '1') and (r_w = '0') then

                case wr_phase is

                    ----------------------------------------------------
                    -- first byte: register address
                    ----------------------------------------------------
                    when WR_ADDR =>
                        addr_reg <= data_in(1 downto 0);
                        wr_phase <= WR_DATA;


                    ----------------------------------------------------
                    -- second byte: register write data
                    ----------------------------------------------------
                    when WR_DATA =>
                        case addr_reg is
                            when "00" =>
                                wr_reg0 <= data_in;

                            when "11" =>
                                wr_reg3 <= data_in;

                            when others =>
                                null;
                        end case;

                        -- 1byte write制限なので、次はまたaddress扱いに戻す。
                        -- 連続writeを使いたい場合はここをWR_DATA保持にして
                        -- addr_regをインクリメントする。
                        wr_phase <= WR_ADDR;

                    when others =>
                        wr_phase <= WR_ADDR;

                end case;
            end if;
        end if;
    end process;


    --------------------------------------------------------------------
    -- Write register outputs
    --------------------------------------------------------------------
    INSELO(1) <= wr_reg0(4);
    INSELO(0) <= wr_reg0(3);

    RSV2	<= wr_reg3(7);
    RSV1 <= wr_reg3(6);
	 DSD_MODE <= wr_reg3(2);
	 MUTE_REQ <= wr_reg3(1);
    MCLKEN <= wr_reg3(0);


    --------------------------------------------------------------------
    -- Read registers
    --------------------------------------------------------------------
    rd_reg0(7) <= OPT1;
    rd_reg0(6) <= OPT0;
    rd_reg0(5) <= PLUGED;
    rd_reg0(4) <= '0';
    rd_reg0(3) <= '0';
    rd_reg0(2) <= DEVNAME(2);
    rd_reg0(1) <= DEVNAME(1);
    rd_reg0(0) <= DEVNAME(0);

    rd_reg1(7) <= MONO1;
    rd_reg1(6) <= MONO0;
    rd_reg1(5) <= DIF2;
    rd_reg1(4) <= DIF1;
    rd_reg1(3) <= DIF0;
    rd_reg1(2) <= DSDPATH;
    rd_reg1(1) <= GC1;
    rd_reg1(0) <= GC0;

    rd_reg2(7) <= CHLR;
    rd_reg2(6) <= INSEL(1);
    rd_reg2(5) <= INSEL(0);
    rd_reg2(4) <= DEM;
    rd_reg2(3) <= DSDSEL1;
    rd_reg2(2) <= DSDSEL0;
    rd_reg2(1) <= DSDD;
    rd_reg2(0) <= DSDF;

    rd_reg3(7) <= DOP_VLD;
    rd_reg3(6) <= '0'; --D256_512;
    rd_reg3(5) <= '0'; --F(3);
    rd_reg3(4) <= '0'; --F(2);
    rd_reg3(3) <= '0'; --F(1);
    rd_reg3(2) <= '0'; --F(0);
    rd_reg3(1) <= '0'; --64_128;
    rd_reg3(0) <= '0';


    --------------------------------------------------------------------
    -- Read mux
    --
    -- i2c_slaveがRead address ACK後すぐdata_inをロードするので、
    -- data_outはr_wやstateでゲートせず、常にaddr_regに応じて出す。
    --------------------------------------------------------------------
    process(addr_reg, rd_reg0, rd_reg1, rd_reg2, rd_reg3)
    begin
        case addr_reg is
            when "00" =>
                data_out_i <= rd_reg0;
            when "01" =>
                data_out_i <= rd_reg1;
            when "10" =>
                data_out_i <= rd_reg2;
            when "11" =>
                data_out_i <= rd_reg3;
            when others =>
                data_out_i <= (others => '0');
        end case;
    end process;

    data_out <= data_out_i;

END RTL;
