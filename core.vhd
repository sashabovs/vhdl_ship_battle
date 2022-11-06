library work;
use work.DataStructures.Coordinates;
use work.DataStructures.resArray;

library ieee;
use ieee.std_logic_1164.all;

entity core is
	generic (
		game_speed : integer;
		screen_w : integer := 100;
		screen_h : integer := 100
	);
	port (
		-- input
		clk : in std_logic;
		cannon_1_up : in std_logic;
		cannon_1_down : in std_logic;
		cannon_1_fire : in std_logic;

		-- output
		cannon_1_pos_out : out Coordinates;
		shells_1_out : out resArray
	);
end core;

architecture a1 of core is
	component cannon is
		generic (
			speed : integer;
			start_pos_x : integer;
			start_pos_y : integer;

			screen_w : integer;
			screen_h : integer
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
			update_period_in_clk : integer
		);
		port (
			-- input
			clk : in std_logic;
			reset : in std_logic;
			pop_enabled : in std_logic; --enable read,should be '0' when not in use.
			push_enabled : in std_logic; --enable write,should be '0' when not in use.
			data_in : in Coordinates; --input data
			-- output
			data_out : out Coordinates; --output data
			data_top : out Coordinates;

			fifo_empty : out std_logic; --set as '1' when the queue is empty
			fifo_full : out std_logic; --set as '1' when the queue is full

			data_all : out resArray
		);
	end component;

	--signal cannon_1_pos_inner : Coordinates;
	signal cannon_1_fire_inner : std_logic := '0';
	signal pop : std_logic := '0';

	signal cannon_1_pos_inner : Coordinates;
	signal reset_inner : std_logic := '0';
	signal fifo_empty_inner : std_logic;
	signal fifo_full_inner : std_logic;
	signal data_out_inner : Coordinates;
	signal data_top_inner : Coordinates;
begin
	cannon_1 : cannon
	generic map(
		speed => 100 * game_speed,
		start_pos_x => 0,
		start_pos_y => screen_h/2,
		screen_w => screen_w,
		screen_h => screen_h

	)
	port map(
		-- input
		clk => clk,
		up => cannon_1_up,
		down => cannon_1_down,

		-- output
		coords_out => cannon_1_pos_inner
	);

	shells_1 : queue
	generic map(
		depth => 10,
		update_period_in_clk => 50 * game_speed

	)
	port map(
		-- input
		clk => clk,

		reset => reset_inner,
		pop_enabled => pop, --enable read,should be '0' when not in use.
		push_enabled => cannon_1_fire_inner, --enable write,should be '0' when not in use.
		data_in => cannon_1_pos_inner, --input data

		-- output
		data_out => data_out_inner, --output data
		data_top => data_top_inner,

		fifo_empty => fifo_empty_inner, --set as '1' when the queue is empty
		fifo_full => fifo_full_inner,

		data_all => shells_1_out
	);

	process (clk)
		variable firePos : Coordinates;
		variable ticks_before_next_fire : integer := 100_000 * game_speed;
		variable ticks_from_last_fire : integer := ticks_before_next_fire;
	begin
		if (rising_edge(clk)) then
			if (ticks_from_last_fire < ticks_before_next_fire) then
				ticks_from_last_fire := ticks_from_last_fire + 1;
			end if;

			cannon_1_fire_inner <= '0';
			pop <= '0';

			if (cannon_1_fire = '1' and ticks_from_last_fire = ticks_before_next_fire) then
				ticks_from_last_fire := 0;

				cannon_1_fire_inner <= '1';
				pop <= '0';
			end if;
		end if;
	end process;
	cannon_1_pos_out <= cannon_1_pos_inner;
end a1;