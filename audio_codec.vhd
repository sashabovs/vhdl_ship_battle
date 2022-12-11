library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.DataStructures.all;
use work.sine_package.all;

entity audio_codec is
	port (
		----------WM8731 pins-----
		AUD_BCLK : out std_logic;
		AUD_XCK : out std_logic;
		AUD_ADCLRCK : out std_logic;
		AUD_ADCDAT : in std_logic;
		AUD_DACLRCK : out std_logic;
		AUD_DACDAT : out std_logic;

		---------FPGA pins-----

		clock_12pll : in std_logic;
		clock_50 : in std_logic;
		reset : in std_logic;
		FPGA_I2C_SCLK : out std_logic;
		FPGA_I2C_SDAT : inout std_logic;
		audio_play_fire_1 : in std_logic;
		audio_play_fire_2 : in std_logic;
		audio_play_explosion_1 : in std_logic;
		audio_play_explosion_2 : in std_logic

	);

end audio_codec;

architecture main of audio_codec is

	signal bitprsc : integer range 0 to 4 := 0;
	signal aud_mono : std_logic_vector(31 downto 0) := (others => '0');
	signal read_addr : integer range 0 to 240254 := 0;
	signal ROM_ADDR : std_logic_vector(17 downto 0);
	signal ROM_OUT : std_logic_vector(15 downto 0) := x"BBFF";
	-- signal clock_12pll : std_logic;
	signal WM_i2c_busy : std_logic;
	signal WM_i2c_done : std_logic;
	signal WM_i2c_send_flag : std_logic;
	signal WM_i2c_data : std_logic_vector(15 downto 0);
	signal DA_CLR : std_logic := '0';
	signal temp_out_fire_1 : signed(15 downto 0);
	signal temp_out_explosion_1 : signed(15 downto 0);
	signal temp_out_fire_2 : signed(15 downto 0);
	signal temp_out_explosion_2 : signed(15 downto 0);
	component aud_gen is
		port (
			aud_clock_12 : in std_logic;
			aud_bk : out std_logic;
			aud_dalr : out std_logic;
			aud_dadat : out std_logic;
			aud_data_in : in std_logic_vector(31 downto 0)
		);
	end component aud_gen;

	component i2c is
		port (
			i2c_busy : out std_logic;
			i2c_scl : out std_logic;
			i2c_send_flag : in std_logic;
			i2c_sda : inout std_logic;
			i2c_addr : in std_logic_vector(7 downto 0);
			i2c_done : out std_logic;
			i2c_data : in std_logic_vector(15 downto 0);
			i2c_clock_50 : in std_logic
		);

	end component i2c;


