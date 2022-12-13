library work;
use work.DataStructures.all;

library ieee;
use ieee.std_logic_1164.all;

entity main is
	generic (
		game_speed : integer := 1000;
		-- screen size
		screen_w : integer;
		screen_h : integer
	);
	port (
		-- INPUT
		-- clocks
		pixel_clk : in std_logic;
		game_clk : in std_logic;

		-- video reset
		reset : in std_logic;

		-- control player 1
		up_1 : in std_logic;
		down_1 : in std_logic;
		fire_1 : in std_logic;

		-- control player 2
		up_2 : in std_logic;
		down_2 : in std_logic;
		fire_2 : in std_logic;

		-- state control
		start_game : in std_logic;
		stop_game : in std_logic;

		-- sram data
		data : in std_logic_vector (15 downto 0);

		load_progress : in integer;

		-- OUTPUT
		--red magnitude output to DAC
		red : out std_logic_vector(7 downto 0); 
		--green magnitude output to DAC
		green : out std_logic_vector(7 downto 0); 
		--blue magnitude output to DAC
		blue : out std_logic_vector(7 downto 0);

		--direct blacking output to DAC
		n_blank : out std_logic; 
		--sync-on-green output to DAC
		n_sync : out std_logic;
		--horiztonal sync pulse
		h_sync : out std_logic; 
		--vertical sync pulse
		v_sync : out std_logic; 

		-- sram memory index for reading
		sram_addres_read : out std_logic_vector(19 downto 0);

		-- signals for audio triger
		audio_play_explosion_1 : out std_logic;
		audio_play_explosion_2 : out std_logic;
		audio_play_fire_1 : out std_logic;
		audio_play_fire_2 : out std_logic
	);
end main;

