library work;
use work.DataStructures.all;
library ieee;
use ieee.std_logic_1164.all;

entity core is
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
end core;

architecture a1 of core is
	component cannon is
	generic (
		-- cannon move speed
		speed : integer;

		-- cannon start position
		start_pos_x : integer;
		start_pos_y : integer;

		-- screen working area borders
		screen_top : integer;
		screen_bottom : integer
	);
	port (
		-- INPUT
		--clock
		clk : in std_logic;

		-- move signals
		up : in std_logic;
		down : in std_logic;

		-- synchronous reset
		core_reset : in std_logic;

		-- OUTPUT
		-- current position of the cannon
		coords_out : out Coordinates
	);
	end component;

	component queue is
		generic (
			--size of fifo
			depth : integer;
			-- speed of shells
			update_period_in_clk : integer;
			-- shells flight direction (1 - left_to_right, -1 - right_to_left)
			direction : integer
		);
		port (
			-- INPUT
			--clock
			clk : in std_logic;
			--reset
			queue_reset : in std_logic;
			--enable read
			pop_enabled : in std_logic;
			--enable write
			push_enabled : in std_logic;
			--input data
			data_in : in Coordinates;
	
			-- OUTPUT
			-- top element
			data_top : out Coordinates;
			-- all elements
			data_all : out ArrayOfShells
		);
	end component;

	component ships is
		generic (
			-- depth of fifo
			size : integer := 5;
			-- speed of ships
			update_period_in_clk : integer := 20;
			-- screen parameters
			screen_w : integer;
			screen_h : integer;
	
			-- position of ships (0 - left side, 1 - right side)
			reverse : integer
		);
		port (
			-- INPUT
			-- clock
			clk : in std_logic;
			-- reset 
			core_reset : in std_logic;
			-- start of ship initialization
			start_init : in std_logic;
			-- index of ship to delete
			ship_to_delete : in integer;
	
			-- OUTPUT
			-- all elements
			ships_all : out ShipArray
		);
	end component;


	signal cannon_1_fire_inner : std_logic := '0';
	signal cannon_2_fire_inner : std_logic := '0';
	
	signal shells_1_remove_top : std_logic := '0';
	signal shells_2_remove_top : std_logic := '0';

	-- playing area borders
	constant first_border_coord_inner : Coordinates := (x => screen_w/20, y => screen_h/12);
	constant second_border_coord_inner : Coordinates := (x => screen_w/20 * 19, y => screen_h/12 * 11);

	-- inner signals for transfer
	signal cannon_1_pos_inner : Coordinates := (x => 0, y => 0);
	signal cannon_2_pos_inner : Coordinates := (x => 0, y => 0);
	signal shells_1_top_inner : Coordinates;
	signal shells_2_top_inner : Coordinates;
	signal ships_1_inner : ShipArray := (others => (pos1 => (x => - 100, y => - 100), ship_type => destroyer));
	signal ships_2_inner : ShipArray := (others => (pos1 => (x => - 100, y => - 100), ship_type => destroyer));

	
	signal ship_to_delete_1_inner : integer := 9999;
	signal ship_to_delete_2_inner : integer := 9999;
