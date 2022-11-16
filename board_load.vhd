library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

library work;
use work.CommonPckg.all;
use work.SdCardPckg.all;
use work.DataStructures.all;

entity board_load is
	port (
		-- input
		game_clk : in std_logic;

		reset : in std_logic;

		up_1 : in std_logic;
		down_1 : in std_logic;
		fire_1 : in std_logic;

		-- output
		red : out std_logic_vector(7 downto 0); --red magnitude output to DAC
		green : out std_logic_vector(7 downto 0); --green magnitude output to DAC
		blue : out std_logic_vector(7 downto 0);

		n_blank : out std_logic; --direct blacking output to DAC
		n_sync : out std_logic;
		h_sync : out std_logic; --horiztonal sync pulse
		v_sync : out std_logic; --vertical sync pulse

		pixel_clk : out std_logic;
		--card
		cs_bo : out std_logic; -- Active-low chip-select.
		sclk_o : out std_logic; -- Serial clock to SD card.
		mosi_o : out std_logic; -- Serial data output to SD card.
		miso_i : in std_logic; -- Serial data input from SD card.

		-- LCD bus
		LCD_RS : out std_logic;
		LCD_E : out std_logic;
		LCD_RW : out std_logic;
		LCD_Data : inout std_logic_vector(7 downto 0);
		LED : out std_logic_vector(7 downto 0)

	);
end board_load;

architecture a1 of board_load is
	constant screen_w : integer := 1920;
	constant screen_h : integer := 1080;

	signal vga_clk_inner : std_logic;

	signal rd_inner : std_logic;
	signal continue_inner : std_logic;
	signal reset_inner : std_logic := '0';
	signal addr_inner : std_logic_vector(31 downto 0) := x"00000000"; -- Block address.
	signal data_o_inner : std_logic_vector(7 downto 0) := x"00"; -- Data read from block.
	signal busy_o_inner : std_logic; -- High when controller is busy performing some operation.
	signal hndShk_i_inner : std_logic; -- High when host has data to give or has taken data.
	signal hndShk_o_inner : std_logic; -- High when controller has taken data or has data to give.

	signal error_o_inner : std_logic_vector(15 downto 0) := (others => NO);

	--signal graphic_memory_inner : GraphicMemoryType;

	signal graphic_memory_data_inner : std_logic_vector (7 downto 0);
	signal graphic_memory_write_address_inner : integer range 0 to 20_000;
	signal graphic_memory_we_inner : std_logic;

	--signal disp_ena_test : std_logic := '0';

	--constant clk_vga_period : time := 5 ns;

	--------------------------------
	type LCD_Data_t is record
		Data : std_logic_vector(7 downto 0);
		IsCommand : std_logic;
	end record;

	type RAM_t is array(0 to 13) of LCD_Data_t;
	type State_t is (LCD_Reset, LCD_WaitDisplay, LCD_Send, LCD_Finish);

	signal CurrentState : State_t := LCD_Reset;

	-- Create a small RAM with some data for the LCD.
	signal RAM : RAM_t := ((x"48", '0'), (x"65", '0'), (x"6C", '0'), (x"6C", '0'), (x"6F", '0'),
	(x"2C", '0'), (x"20", '0'), (x"57", '0'), (x"6F", '0'), (x"72", '0'),
	(x"6C", '0'), (x"64", '0'), (x"21", '0'), (x"02", '1'));

	signal LCD_Data_inner : std_logic_vector(7 downto 0);
	signal LCD_Address : UNSIGNED(6 downto 0) := "0000010";
	signal LCD_Ready : std_logic;
	signal LCD_Valid : std_logic := '0';
	signal LCD_SendCommand : std_logic := '0';
	signal LCD_AddressSet : std_logic := '0';

	component LCD_Controller is
		generic (
			CLOCK_FREQ : integer := 125
		);
		port (
			Clock : in std_logic;
			nReset : in std_logic;

			Data : in std_logic_vector(7 downto 0) := (others => '0');

			Ready : out std_logic;
			Valid : in std_logic;

			SendCommand : in std_logic;

			LCD_RS : out std_logic;
			LCD_E : out std_logic;
			LCD_RW : out std_logic;
			LCD_Data : inout std_logic_vector(7 downto 0)
		);
	end component;
	--------------------------------

	component main is
		generic (
			game_speed : integer;
			screen_w : integer;
			screen_h : integer
		);
		port (
			-- input
			pixel_clk : in std_logic;
			game_clk : in std_logic;

			reset : in std_logic;

			up_1 : in std_logic;
			down_1 : in std_logic;
			fire_1 : in std_logic;

			--graphic_memory : in GraphicMemoryType;
			data : in std_logic_vector (7 downto 0);
			write_address : in integer range 0 to 20_000;
			we : in std_logic;

			-- output
			red : out std_logic_vector(7 downto 0); --red magnitude output to DAC
			green : out std_logic_vector(7 downto 0); --green magnitude output to DAC
			blue : out std_logic_vector(7 downto 0);

			n_blank : out std_logic; --direct blacking output to DAC
			n_sync : out std_logic;
			h_sync : out std_logic; --horiztonal sync pulse
			v_sync : out std_logic; --vertical sync pulse

			disp_ena : out std_logic
		);
	end component;

	component altpll0 is
		port (
			inclk0 : in std_logic := '0';
			c0 : out std_logic
		);
	end component;

	component SdCardCtrl is
		generic (
			FREQ_G : real := 50.0; -- Master clock frequency (MHz).
			INIT_SPI_FREQ_G : real := 0.4; -- Slow SPI clock freq. during initialization (MHz).
			SPI_FREQ_G : real := 25.0; -- Operational SPI freq. to the SD card (MHz).
			BLOCK_SIZE_G : natural := 512; -- Number of bytes in an SD card block or sector.
			CARD_TYPE_G : CardType_t := SD_CARD_E -- Type of SD card connected to this controller.
		);
		port (
			-- Host-side interface signals.
			clk_i : in std_logic; -- Master clock.
			reset_i : in std_logic := NO; -- active-high, synchronous  reset.
			rd_i : in std_logic := NO; -- active-high read block request.
			wr_i : in std_logic := NO; -- active-high write block request.
			continue_i : in std_logic := NO; -- If true, inc address and continue R/W.
			addr_i : in std_logic_vector(31 downto 0) := x"00000000"; -- Block address.
			data_i : in std_logic_vector(7 downto 0) := x"00"; -- Data to write to block.
			data_o : out std_logic_vector(7 downto 0) := x"00"; -- Data read from block.
			busy_o : out std_logic; -- High when controller is busy performing some operation.
			hndShk_i : in std_logic; -- High when host has data to give or has taken data.
			hndShk_o : out std_logic; -- High when controller has taken data or has data to give.
			error_o : out std_logic_vector(15 downto 0) := (others => NO);
			-- I/O signals to the external SD card.
			cs_bo : out std_logic := HI; -- Active-low chip-select.
			sclk_o : out std_logic := LO; -- Serial clock to SD card.
			mosi_o : out std_logic := HI; -- Serial data output to SD card.
			miso_i : in std_logic := ZERO -- Serial data input from SD card.
		);
	end component;

