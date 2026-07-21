Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE WORK.ALL;

ENTITY i2c_slave IS
PORT (
    -- generic ports
    XRESET   : in  std_logic;                    -- System Reset, active high
    sysclk   : in  std_logic;
    ready    : in  std_logic;                    -- back end ready

    start    : out std_logic;                    -- 1 sysclk pulse
    stop     : out std_logic;                    -- 1 sysclk pulse

    data_in  : in  std_logic_vector(7 DOWNTO 0); -- read data from reg_ctrl
    data_out : out std_logic_vector(7 DOWNTO 0); -- write data to reg_ctrl

    r_w      : out std_logic;                    -- 0: write, 1: read
    data_vld : out std_logic;                    -- write byte valid, 1 sysclk pulse

    -- i2c ports
    scl_in   : in  std_logic;
    scl_oe   : out std_logic;
    sda_in   : in  std_logic;
    sda_oe   : out std_logic
);
END i2c_slave;

ARCHITECTURE RTL OF i2c_slave IS

    constant I2C_SLAVE_ADDR : std_logic_vector(6 downto 0) := "1010010"; -- 0x52

    type i2c_state_type is (
        ST_IDLE,
        ST_ADDR,
        ST_ADDR_ACK,
        ST_WRITE,
        ST_WRITE_ACK,
        ST_READ,
        ST_READ_ACK
    );

    signal state       : i2c_state_type;

    signal scl_sr      : std_logic_vector(2 downto 0);
    signal sda_sr      : std_logic_vector(2 downto 0);
    signal scl_filt    : std_logic;
    signal sda_filt    : std_logic;
    signal scl_prev    : std_logic;
    signal sda_prev    : std_logic;

    signal scl_rise    : std_logic;
    signal scl_fall    : std_logic;
    signal start_det   : std_logic;
    signal stop_det    : std_logic;

    signal bit_cnt     : integer range 0 to 7;
    signal rx_shift    : std_logic_vector(7 downto 0);
    signal tx_shift    : std_logic_vector(7 downto 0);

    signal rw_reg      : std_logic;

    signal sda_oe_reg  : std_logic;
    signal scl_oe_reg  : std_logic;

    signal start_reg   : std_logic;
    signal stop_reg    : std_logic;
    signal data_vld_reg: std_logic;
    signal data_out_reg: std_logic_vector(7 downto 0);

    signal ack_value   : std_logic;  -- '1' means ACK drive low
    signal ack_phase   : std_logic;  -- 0: wait first fall, 1: wait second fall

    signal read_ack_sampled : std_logic;
    signal read_more        : std_logic;