architecture a1 of main is
	-- transfer signals
	signal disp_ena_inner : std_logic; 
	signal column_inner : integer; 
	signal row_inner : integer; 

	-- reset for vga
	signal reset_low : std_logic := '1';

	-- transfer signals
	signal cannon_pos_1_inner : Coordinates;
	signal cannon_pos_2_inner : Coordinates;
	signal shells_1_inner : ArrayOfShells;
	signal shells_2_inner : ArrayOfShells;
	signal ships_1_inner : ShipArray;
	signal ships_2_inner : ShipArray;

	signal score_1_inner : integer := 0;
	signal score_2_inner : integer := 0;

	signal first_border_coord_inner : Coordinates;
	signal second_border_coord_inner : Coordinates;

	-- in-game timer 
	signal game_time_inner : integer := 0;
	-- state
	signal game_state_inner : GameStates;

	-- signals for reset and re-initialization
	signal core_reset_inner : std_logic := '0';
	signal queue_reset_inner : std_logic := '0';
	signal start_init_inner : std_logic := '0';

	component vga_controller is
		generic (
			h_pulse : integer := 44; --horiztonal sync pulse width in pixels
			h_bp : integer := 148; --horiztonal back porch width in pixels
			h_pixels : integer := screen_w; --horiztonal display width in pixels
			h_fp : integer := 88; --horiztonal front porch width in pixels
			h_pol : std_logic := '1'; --horizontal sync pulse polarity (1 = positive, 0 = negative)
			v_pulse : integer := 5; --vertical sync pulse width in rows
			v_bp : integer := 36; --vertical back porch width in rows
			v_pixels : integer := screen_h; --vertical display width in rows
			v_fp : integer := 4; --vertical front porch width in rows
			v_pol : std_logic := '1'); --vertical sync pulse polarity (1 = positive, 0 = negative)
		port (
			-- input
			pixel_clk : in std_logic; --pixel clock at frequency of VGA mode being used
			reset_n : in std_logic; --active low asycnchronous reset

			-- output
			disp_ena : out std_logic; --display enable ('1' = display time, '0' = blanking time)
			column : out integer; --horizontal pixel coordinate
			row : out integer; --vertical pixel coordinate

			n_blank : out std_logic; --direct blacking output to DAC
			n_sync : out std_logic; --sync-on-green output to DAC
			h_sync : out std_logic; --horiztonal sync pulse
			v_sync : out std_logic --vertical sync pulse
		);
	end component;

	component hw_image_generator is
		generic (
			-- screen size
			screen_w : integer;
			screen_h : integer
		);
		port (
			-- INPUT
			-- clock
			pixel_clk : in std_logic;
			--display enable ('1' = display time, '0' = blanking time)
			disp_ena : in std_logic; 
			--row pixel coordinate
			row : in integer; 
			--column pixel coordinate
			column : in integer; 
	
			-- play area borders
			first_border_coord : in Coordinates;
			second_border_coord : in Coordinates;
	
			-- elements to draw
			cannon_1_pos : in Coordinates;
			cannon_2_pos : in Coordinates;
			shells_1 : in ArrayOfShells;
			shells_2 : in ArrayOfShells;
			ships_1 : in ShipArray;
			ships_2 : in ShipArray;
	
			-- score
			score_1 : in integer;
			score_2 : in integer;
	
			-- antwort from sram (2 byte)
			data : in std_logic_vector (15 downto 0);
			-- progress of loading of SDCard
			load_progress : in integer;
	
			-- in-game timer
			game_time : in integer;
			-- state of the game
			game_state : in GameStates;
	
			-- OUTPUT
			-- sram addres 
			sram_addres_read : out std_logic_vector(19 downto 0);
	
			--red magnitude output to DAC
			red : out std_logic_vector(7 downto 0) := (others => '0'); 
			--green magnitude output to DAC
			green : out std_logic_vector(7 downto 0) := (others => '0'); 
			--blue magnitude output to DAC
			blue : out std_logic_vector(7 downto 0) := (others => '0') 
		);
	end component;

	component core is
		generic (
			game_speed : integer;
			-- screen size
			screen_w : integer := 100;
			screen_h : integer := 100
		);
		port (
			-- INPUT
			-- clock
			clk : in std_logic;
	
			-- cannon control signals
			cannon_1_up : in std_logic;
			cannon_1_down : in std_logic;
			cannon_1_fire : in std_logic;
			cannon_2_up : in std_logic;
			cannon_2_down : in std_logic;
			cannon_2_fire : in std_logic;
	
			-- resets signal
			core_reset : in std_logic;
			queue_reset : in std_logic;
	
			-- signal for starting of initialization
			start_init : in std_logic;
	
			-- OUTPUT
			-- signals for drawing
			cannon_1_pos_out : out Coordinates;
			cannon_2_pos_out : out Coordinates;
			shells_1_out : out ArrayOfShells;
			shells_2_out : out ArrayOfShells;
			ships_1_out : out ShipArray;
			ships_2_out : out ShipArray;
	
			-- score value for drawing
			score_1 : out integer;
			score_2 : out integer;
	
			-- points of border of playing area
			first_border_coord : out Coordinates;
			second_border_coord : out Coordinates;
	
			-- signals for audio triger
			audio_play_explosion_1 : out std_logic;
			audio_play_explosion_2 : out std_logic;
			audio_play_fire_1 : out std_logic;
			audio_play_fire_2 : out std_logic
		);
	end component;