begin
	main_test : main
	generic map(
		game_speed => 10_000,
		screen_w => screen_w,
		screen_h => screen_h
	)
	port map(
		-- input
		pixel_clk => vga_clk_inner,
		game_clk => game_clk,

		reset => reset,

		up_1 => up_1,
		down_1 => down_1,
		fire_1 => not fire_1,

		--graphic_memory => graphic_memory_inner,

		data => graphic_memory_data_inner,
		write_address => graphic_memory_write_address_inner,
		we => graphic_memory_we_inner,

		-- output
		red => red, --red magnitude output to DAC
		green => green, --green magnitude output to DAC
		blue => blue,

		n_blank => n_blank, --direct blacking output to DAC
		n_sync => n_sync,
		h_sync => h_sync, --horiztonal sync pulse
		v_sync => v_sync --vertical sync pulse

		--disp_ena => disp_ena_test
	);

	altpll0_vga : altpll0 port map(

		inclk0 => game_clk,
		c0 => vga_clk_inner

	);

	sd_card : SdCardCtrl
	generic map(
		FREQ_G => 50.0, -- Master clock frequency (MHz).
		INIT_SPI_FREQ_G => 0.4, -- Slow SPI clock freq. during initialization (MHz).
		SPI_FREQ_G => 25.0, -- Operational SPI freq. to the SD card (MHz).
		BLOCK_SIZE_G => 512, -- Number of bytes in an SD card block or sector.
		CARD_TYPE_G => SDHC_CARD_E -- Type of SD card connected to this controller.
	)
	port map(
		-- Host-side interface signals.
		clk_i => game_clk,
		reset_i => reset_inner,
		rd_i => rd_inner,
		--wr_i => '0',
		continue_i => continue_inner,
		addr_i => addr_inner,
		--data_i : in std_logic_vector(7 downto 0) := x"00"; -- Data to write to block.
		data_o => data_o_inner,
		busy_o => busy_o_inner,
		hndShk_i => hndShk_i_inner,
		hndShk_o => hndShk_o_inner,
		error_o => error_o_inner,
		-- I/O signals to the external SD card.
		cs_bo => cs_bo,
		sclk_o => sclk_o,
		mosi_o => mosi_o,
		miso_i => miso_i
	);
	pixel_clk <= vga_clk_inner;

	----------------------------------------------

	LCD : LCD_Controller
	-- generic map(
	-- 	CLOCK_FREQ => 125
	-- )
	port map(
		Clock => game_clk,
		nReset => '1',
		Data => LCD_Data_inner,
		Ready => LCD_Ready,
		Valid => LCD_Valid,
		SendCommand => LCD_SendCommand,
		LCD_RS => LCD_RS,
		LCD_E => LCD_E,
		LCD_RW => LCD_RW,
		LCD_Data => LCD_Data
	);

	process (game_clk, reset)
		variable Index : integer := 0;
		variable speed : integer := 0;
	begin
		-- if (reset_inner = '1') then
		-- 	CurrentState <= LCD_Reset;
		-- els
		if (rising_edge(game_clk)) then
			if (speed < 50_000_000) then
				speed := speed + 1;
			else
				speed := 0;
				case CurrentState is

					when LCD_Reset =>
						LCD_Valid <= '0';
						LCD_Data_inner <= (others => '0');
						CurrentState <= LCD_WaitDisplay;

					when LCD_WaitDisplay =>
						LCD_Valid <= '0';

						if (LCD_Ready = '1') then
							if (LCD_AddressSet = '0') then
								LCD_AddressSet <= '1';
								LCD_SendCommand <= '1';
								LCD_Data_inner <= '1' & std_logic_vector(LCD_Address);
							else
								LCD_SendCommand <= RAM(Index).IsCommand;
								LCD_Data_inner <= RAM(Index).Data;
								Index := Index + 1;
							end if;

							LCD_Valid <= '1';
							CurrentState <= LCD_Send;
						else
							CurrentState <= LCD_WaitDisplay;
						end if;

					when LCD_Send =>
						if (LCD_Ready <= '0') then
							if (Index < RAM'length) then
								CurrentState <= LCD_WaitDisplay;
							else
								CurrentState <= LCD_Finish;
							end if;
						else
							CurrentState <= LCD_Send;
						end if;

					when LCD_Finish =>
						LCD_Valid <= '0';

				end case;
			end if;
		end if;
	end process;

	--LED(0) <= busy_o_inner;

	--LED <= std_logic_vector(to_unsigned(card_states'pos(state) + 1, 4));

	---------------------------------------------------------------------------

	process (game_clk)
		type card_states is (-- States of the SD card.
			RESET,
			WAIT_FOR_RESET_STARTS,
			END_OF_RESET,
			START_READ,
			WAIT_FOR_READ_STARTS,

			WAIT_FOR_HNDSHK_UP,
			WAIT_FOR_HNDSHK_DOWN,
			READ_END

		);
		variable state : card_states := RESET;
		variable data_addres : integer := 0;
		variable wait_ : integer := 0;
	begin
		if (rising_edge(game_clk)) then
			if (wait_ > 0) then
				wait_ := wait_ - 1;
			else
				wait_ := 50_000_000;
				-- initialization
				if (state = RESET) then
					reset_inner <= '1';
					state := WAIT_FOR_RESET_STARTS;
					wait_ := 0;
				elsif (state = WAIT_FOR_RESET_STARTS) then
					reset_inner <= '0';
					if (busy_o_inner = '1') then
						state := END_OF_RESET;
						
					end if;

					-- read data
				elsif (state = END_OF_RESET) then
				
					if (busy_o_inner = '0') then
						if (error_o_inner = x"0000") then
							state := START_READ;
						else
							state := RESET;
						end if;
					end if;
				elsif (state = START_READ) then
					rd_inner <= '1';
					addr_inner <= x"00000001";
					state := WAIT_FOR_READ_STARTS;
				elsif (state = WAIT_FOR_READ_STARTS) then
					if (busy_o_inner = '1') then
						rd_inner <= '0';
						addr_inner <= x"00000000";
						state := WAIT_FOR_HNDSHK_UP;
					end if;

				elsif (state = WAIT_FOR_HNDSHK_UP) then
					if (busy_o_inner = '0') then
						state := READ_END;

					else
						if (hndShk_o_inner = '1') then

							graphic_memory_write_address_inner <= data_addres;
							--graphic_memory_we_inner <= '1';
							graphic_memory_data_inner <= data_o_inner;

							data_addres := data_addres + 1;

							hndShk_i_inner <= '1';
							state := WAIT_FOR_HNDSHK_DOWN;
						end if;
					end if;
				elsif (state = WAIT_FOR_HNDSHK_DOWN) then
					if (hndShk_o_inner = '0') then
						hndShk_i_inner <= '0';
						state := WAIT_FOR_HNDSHK_UP;
					end if;
				elsif (state = READ_END) then
					-- END
				end if;
			end if;
		end if;

		LED <= std_logic_vector(to_unsigned(card_states'pos(state) + 1, 8));
	end process;

end a1;