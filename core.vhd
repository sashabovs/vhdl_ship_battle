library work;
use work.DataStructures.all;


library ieee;
use ieee.std_logic_1164.all;

entity core is
	generic (
		game_speed : integer;
		screen_w : integer := 100;
		screen_h : integer := 100

		-- ship_1_image_width : integer;
		-- ship_1_image_height : integer
	);
	port (
		-- input
		pixel_clk : in std_logic;
		clk : in std_logic;
		cannon_1_up : in std_logic;
		cannon_1_down : in std_logic;
		cannon_1_fire : in std_logic;
		cannon_2_up : in std_logic;
		cannon_2_down : in std_logic;
		cannon_2_fire : in std_logic;

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
		second_border_coord : out Coordinates
	);
end core;

architecture a1 of core is
	component cannon is
		generic (
			speed : integer;
			start_pos_x : integer;
			start_pos_y : integer;

			screen_top : integer;
			screen_bottom : integer
		);
		port (
			-- input
			clk : in std_logic;
			up : in std_logic;
			down : in std_logic;

			-- output
			coords_out : out Coordinates
		);
	end component;

	component queue is
		generic (
			--depth of fifo
			depth : integer;
			update_period_in_clk : integer;
			direction : integer
		);
		port (
			-- input
			clk : in std_logic;
			reset : in std_logic;
			pop_enabled : in std_logic; --enable read,should be '0' when not in use.
			push_enabled : in std_logic; --enable write,should be '0' when not in use.
			data_in : in Coordinates; --input data
			-- output
			--data_out : out Coordinates; --output data
			data_top : out Coordinates;

			fifo_empty : out std_logic; --set as '1' when the queue is empty
			fifo_full : out std_logic; --set as '1' when the queue is full

			data_all : out ArrayOfShells
		);
	end component;

	component ships is
		generic (
			--depth of fifo
			size : integer := 10;
			update_period_in_clk : integer := 20;
			screen_w : integer;
			screen_h : integer;
			reverse : integer
		);
		port (
			-- input
			clk : in std_logic;
			reset : in std_logic;

			ship_to_delete : in integer;
			-- output
			ships_all : out ShipArray
		);
	end component;
	--signal cannon_1_pos_inner : Coordinates;
	signal cannon_1_fire_inner : std_logic := '0';
	signal cannon_2_fire_inner : std_logic := '0';
	signal shells_1_remove_top : std_logic := '0';
	signal shells_2_remove_top : std_logic := '0';

	signal first_border_coord_inner : Coordinates := (x => screen_w/20, y => screen_h/12);
	signal second_border_coord_inner : Coordinates := (x => screen_w/20 * 19, y => screen_h/12 * 11);

	signal cannon_1_pos_inner : Coordinates := (x => 0, y => 0);
	signal cannon_2_pos_inner : Coordinates := (x => 0, y => 0);
	signal reset_inner : std_logic := '0';
	signal fifo_empty_1_inner : std_logic;
	signal fifo_full_1_inner : std_logic;
	signal fifo_empty_2_inner : std_logic;
	signal fifo_full_2_inner : std_logic;
	--signal data_out_inner : Coordinates;
	signal shells_1_top_inner : Coordinates;
	signal shells_2_top_inner : Coordinates;
	--signal ships_1_inner : ShipArray := (others => (pos1 => (x => - 100, y => - 100), ship_type => (color => "000000000000001111111111", value => - 2, ship_image_width => 20, ship_image_height => 65)));
	--signal ships_2_inner : ShipArray := (others => (pos1 => (x => - 100, y => - 100), ship_type => (color => "000000000000001111111111", value => - 2, ship_image_width => 20, ship_image_height => 65)));
	signal ships_1_inner : ShipArray := (others => (pos1 => (x => - 100, y => - 100), ship_type => destroyer));
	signal ships_2_inner : ShipArray := (others => (pos1 => (x => - 100, y => - 100), ship_type => destroyer));
	signal ship_to_delete_1_inner : integer := 9999;
	signal ship_to_delete_2_inner : integer := 9999;

	signal score_1_inner : integer := 0;
	signal score_2_inner : integer := 0;

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
		--clk => pixel_clk,

		reset => reset_inner,
		pop_enabled => shells_1_remove_top, --enable read,should be '0' when not in use.
		push_enabled => cannon_1_fire_inner, --enable write,should be '0' when not in use.
		data_in => cannon_1_pos_inner, --input data

		-- output
		--data_out => data_out_inner, --output data
		data_top => shells_1_top_inner,

		fifo_empty => fifo_empty_1_inner, --set as '1' when the queue is empty
		fifo_full => fifo_full_1_inner,

		data_all => shells_1_out
	);

	shells_2 : queue
	generic map(
		depth => 10,
		update_period_in_clk => 50 * game_speed,
		direction => -1
	)
	port map(
		-- input
		clk => clk,
		--clk => pixel_clk,

		reset => reset_inner,
		pop_enabled => shells_2_remove_top, --enable read,should be '0' when not in use.
		push_enabled => cannon_2_fire_inner, --enable write,should be '0' when not in use.
		data_in => cannon_2_pos_inner, --input data

		-- output
		--data_out => data_out_inner, --output data
		data_top => shells_2_top_inner,

		fifo_empty => fifo_empty_2_inner, --set as '1' when the queue is empty
		fifo_full => fifo_full_2_inner,

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
		reset => reset_inner,
		ship_to_delete => ship_to_delete_1_inner,

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
		reset => reset_inner,
		ship_to_delete => ship_to_delete_2_inner,

		-- output
		ships_all => ships_2_inner
	);





	-- 1
	process (clk)
		variable firePos : Coordinates;
		variable ticks_before_next_fire : integer := 10_000 * game_speed;
		variable ticks_from_last_fire : integer := ticks_before_next_fire;
	begin
		if (rising_edge(clk)) then
			if (ticks_from_last_fire < ticks_before_next_fire) then
				ticks_from_last_fire := ticks_from_last_fire + 1;
			end if;

			cannon_1_fire_inner <= '0';

			if (cannon_1_fire = '1' and ticks_from_last_fire = ticks_before_next_fire) then
				ticks_from_last_fire := 0;

				cannon_1_fire_inner <= '1';

			end if;
		end if;
	end process;

	process (clk)
		variable ticks : integer := 0;
	begin
		if (rising_edge(clk)) then
			ticks := ticks + 1;
			shells_1_remove_top <= '0';
			ship_to_delete_1_inner <= 9999;

			-- we need a delay because the Shell queue changes state not immideatly, but after 3 cycles
			if (ticks = 5) then
				ticks := 0;
				if (shells_1_top_inner.x > second_border_coord_inner.x) then
					shells_1_remove_top <= '1';
				end if;
				-- check that top shell hits any ship
				for i in 0 to 4 loop
					if (shells_1_top_inner.x < (ships_1_inner(i).pos1.x + ships_1_inner(i).ship_type.ship_image_width)
						and shells_1_top_inner.x > (ships_1_inner(i).pos1.x) and shells_1_top_inner.y < (ships_1_inner(i).pos1.y + ships_1_inner(i).ship_type.ship_image_height) and shells_1_top_inner.y > (ships_1_inner(i).pos1.y)) then
						shells_1_remove_top <= '1';
						ship_to_delete_1_inner <= i;
						score_1_inner <= score_1_inner + ships_1_inner(i).ship_type.value;
						if(score_1_inner < 0) then
							score_1_inner <= 0;
						end if;
					end if;
				end loop;
			end if;

		end if;
	end process;




	-- 2
	process (clk)
		variable firePos : Coordinates;
		variable ticks_before_next_fire : integer := 10_000 * game_speed;
		variable ticks_from_last_fire : integer := ticks_before_next_fire;
	begin
		if (rising_edge(clk)) then
			if (ticks_from_last_fire < ticks_before_next_fire) then
				ticks_from_last_fire := ticks_from_last_fire + 1;
			end if;

			cannon_2_fire_inner <= '0';

			if (cannon_2_fire = '1' and ticks_from_last_fire = ticks_before_next_fire) then
				ticks_from_last_fire := 0;

				cannon_2_fire_inner <= '1';

			end if;
		end if;
	end process;

	process (clk)
		variable ticks : integer := 0;
	begin
		if (rising_edge(clk)) then
			ticks := ticks + 1;
			shells_2_remove_top <= '0';
			ship_to_delete_2_inner <= 9999;

			-- we need a delay because the Shell queue changes state not immideatly, but after 3 cycles
			if (ticks = 5) then
				ticks := 0;
				if (shells_2_top_inner.x < first_border_coord_inner.x) then
					shells_2_remove_top <= '1';
				end if;
				-- check that top shell hits any ship
				for i in 0 to 4 loop
					if (shells_2_top_inner.x < (ships_2_inner(i).pos1.x + ships_2_inner(i).ship_type.ship_image_width)
						and shells_2_top_inner.x > (ships_2_inner(i).pos1.x) and shells_2_top_inner.y < (ships_2_inner(i).pos1.y + ships_2_inner(i).ship_type.ship_image_height) and shells_2_top_inner.y > (ships_2_inner(i).pos1.y)) then
						shells_2_remove_top <= '1';
						ship_to_delete_2_inner <= i;
						score_2_inner <= score_2_inner + ships_2_inner(i).ship_type.value;
						if(score_2_inner < 0) then
							score_2_inner <= 0;
						end if;
					end if;
				end loop;
			end if;

		end if;
	end process;


	first_border_coord <= first_border_coord_inner;
	second_border_coord <= second_border_coord_inner;

	cannon_1_pos_out <= cannon_1_pos_inner;
	cannon_2_pos_out <= cannon_2_pos_inner;
	ships_1_out <= ships_1_inner;
	ships_2_out <= ships_2_inner;
	score_1 <= score_1_inner;
	score_2 <= score_2_inner;
end a1;