begin

	sound : component aud_gen
		port map(
			aud_clock_12 => clock_12pll,
			aud_bk => AUD_BCLK,
			aud_dalr => DA_CLR,
			aud_dadat => AUD_DACDAT,
			aud_data_in => aud_mono

		);

		WM8731 : component i2c
			port map(
				i2c_busy => WM_i2c_busy,
				i2c_scl => FPGA_I2C_SCLK,
				i2c_send_flag => WM_i2c_send_flag,
				i2c_sda => FPGA_I2C_SDAT,
				i2c_addr => "00110100",
				i2c_done => WM_i2c_done,
				i2c_data => WM_i2c_data,
				i2c_clock_50 => clock_50
			);
			AUD_XCK <= clock_12pll;
			AUD_DACLRCK <= DA_CLR;

			process (clock_12pll)
			begin

				if rising_edge(clock_12pll) then

					if (reset = '1') then--------reset
						--read_addr<=0;
						--bitprsc<=0;
						aud_mono <= (others => '0');
					else
						aud_mono(15 downto 0) <= std_logic_vector(temp_out_fire_1/2 + temp_out_explosion_1/2);----mono sound
						aud_mono(31 downto 16) <= std_logic_vector(temp_out_fire_2/2 + temp_out_explosion_2/2);
					end if;
				end if;
			end process;

			process (clock_50)
				-- variable sleep : integer := 1000;
				-- variable sleep_to_next : integer := 55_000_000;

				-- variable sleep_sec : integer := 50_000;
				-- variable sleep_cur : integer := sleep;
				-- variable v_tstep : integer := 0;
				-- variable quarter_num : std_logic := '0';
				-- variable quarter_sign : integer := 1;
				-- variable stage : integer := 0;

				-- variable ampl_mult : integer := 1;
				-- variable ampl_div : integer := 1;

				variable soundData_1 : AudioTypeForFire := (sleep => 100, sleep_sec => 50_000, sleep_cur => 100, v_tstep => 128, quarter_num => '0', quarter_sign => 1, temp_out => (others => '0'), finished => '1');
				variable soundData_2 : AudioTypeForFire := (sleep => 100, sleep_sec => 50_000, sleep_cur => 100, v_tstep => 128, quarter_num => '0', quarter_sign => 1, temp_out => (others => '0'), finished => '1');

			begin

				if rising_edge (clock_50) then

					if (audio_play_fire_1 = '1') then
						soundData_1.finished := '0';
					end if;

					if (audio_play_fire_2 = '1') then
						soundData_2.finished := '0';
					end if;
					if (soundData_1.finished = '0') then
						soundData_1 := PlayFireSound(soundData_1);
					end if;

					if (soundData_2.finished = '0') then
						soundData_2 := PlayFireSound(soundData_2);
					end if;

					temp_out_fire_1 <= soundData_1.temp_out;
					temp_out_fire_2 <= soundData_2.temp_out;
				end if;
			end process;

			process (clock_50)

				-- variable sleep : integer := 1000;
				-- variable sleep_to_next : integer := 50_000_000;
				-- variable sleep_sec : integer := 50_000;
				-- variable sleep_cur : integer := sleep;
				-- variable v_tstep : integer := 0;
				-- variable quarter_num : std_logic := '0';
				-- variable quarter_sign : integer := 1;
				-- variable stage : integer := 0;

				-- variable ampl_mult : integer := 1;
				-- variable ampl_div : integer := 1;

				variable soundData_1 : AudioTypeForExplosion := (sleep => 100, sleep_sec => 50_000, sleep_cur => 100, v_tstep => 128, quarter_num => '0', quarter_sign => 1, stage => 0, ampl_mult => 0, ampl_div => 1, temp_out => (others => '0'), finished => '1');
				variable soundData_2 : AudioTypeForExplosion := (sleep => 100, sleep_sec => 50_000, sleep_cur => 100, v_tstep => 128, quarter_num => '0', quarter_sign => 1, stage => 0, ampl_mult => 0, ampl_div => 1, temp_out => (others => '0'), finished => '1');
			begin

				if rising_edge (clock_50) then

					if (audio_play_explosion_1 = '1') then
						soundData_1.finished := '0';
					end if;

					if (audio_play_explosion_2 = '1') then
						soundData_2.finished := '0';
					end if;
					if (soundData_1.finished = '0') then
						soundData_1 := PlayExplosionSound(soundData_1);
					end if;

					if (soundData_2.finished = '0') then
						soundData_2 := PlayExplosionSound(soundData_2);
					end if;

					temp_out_explosion_1 <= soundData_1.temp_out;
					temp_out_explosion_2 <= soundData_2.temp_out;

				end if;
			end process;

			process (clock_50)
				type states is (RESET, ACTIVE_INTERFACE, POWER_ON, SET_DIGITAL_INTERFACE, HEADPFONE_VOLUME, USB_MODE, ENABLE_DAC_TO_LINEOUT, UNMUTE_DAC, FINISH);
				variable stage : states := RESET;
				variable sleep : integer := 500_000;
				variable is_command_transfer_finished : std_logic := '1';
				variable num_finished : integer := 0;
			begin
				if rising_edge(clock_50) then
					if (WM_i2c_busy = '1') then
						WM_i2c_send_flag <= '0';
					end if;

					if (WM_i2c_done = '1') then
						if (is_command_transfer_finished = '0') then
							num_finished := num_finished + 1;
						end if;
						is_command_transfer_finished := '1';
					end if;

					if (sleep > 0) then
						sleep := sleep - 1;
					end if;

					if (sleep = 0 and is_command_transfer_finished = '1') then
						is_command_transfer_finished := '0';
						sleep := 500_000;
						if (stage = RESET) then
							---reset
							WM_i2c_data(15 downto 9) <= "0001111";
							WM_i2c_data(8 downto 0) <= "000000000";
							WM_i2c_send_flag <= '1';
							stage := ACTIVE_INTERFACE;
						elsif (stage = ACTIVE_INTERFACE) then
							---activ interface 
							WM_i2c_data(15 downto 9) <= "0001001";
							WM_i2c_data(8 downto 0) <= "111111111";
							WM_i2c_send_flag <= '1';
							stage := POWER_ON;
						elsif (stage = POWER_ON) then
							---ADC of, DAC on, Linout ON, Power ON
							WM_i2c_data(15 downto 9) <= "0000110";
							WM_i2c_data(8 downto 0) <= "000000111";

							WM_i2c_send_flag <= '1';
							stage := SET_DIGITAL_INTERFACE;
						elsif (stage = SET_DIGITAL_INTERFACE) then
							----Digital Interface: DSP, 16 bit, slave mode
							WM_i2c_data(15 downto 9) <= "0000111";
							WM_i2c_data(8 downto 0) <= "000010011";
							WM_i2c_send_flag <= '1';
							stage := HEADPFONE_VOLUME;
						elsif (stage = HEADPFONE_VOLUME) then
							---HEADPHONE VOLUME
							WM_i2c_data(15 downto 9) <= "0000010";
							WM_i2c_data(8 downto 0) <= "101111001";
							WM_i2c_send_flag <= '1';
							stage := USB_MODE;
						elsif (stage = USB_MODE) then
							---USB mode
							WM_i2c_data(15 downto 9) <= "0001000";
							WM_i2c_data(8 downto 0) <= "000000001";
							WM_i2c_send_flag <= '1';
							stage := ENABLE_DAC_TO_LINEOUT;
						elsif (stage = ENABLE_DAC_TO_LINEOUT) then
							---Enable DAC to LINOUT
							WM_i2c_data(15 downto 9) <= "0000100";
							WM_i2c_data(8 downto 0) <= "000010010";
							WM_i2c_send_flag <= '1';
							stage := UNMUTE_DAC;
						elsif (stage = UNMUTE_DAC) then
							---un mute DAC 
							WM_i2c_data(15 downto 9) <= "0000101";
							WM_i2c_data(8 downto 0) <= "000000000";
							WM_i2c_send_flag <= '1';
							stage := FINISH;
						end if;
					end if;

				end if;
			end process;
		end main;