begin

	cannon_1 : cannon
	generic map(
		speed => 100 * game_speed,
		start_pos_x => (first_border_coord_inner.x + 0),
		start_pos_y => (first_border_coord_inner.y + second_border_coord_inner.y)/2,
		screen_top => (first_border_coord_inner.y + 0),
		screen_bottom => (second_border_coord_inner.y + 0)

	)
	port map(
		-- input
		clk => clk,
		up => cannon_1_up,
		down => cannon_1_down,
		core_reset => core_reset,
		-- output
		coords_out => cannon_1_pos_inner
	);

	cannon_2 : cannon
	generic map(
		speed => 100 * game_speed,
		start_pos_x => (second_border_coord_inner.x - 0),
		start_pos_y => (first_border_coord_inner.y + second_border_coord_inner.y)/2,
		screen_top => (first_border_coord_inner.y + 0),
		screen_bottom => (second_border_coord_inner.y + 0)

	)
	port map(
		-- input
		clk => clk,
		up => cannon_2_up,
		down => cannon_2_down,
		core_reset => core_reset,
		-- output
		coords_out => cannon_2_pos_inner
	);

	shells_1 : queue
	generic map(
		depth => 10,
		update_period_in_clk => 50 * game_speed,
		direction => 1
	)
	port map(
		-- input
		clk => clk,
		queue_reset => queue_reset,
		pop_enabled => shells_1_remove_top, 
		push_enabled => cannon_1_fire_inner, 
		data_in => cannon_1_pos_inner, 

		-- output
		data_top => shells_1_top_inner,
		data_all => shells_1_out
	);

	shells_2 : queue
	generic map(
		depth => 10,
		update_period_in_clk => 50 * game_speed,
		direction => - 1
	)
	port map(
		-- input
		clk => clk,
		queue_reset => queue_reset,
		pop_enabled => shells_2_remove_top, 
		push_enabled => cannon_2_fire_inner, 
		data_in => cannon_2_pos_inner, 

		-- output
		data_top => shells_2_top_inner,
		data_all => shells_2_out
	);

	ships_1 : ships
	generic map(
		size => 5,
		update_period_in_clk => 50 * game_speed,
		screen_w => screen_w,
		screen_h => screen_h,
		reverse => 1
	)
	port map(
		-- input
		clk => clk,
		core_reset => core_reset,
		ship_to_delete => ship_to_delete_1_inner,
		start_init => start_init,
		-- output
		ships_all => ships_1_inner
	);

	ships_2 : ships
	generic map(
		size => 5,
		update_period_in_clk => 50 * game_speed,
		screen_w => screen_w,
		screen_h => screen_h,
		reverse => 0
	)
	port map(
		-- input
		clk => clk,
		core_reset => core_reset,
		ship_to_delete => ship_to_delete_2_inner,
		start_init => start_init,

		-- output
		ships_all => ships_2_inner
	);

	-- 1 player --
	-- fire
	process (clk)
		-- fire rate
		variable ticks_before_next_fire : integer := 10_000 * game_speed;
		-- current ticks from last fire
		variable ticks_from_last_fire : integer := ticks_before_next_fire;
	begin
		if (rising_edge(clk)) then
			if (ticks_from_last_fire < ticks_before_next_fire) then
				ticks_from_last_fire := ticks_from_last_fire + 1;
			end if;
			--all other time dont fire
			cannon_1_fire_inner <= '0';

			-- fire when the player wants and the player can
			if (cannon_1_fire = '1' and ticks_from_last_fire = ticks_before_next_fire) then
				ticks_from_last_fire := 0;

				cannon_1_fire_inner <= '1';
			end if;
		end if;
	end process;

	-- score and colision logic
	process (clk)
		-- variable for delay of shell removal
		variable ticks : integer := 0;
		-- temporal score
		variable score_tmp : integer := 0;
	begin
		if (rising_edge(clk)) then
			if (core_reset = '1') then
				score_tmp := 0;
			else
				ticks := ticks + 1;
				shells_1_remove_top <= '0';
				ship_to_delete_1_inner <= 9999;

				-- we need a delay because the Shell queue changes state not immideatly, but after 3 cycles
				if (ticks = 5) then
					ticks := 0;
					-- remove shell when it flew out of the playing area
					if (shells_1_top_inner.x > second_border_coord_inner.x) then
						shells_1_remove_top <= '1';
					end if;
					-- check that top shell hits any ship
					for i in 0 to 4 loop
						if (shells_1_top_inner.x < (ships_1_inner(i).pos1.x + ships_1_inner(i).ship_type.ship_image_width)
							and shells_1_top_inner.x > (ships_1_inner(i).pos1.x) and shells_1_top_inner.y < (ships_1_inner(i).pos1.y + ships_1_inner(i).ship_type.ship_image_height) and shells_1_top_inner.y > (ships_1_inner(i).pos1.y)) then
							-- if hits, remove top shell and ship that was hitted, change score by value of ship
							shells_1_remove_top <= '1';
							ship_to_delete_1_inner <= i;
							score_tmp := score_tmp + ships_1_inner(i).ship_type.value;
							-- if score falls below 0, set it to 0
							if (score_tmp < 0) then
								score_tmp := 0;
							end if;
						end if;
					end loop;
				end if;
			end if;
			score_1 <= score_tmp;
		end if;
	end process;

	-- 2 player --
	-- fire
	process (clk)
		-- fire rate
		variable ticks_before_next_fire : integer := 10_000 * game_speed;
		-- current ticks from last fire
		variable ticks_from_last_fire : integer := ticks_before_next_fire;
	begin
		if (rising_edge(clk)) then
			if (ticks_from_last_fire < ticks_before_next_fire) then
				ticks_from_last_fire := ticks_from_last_fire + 1;
			end if;
			--all other time dont fire
			cannon_2_fire_inner <= '0';

			-- fire when the player wants and the player can
			if (cannon_2_fire = '1' and ticks_from_last_fire = ticks_before_next_fire) then
				ticks_from_last_fire := 0;

				cannon_2_fire_inner <= '1';
			end if;
		end if;
	end process;

	-- score and colision logic
	process (clk)
		-- variable for delay of shell removal
		variable ticks : integer := 0;
		-- temporal score
		variable score_tmp : integer := 0;
	begin
		if (rising_edge(clk)) then
			if (core_reset = '1') then
				score_tmp := 0;
			else
				ticks := ticks + 1;
				shells_2_remove_top <= '0';
				ship_to_delete_2_inner <= 9999;

				-- we need a delay because the Shell queue changes state not immideatly, but after 3 cycles
				if (ticks = 5) then
					ticks := 0;
					-- remove shell when it flew out of the playing area
					if (shells_2_top_inner.x < first_border_coord_inner.x) then
						shells_2_remove_top <= '1';
					end if;
					-- check that top shell hits any ship
					for i in 0 to 4 loop
						if (shells_2_top_inner.x < (ships_2_inner(i).pos1.x + ships_2_inner(i).ship_type.ship_image_width)
							and shells_2_top_inner.x > (ships_2_inner(i).pos1.x) and shells_2_top_inner.y < (ships_2_inner(i).pos1.y + ships_2_inner(i).ship_type.ship_image_height) and shells_2_top_inner.y > (ships_2_inner(i).pos1.y)) then
							-- if hits, remove top shell and ship that was hitted, change score by value of ship
							shells_2_remove_top <= '1';
							ship_to_delete_2_inner <= i;
							score_tmp := score_tmp + ships_2_inner(i).ship_type.value;
							-- if score falls below 0, set it to 0
							if (score_tmp < 0) then
								score_tmp := 0;
							end if;
						end if;
					end loop;
				end if;
			end if;
			score_2 <= score_tmp;
		end if;
	end process;


	-- send inner signals to out signals
	first_border_coord <= first_border_coord_inner;
	second_border_coord <= second_border_coord_inner;

	cannon_1_pos_out <= cannon_1_pos_inner;
	cannon_2_pos_out <= cannon_2_pos_inner;
	ships_1_out <= ships_1_inner;
	ships_2_out <= ships_2_inner;

	audio_play_explosion_1 <= shells_1_remove_top;
	audio_play_explosion_2 <= shells_2_remove_top;


	audio_play_fire_1 <= cannon_1_fire_inner;
	audio_play_fire_2 <= cannon_2_fire_inner;
end a1;