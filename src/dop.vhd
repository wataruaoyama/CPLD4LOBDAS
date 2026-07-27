Library IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.std_logic_unsigned.ALL;
USE WORK.ALL;

ENTITY dop IS
PORT(
        xrst        : in  std_logic;
        mclk        : in  std_logic;
        bclk        : in  std_logic;
        lrck        : in  std_logic;
        data        : in  std_logic;
        bck_dsdck   : out std_logic;
        lrck_dsdr   : out std_logic;
        data_dsdl   : out std_logic;
        dop_valid   : out std_logic;
        dop_locked  : out std_logic
);
END dop;

ARCHITECTURE RTL OF dop IS

    ---------------------------------------------------------------------------
    -- Assumption:
    --   I2S 32bit slot, upper 24bit valid.
    --   DoP word:
    --     bit[23:16] = marker 0x05 / 0xFA
    --     bit[15:0]  = DSD data
    ---------------------------------------------------------------------------

    constant WORD_BITS      : integer := 24;
    constant SLOT_BITS      : integer := 32;

    constant MARK_05        : std_logic_vector(7 downto 0) := X"05";
    constant MARK_FA        : std_logic_vector(7 downto 0) := X"FA";

    -- lock / unlock hysteresis
    constant LOCK_COUNT_MAX : integer := 8;
    constant BAD_COUNT_MAX  : integer := 4;

    signal lrck_d           : std_logic;
    signal bit_cnt          : integer range 0 to SLOT_BITS-1;

    signal shreg            : std_logic_vector(23 downto 0);
    signal left_word        : std_logic_vector(23 downto 0);

    signal expect_marker    : std_logic_vector(7 downto 0);
    signal good_count       : integer range 0 to LOCK_COUNT_MAX;
    signal bad_count        : integer range 0 to BAD_COUNT_MAX;

    signal dop_lock_i       : std_logic;

    -- DSD serializer
    signal dsd_clk_i        : std_logic;
    signal dsd_l_i          : std_logic;
    signal dsd_r_i          : std_logic;

    signal dsd_div          : integer range 0 to 3;
    signal dsd_bit_cnt      : integer range 0 to 15;

    signal dsd_shift_l      : std_logic_vector(15 downto 0);
    signal dsd_shift_r      : std_logic_vector(15 downto 0);
    signal dsd_next_l       : std_logic_vector(15 downto 0);
    signal dsd_next_r       : std_logic_vector(15 downto 0);
    signal dsd_load_pending : std_logic;

