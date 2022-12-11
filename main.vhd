library work;
use work.DataStructures.all;

library ieee;
use ieee.std_logic_1164.all;

entity main is
	generic (
		game_speed : integer := 1000;

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

		up_2 : in std_logic;
		down_2 : in std_logic;
		fire_2 : in std_logic;

		start_game : in std_logic;
		stop_game : in std_logic;

		data : in std_logic_vector (15 downto 0);

		-- we : in std_logic;

		load_progress : in integer;

		-- output
		red : out std_logic_vector(7 downto 0); --red magnitude output to DAC
		green : out std_logic_vector(7 downto 0); --green magnitude output to DAC
		blue : out std_logic_vector(7 downto 0);

		n_blank : out std_logic; --direct blacking output to DAC
		n_sync : out std_logic;
		h_sync : out std_logic; --horiztonal sync pulse
		v_sync : out std_logic; --vertical sync pulse

		-- for testing
		disp_ena : out std_logic;

		sram_addres_read : out std_logic_vector(19 downto 0);
		LED : out std_logic_vector(7 downto 0);


		audio_play_explosion_1 : out std_logic;
		audio_play_explosion_2 : out std_logic;
		audio_play_fire_1 : out std_logic;
		audio_play_fire_2 : out std_logic
	);
end main;

architecture a1 of main is

	


	signal disp_ena_inner : std_logic; --display enable ('1' = display time, '0' = blanking time)
	signal column_inner : integer; --horizontal pixel coordinate
	signal row_inner : integer; --vertical pixel coordinate

	signal reset_low : std_logic := '1';

	signal cannon_pos_1_inner : Coordinates;
	signal cannon_pos_2_inner : Coordinates;
	signal shells_1_inner : ArrayOfShells;
	signal shells_2_inner : ArrayOfShells;
	signal ships_1_inner : ShipArray;
	signal ships_2_inner : ShipArray;

	signal up_inner : std_logic := '0';
	signal down_inner : std_logic := '0';
	signal fire_inner : std_logic := '0';

	signal enr_test : std_logic := '0';
	signal enw_test : std_logic := '0';
	signal data_in_test : Coordinates;

	signal data_out_test : Coordinates;
	signal data_top_test : Coordinates;
	signal enpt_test : std_logic := '0';
	signal full_test : std_logic := '0';

	signal score_1_inner : integer := 0;
	signal score_2_inner : integer := 0;

	signal first_border_coord_inner : Coordinates;
	signal second_border_coord_inner : Coordinates;

	signal game_time_inner : integer := 0;
	signal game_state_inner : GameStates;

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
			screen_w : integer;
			screen_h : integer
		);
		port (
			-- input
			disp_ena : in std_logic; --display enable ('1' = display time, '0' = blanking time)
			row : in integer; --row pixel coordinate
			column : in integer; --column pixel coordinate

			first_border_coord : in Coordinates;
			second_border_coord : in Coordinates;

			cannon_1_pos : in Coordinates;
			cannon_2_pos : in Coordinates;
			shells_1 : in ArrayOfShells;
			shells_2 : in ArrayOfShells;
			ships_1 : in ShipArray;
			ships_2 : in ShipArray;

			score_1 : in integer;
			score_2 : in integer;

			data : in std_logic_vector (15 downto 0);
			game_clk : in std_logic;
			pixel_clk : in std_logic;
			-- we : in std_logic;

			load_progress : in integer;

			game_time : integer;
			game_state : GameStates;

			-- output
			sram_addres_read : out std_logic_vector(19 downto 0);

			red : out std_logic_vector(7 downto 0) := (others => '0'); --red magnitude output to DAC
			green : out std_logic_vector(7 downto 0) := (others => '0'); --green magnitude output to DAC
			blue : out std_logic_vector(7 downto 0) := (others => '0'); --blue magnitude output to DAC

			LED : out std_logic_vector(7 downto 0)
		);
	end component;

	component core is
		generic (
			game_speed : integer;
			screen_w : integer;
			screen_h : integer
		);
		port (
			-- input
			-- pixel_clk : in std_logic;
			clk : in std_logic;
			cannon_1_up : in std_logic;
			cannon_1_down : in std_logic;
			cannon_1_fire : in std_logic;
			cannon_2_up : in std_logic;
			cannon_2_down : in std_logic;
			cannon_2_fire : in std_logic;
			core_reset : in std_logic;
			queue_reset : in std_logic;
			start_init : in std_logic;

			-- output
			cannon_1_pos_out : out Coordinates;
			cannon_2_pos_out : out Coordinates;
			shells_1_out : out ArrayOfShells;
			shells_2_out : out ArrayOfShells;
			ships_1_out : out ShipArray;
			ships_2_out : out ShipArray;

			score_1 : out integer;
			score_2 : out integer;

			first_border_coord : out Coordinates;
			second_border_coord : out Coordinates;

			audio_play_explosion_1 : out std_logic;
			audio_play_explosion_2 : out std_logic;
			audio_play_fire_1 : out std_logic;
			audio_play_fire_2 : out std_logic
		);
	end component;

begin
	reset_low <= reset;

	disp_ena <= disp_ena_inner;

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
		game_clk => game_clk,
		pixel_clk => pixel_clk,
		-- we => we,

		load_progress => load_progress,

		game_time => game_time_inner,
		game_state => game_state_inner,

		-- output
		red => red,
		green => green,
		blue => blue,

		sram_addres_read => sram_addres_read,

		LED => LED
	);

	core_1 : core
	generic map(
		game_speed => game_speed,
		screen_w => screen_w,
		screen_h => screen_h
	)
	port map(
		-- pixel_clk => pixel_clk,
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

	process (game_clk)
		variable game_state : GameStates := GAME_LOAD;

		variable game_cur_time_sec : integer := 0;
		variable game_time_sec : integer := 60;
		variable ticks_in_sec : integer := 50_000_000;
		variable ticks : integer := 0;

		variable sleep : integer := 0;
	begin
		if (rising_edge(game_clk)) then

			core_reset_inner <= '0';
			queue_reset_inner <= '0';

			if (game_state = GAME_LOAD) then
				if (load_progress >= 175760) then
					game_state := GAME_START;

				end if;
			elsif (game_state = GAME_START) then
				game_cur_time_sec := game_time_sec;
				if (start_game = '1') then
					core_reset_inner <= '1';
					queue_reset_inner <= '1';

					game_state := WAIT_FOR_GAME;
					ticks := 0;
				end if;
			elsif (game_state = WAIT_FOR_GAME) then
				if (sleep > ticks_in_sec) then
					start_init_inner <= '1';

					game_state := GAME_PLAY;
					sleep := 0;
				end if;
				sleep := sleep + 1;
			elsif (game_state = GAME_PLAY) then

			

				if (game_cur_time_sec <= 0) then
					game_state := GAME_END;


				else
					ticks := ticks + 1;
					if (ticks = ticks_in_sec) then
						ticks := 0;
						game_cur_time_sec := game_cur_time_sec - 1;
					end if;
				end if;
			elsif (game_state = GAME_END) then
				queue_reset_inner <= '1';

				if (sleep > ticks_in_sec) then
					if (start_game = '1') then
						game_state := GAME_PLAY;
						game_cur_time_sec := game_time_sec;
						core_reset_inner <= '1';
						sleep := 0;
					elsif (stop_game = '1') then
						game_state := GAME_START;
						core_reset_inner <= '1';
						sleep := 0;
					end if;
				end if;
				sleep := sleep + 1;
			end if;

			game_time_inner <= game_cur_time_sec;
			game_state_inner <= game_state;
		end if;
	end process;

end a1;