BEGIN

    --------------------------------------------------------------------
    -- Output assign
    --------------------------------------------------------------------
    start    <= start_reg;
    stop     <= stop_reg;
    data_vld <= data_vld_reg;
    data_out <= data_out_reg;
    r_w      <= rw_reg;

    sda_oe   <= sda_oe_reg;
    scl_oe   <= scl_oe_reg;

    --------------------------------------------------------------------
    -- Simple input synchronizer / glitch filter
    --------------------------------------------------------------------
    process(sysclk, XRESET)
    begin
        if XRESET = '1' then
            scl_sr   <= "111";
            sda_sr   <= "111";
            scl_filt <= '1';
            sda_filt <= '1';
            scl_prev <= '1';
            sda_prev <= '1';

        elsif rising_edge(sysclk) then
            scl_sr <= scl_sr(1 downto 0) & scl_in;
            sda_sr <= sda_sr(1 downto 0) & sda_in;

            scl_prev <= scl_filt;
            sda_prev <= sda_filt;

            if scl_sr = "111" then
                scl_filt <= '1';
            elsif scl_sr = "000" then
                scl_filt <= '0';
            end if;

            if sda_sr = "111" then
                sda_filt <= '1';
            elsif sda_sr = "000" then
                sda_filt <= '0';
            end if;
        end if;
    end process;

    scl_rise  <= '1' when (scl_prev = '0' and scl_filt = '1') else '0';
    scl_fall  <= '1' when (scl_prev = '1' and scl_filt = '0') else '0';

    start_det <= '1' when (sda_prev = '1' and sda_filt = '0' and scl_filt = '1') else '0';
    stop_det  <= '1' when (sda_prev = '0' and sda_filt = '1' and scl_filt = '1') else '0';


    --------------------------------------------------------------------
    -- I2C slave FSM
    --------------------------------------------------------------------
    process(sysclk, XRESET)
        variable rx_byte : std_logic_vector(7 downto 0);
    begin
        if XRESET = '1' then
            state            <= ST_IDLE;
            bit_cnt          <= 7;
            rx_shift         <= (others => '0');
            tx_shift         <= (others => '0');
            rw_reg           <= '1';

            sda_oe_reg       <= '0';
            scl_oe_reg       <= '0';

            start_reg        <= '0';
            stop_reg         <= '0';
            data_vld_reg     <= '0';
            data_out_reg     <= (others => '0');

            ack_value        <= '0';
            ack_phase        <= '0';

            read_ack_sampled <= '0';
            read_more        <= '0';

        elsif rising_edge(sysclk) then

            ----------------------------------------------------------------
            -- default pulse outputs
            ----------------------------------------------------------------
            start_reg    <= '0';
            stop_reg     <= '0';
            data_vld_reg <= '0';

            -- 今回は clock stretch しない
            scl_oe_reg <= '0';

            ----------------------------------------------------------------
            -- START / STOP detect
            ----------------------------------------------------------------
            if start_det = '1' then
                start_reg        <= '1';
                state            <= ST_ADDR;
                bit_cnt          <= 7;
                rx_shift         <= (others => '0');
                sda_oe_reg       <= '0';
                ack_value        <= '0';
                ack_phase        <= '0';
                read_ack_sampled <= '0';

            elsif stop_det = '1' then
                stop_reg         <= '1';
                state            <= ST_IDLE;
                bit_cnt          <= 7;
                sda_oe_reg       <= '0';
                ack_value        <= '0';
                ack_phase        <= '0';
                read_ack_sampled <= '0';

            else

                case state is

                    --------------------------------------------------------
                    -- Wait state
                    --------------------------------------------------------
                    when ST_IDLE =>
                        sda_oe_reg <= '0';


                    --------------------------------------------------------
                    -- Receive slave address + R/W bit
                    --------------------------------------------------------
                    when ST_ADDR =>
                        if scl_rise = '1' then
                            rx_byte := rx_shift;
                            rx_byte(bit_cnt) := sda_filt;
                            rx_shift <= rx_byte;

                            if bit_cnt = 0 then
                                if (rx_byte(7 downto 1) = I2C_SLAVE_ADDR) and (ready = '1') then
                                    rw_reg    <= rx_byte(0);
                                    ack_value <= '1';  -- ACK
                                else
                                    rw_reg    <= rx_byte(0);
                                    ack_value <= '0';  -- NACK
                                end if;

                                state     <= ST_ADDR_ACK;
                                ack_phase <= '0';
                            else
                                bit_cnt <= bit_cnt - 1;
                            end if;
                        end if;


                    --------------------------------------------------------
                    -- ACK after address byte
                    --------------------------------------------------------
                    when ST_ADDR_ACK =>
                        if scl_fall = '1' then
                            if ack_phase = '0' then
                                -- SCL low during ACK bit: pull SDA low if ACK
                                sda_oe_reg <= ack_value;
                                ack_phase  <= '1';
                            else
                                -- ACK bit finished
                                sda_oe_reg <= '0';
                                ack_phase  <= '0';

                                if ack_value = '0' then
                                    state <= ST_IDLE;
                                else
                                    if rw_reg = '0' then
                                        -- master write
                                        state   <= ST_WRITE;
                                        bit_cnt <= 7;
                                    else
                                        -- master read
                                        tx_shift   <= data_in;
                                        state      <= ST_READ;
                                        bit_cnt    <= 7;
                                        sda_oe_reg <= not data_in(7); -- first read bit
                                    end if;
                                end if;
                            end if;
                        end if;


                    --------------------------------------------------------
                    -- Receive write data byte
                    --------------------------------------------------------
                    when ST_WRITE =>
                        if scl_rise = '1' then
                            rx_byte := rx_shift;
                            rx_byte(bit_cnt) := sda_filt;
                            rx_shift <= rx_byte;

                            if bit_cnt = 0 then
                                data_out_reg <= rx_byte;
                                data_vld_reg <= '1';

                                if ready = '1' then
                                    ack_value <= '1';
                                else
                                    ack_value <= '0';
                                end if;

                                state     <= ST_WRITE_ACK;
                                ack_phase <= '0';
                            else
                                bit_cnt <= bit_cnt - 1;
                            end if;
                        end if;


                    --------------------------------------------------------
                    -- ACK after write data byte
                    --------------------------------------------------------
                    when ST_WRITE_ACK =>
                        if scl_fall = '1' then
                            if ack_phase = '0' then
                                sda_oe_reg <= ack_value;
                                ack_phase  <= '1';
                            else
                                sda_oe_reg <= '0';
                                ack_phase  <= '0';

                                if ack_value = '1' then
                                    state   <= ST_WRITE;
                                    bit_cnt <= 7;
                                else
                                    state <= ST_IDLE;
                                end if;
                            end if;
                        end if;


                    --------------------------------------------------------
                    -- Transmit read data byte
                    --------------------------------------------------------
                    when ST_READ =>
                        if scl_fall = '1' then
                            if bit_cnt = 0 then
                                -- release SDA for master ACK/NACK
                                sda_oe_reg       <= '0';
                                state            <= ST_READ_ACK;
                                read_ack_sampled <= '0';
                            else
                                bit_cnt    <= bit_cnt - 1;
                                sda_oe_reg <= not tx_shift(bit_cnt - 1);
                            end if;
                        end if;


                    --------------------------------------------------------
                    -- Master ACK/NACK after read byte
                    --------------------------------------------------------
                    when ST_READ_ACK =>

                        if scl_rise = '1' then
                            -- ACK = SDA low, NACK = SDA high
                            if sda_filt = '0' then
                                read_more <= '1';
                            else
                                read_more <= '0';
                            end if;

                            read_ack_sampled <= '1';
                        end if;

                        if (scl_fall = '1') and (read_ack_sampled = '1') then
                            read_ack_sampled <= '0';

                            if read_more = '1' then
                                -- sequential read fallback
                                -- reg_ctrl側でアドレス自動更新はしないので、
                                -- 必要ならreg_ctrl側も拡張する
                                tx_shift   <= data_in;
                                bit_cnt    <= 7;
                                state      <= ST_READ;
                                sda_oe_reg <= not data_in(7);
                            else
                                sda_oe_reg <= '0';
                                state      <= ST_IDLE;
                            end if;
                        end if;


                    when others =>
                        state      <= ST_IDLE;
                        sda_oe_reg <= '0';

                end case;
            end if;
        end if;
    end process;

END RTL;