begin

    ---------------------------------------------------------------------------
    -- Output mux
    --
    -- PCM:
    --   pass through BCLK/LRCK/DATA.
    --
    -- DoP locked:
    --   output native DSD style signals.
    --   bck_dsdck = DSD clock
    --   lrck_dsdr = DSD right data
    --   data_dsdl = DSD left data
    ---------------------------------------------------------------------------

    bck_dsdck  <= bclk      when dop_lock_i = '0' else dsd_clk_i;
    lrck_dsdr  <= lrck      when dop_lock_i = '0' else dsd_r_i;
    data_dsdl  <= data      when dop_lock_i = '0' else dsd_l_i;

    dop_valid  <= dop_lock_i;
    dop_locked <= dop_lock_i;

    ---------------------------------------------------------------------------
    -- Main process
    --   - I2S 24bit word receiver
    --   - DoP marker detector
    --   - DSD payload extraction
    --   - DSD serializer
    ---------------------------------------------------------------------------

    process(xrst, bclk)
        variable v_word     : std_logic_vector(23 downto 0);
        variable v_lmark    : std_logic_vector(7 downto 0);
        variable v_rmark    : std_logic_vector(7 downto 0);
        variable v_marker_ok: boolean;

        variable v_shift_l  : std_logic_vector(15 downto 0);
        variable v_shift_r  : std_logic_vector(15 downto 0);
    begin
        if xrst = '0' then

            lrck_d           <= '0';
            bit_cnt          <= 0;
            shreg            <= (others => '0');
            left_word        <= (others => '0');

            expect_marker    <= MARK_05;
            good_count       <= 0;
            bad_count        <= 0;
            dop_lock_i       <= '0';

            dsd_clk_i        <= '0';
            dsd_l_i          <= '0';
            dsd_r_i          <= '0';
            dsd_div          <= 0;
            dsd_bit_cnt      <= 0;

            dsd_shift_l      <= (others => '0');
            dsd_shift_r      <= (others => '0');
            dsd_next_l       <= (others => '0');
            dsd_next_r       <= (others => '0');
            dsd_load_pending <= '0';

        elsif rising_edge(bclk) then

            -------------------------------------------------------------------
            -- DSD serializer
            --
            -- For 32bit slot I2S:
            --   BCLK = Fs * 64
            --   DSDCLK = Fs * 16
            -- so:
            --   DSDCLK = BCLK / 4
            --
            -- DSD64:
            --   Fs carrier = 176.4kHz
            --   BCLK       = 11.2896MHz
            --   DSDCLK     = 2.8224MHz
            --
            -- DSD128:
            --   Fs carrier = 352.8kHz
            --   BCLK       = 22.5792MHz
            --   DSDCLK     = 5.6448MHz
            --
            -- DSD256:
            --   Fs carrier = 705.6kHz
            --   BCLK       = 45.1584MHz
            --   DSDCLK     = 11.2896MHz
            -------------------------------------------------------------------

            if dop_lock_i = '1' then

                if dsd_div = 3 then
                    dsd_div <= 0;
                else
                    dsd_div <= dsd_div + 1;
                end if;

                if dsd_div = 0 then
                    dsd_clk_i <= '0';

                    v_shift_l := dsd_shift_l;
                    v_shift_r := dsd_shift_r;

                    -- Load next 16bit DSD block at the beginning of a block.
                    if dsd_bit_cnt = 0 then
                        if dsd_load_pending = '1' then
                            v_shift_l := dsd_next_l;
                            v_shift_r := dsd_next_r;
                            dsd_load_pending <= '0';
                        end if;
                    end if;

                    -- MSB first.
                    -- This preserves the order of the DoP payload as it appears
                    -- in the I2S 24bit word.
                    dsd_l_i <= v_shift_l(15);
                    dsd_r_i <= v_shift_r(15);

                    dsd_shift_l <= v_shift_l(14 downto 0) & '0';
                    dsd_shift_r <= v_shift_r(14 downto 0) & '0';

                    if dsd_bit_cnt = 15 then
                        dsd_bit_cnt <= 0;
                    else
                        dsd_bit_cnt <= dsd_bit_cnt + 1;
                    end if;

                elsif dsd_div = 2 then
                    dsd_clk_i <= '1';
                end if;

            else
                dsd_clk_i        <= '0';
                dsd_l_i          <= '0';
                dsd_r_i          <= '0';
                dsd_div          <= 0;
                dsd_bit_cnt      <= 0;
                dsd_shift_l      <= (others => '0');
                dsd_shift_r      <= (others => '0');
                dsd_load_pending <= '0';
            end if;

            -------------------------------------------------------------------
            -- I2S receiver
            --
            -- I2S has 1 BCLK delay after LRCK edge.
            -- Therefore, when LRCK changes, this clock is not used as MSB.
            -- The next BCLK edge starts bit_cnt = 0.
            -------------------------------------------------------------------

            if lrck /= lrck_d then

                lrck_d  <= lrck;
                bit_cnt <= 0;
                shreg   <= (others => '0');

            else

                if bit_cnt < WORD_BITS then
                    v_word := shreg(22 downto 0) & data;
                    shreg  <= v_word;

                    -- Completed 24bit word
                    if bit_cnt = WORD_BITS-1 then

                        if lrck = '0' then

                            -- Left channel word
                            left_word <= v_word;

                        else

                            -- Right channel word.
                            -- Check L/R DoP markers together.
                            v_lmark := left_word(23 downto 16);
                            v_rmark := v_word(23 downto 16);

                            v_marker_ok := false;

                            if (v_lmark = expect_marker) and
                               (v_rmark = expect_marker) then
                                v_marker_ok := true;
                            end if;

                            if v_marker_ok = true then

                                -- Valid DoP frame.
                                if good_count < LOCK_COUNT_MAX then
                                    good_count <= good_count + 1;
                                end if;

                                bad_count <= 0;

                                if good_count >= LOCK_COUNT_MAX-1 then
                                    dop_lock_i <= '1';
                                end if;

                                -- Marker alternates every stereo sample.
                                if expect_marker = MARK_05 then
                                    expect_marker <= MARK_FA;
                                else
                                    expect_marker <= MARK_05;
                                end if;

                                -- Store extracted DSD payload.
                                dsd_next_l       <= left_word(15 downto 0);
                                dsd_next_r       <= v_word(15 downto 0);
                                dsd_load_pending <= '1';

                            else

                                -- Not expected marker.
                                -- To make acquisition easier, restart sequence if
                                -- both channels already look like a valid marker.
                                if (v_lmark = MARK_05) and (v_rmark = MARK_05) then
                                    expect_marker <= MARK_FA;
                                    good_count    <= 1;
                                    bad_count     <= 0;

                                elsif (v_lmark = MARK_FA) and (v_rmark = MARK_FA) then
                                    expect_marker <= MARK_05;
                                    good_count    <= 1;
                                    bad_count     <= 0;

                                else
                                    good_count <= 0;

                                    if dop_lock_i = '1' then
                                        if bad_count < BAD_COUNT_MAX then
                                            bad_count <= bad_count + 1;
                                        end if;

                                        if bad_count >= BAD_COUNT_MAX-1 then
                                            dop_lock_i       <= '0';
                                            bad_count        <= 0;
                                            dsd_load_pending <= '0';
                                        end if;
                                    else
                                        bad_count <= 0;
                                    end if;

                                    expect_marker <= MARK_05;
                                end if;

                            end if;

                        end if;

                    end if;
                end if;

                if bit_cnt < SLOT_BITS-1 then
                    bit_cnt <= bit_cnt + 1;
                else
                    bit_cnt <= SLOT_BITS-1;
                end if;

            end if;

        end if;
    end process;

end RTL;