begin
	-- set reset
	reset_low <= reset;

	
	-- if-else generate only in vhdl-2008
	-- generate object with exact parameters
	gen_vga_controller : if (screen_w = 800) generate
		vga_controller_1 : vga_controller
		generic map(
			h_pulse => 128,
			h_bp => 88,
			h_fp => 40,
			h_pol => '1',
			v_pulse => 4,
			v_bp => 23,
			v_fp => 1,
			v_pol => '1'
		)
		port map(
			-- input
			pixel_clk => pixel_clk,
			reset_n => reset_low,

			-- output
			disp_ena => disp_ena_inner,
			column => column_inner,
			row => row_inner,

			n_blank => n_blank,
			n_sync => n_sync,
			h_sync => h_sync,
			v_sync => v_sync
		);
	end generate gen_vga_controller;

	hw_image_generator_1 : hw_image_generator
	generic map(
		screen_w => screen_w,
		screen_h => screen_h
	)
	port map(
		-- input
		pixel_clk => pixel_clk,

		disp_ena => disp_ena_inner,
		row => row_inner,
		column => column_inner,

		first_border_coord => first_border_coord_inner,
		second_border_coord => second_border_coord_inner,

		cannon_1_pos => cannon_pos_1_inner,
		cannon_2_pos => cannon_pos_2_inner,
		shells_1 => shells_1_inner,
		shells_2 => shells_2_inner,
		ships_1 => ships_1_inner,
		ships_2 => ships_2_inner,

		score_1 => score_1_inner,
		score_2 => score_2_inner,

		data => data,
	
		load_progress => load_progress,

		game_time => game_time_inner,
		game_state => game_state_inner,

		-- output
		red => red,
		green => green,
		blue => blue,

		sram_addres_read => sram_addres_read
	);

	core_1 : core
	generic map(
		game_speed => game_speed,
		screen_w => screen_w,
		screen_h => screen_h
	)
	port map(
		clk => game_clk,
		cannon_1_up => up_1,
		cannon_1_down => down_1,
		cannon_1_fire => fire_1,
		cannon_2_up => up_2,
		cannon_2_down => down_2,
		cannon_2_fire => fire_2,
		core_reset => core_reset_inner,
		queue_reset => queue_reset_inner,
		start_init => start_init_inner,

		cannon_1_pos_out => cannon_pos_1_inner,
		cannon_2_pos_out => cannon_pos_2_inner,
		shells_1_out => shells_1_inner,
		shells_2_out => shells_2_inner,
		ships_1_out => ships_1_inner,
		ships_2_out => ships_2_inner,

		score_1 => score_1_inner,
		score_2 => score_2_inner,

		first_border_coord => first_border_coord_inner,
		second_border_coord => second_border_coord_inner,

		audio_play_explosion_1 => audio_play_explosion_1,
		audio_play_explosion_2 => audio_play_explosion_2,
		audio_play_fire_1 => audio_play_fire_1,
		audio_play_fire_2 => audio_play_fire_2
	);


	-- state control
	process (game_clk)
		variable game_state : GameStates := GAME_LOAD;

		-- current in-game time
		variable game_cur_time_sec : integer := 0;
		-- max game time
		constant game_time_sec : integer := 60;
		-- 1 second for 50 MHz clock
		variable ticks_in_sec : integer := 50_000_000;
		-- increment "game_cur_time_sec" when ticks = ticks_in_sec
		variable ticks : integer := 0;
		-- variable to slow down the transition from state to state
		variable sleep : integer := 0;
	begin
		if (rising_edge(game_clk)) then
			-- reset off
			core_reset_inner <= '0';
			queue_reset_inner <= '0';

			-- loading....
			if (game_state = GAME_LOAD) then
				if (load_progress >= 175760) then
					game_state := GAME_START;

				end if;
			-- waiting for player input
			elsif (game_state = GAME_START) then
				if (start_game = '1') then
					-- reset
					core_reset_inner <= '1';
					queue_reset_inner <= '1';

					game_state := WAIT_FOR_GAME;
					ticks := 0;
				end if;
			-- pre-game delay
			elsif (game_state = WAIT_FOR_GAME) then
				if (sleep > ticks_in_sec) then
					-- initialize ships
					start_init_inner <= '1';
					-- set in-game timer
					game_cur_time_sec := game_time_sec;

					game_state := GAME_PLAY;
					sleep := 0;
				end if;
				sleep := sleep + 1;
			-- game
			elsif (game_state = GAME_PLAY) then
				-- when time ends, end the game
				if (game_cur_time_sec <= 0) then
					game_state := GAME_END;
				else
					-- reduce the timer every second
					ticks := ticks + 1;
					if (ticks = ticks_in_sec) then
						ticks := 0;
						game_cur_time_sec := game_cur_time_sec - 1;
					end if;
				end if;
			-- results
			elsif (game_state = GAME_END) then
				-- clear shell arrays
				queue_reset_inner <= '1';

				-- after game delay
				if (sleep > ticks_in_sec) then
					-- restart
					if (start_game = '1') then
						game_state := GAME_PLAY;
						game_cur_time_sec := game_time_sec;
						core_reset_inner <= '1';
						sleep := 0;
					-- back to main window
					elsif (stop_game = '1') then
						game_state := GAME_START;
						core_reset_inner <= '1';
						sleep := 0;
					end if;
				else 
					sleep := sleep + 1;
				end if;
			end if;

			-- set signals
			game_time_inner <= game_cur_time_sec;
			game_state_inner <= game_state;
		end if;
	end process;

end a1;