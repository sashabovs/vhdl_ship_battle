library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

library work;
use work.DataStructures.resArray;
use work.DataStructures.Pair;

entity vga_tb is
end vga_tb;

architecture test of vga_tb is
	constant screen_w : integer := 100;
	constant screen_h : integer := 100;

	constant clk_vga_period : time := 5 ns;
	signal clk_vga : std_logic := '0';

	constant clk_game_period : time := 20 ns;
	signal clk_game : std_logic := '0';

	signal reset_game : std_logic := '1';

	signal n_blank_test : std_logic; --direct blacking output to DAC
	signal n_sync_test : std_logic;
	signal h_sync_test : std_logic; --horiztonal sync pulse
	signal v_sync_test : std_logic; --vertical sync pulse

	signal red_test : std_logic_vector(7 downto 0); --red magnitude output to DAC
	signal green_test : std_logic_vector(7 downto 0); --green magnitude output to DAC
	signal blue_test : std_logic_vector(7 downto 0);

	signal up_test : std_logic := '0';
	signal down_test : std_logic := '1';
	signal fire_test : std_logic := '1';

	signal disp_ena_test : std_logic := '0';

	-- signal enr_test : std_logic := '0';
	-- signal enw_test : std_logic := '0';

	-- signal data_in_test : Pair;
	-- signal data_in_test_x : integer;
	-- signal data_in_test_y : integer;

	-- signal data_out_test : Pair;
	-- signal data_out_test_x : integer;
	-- signal data_out_test_y : integer;

	-- signal data_top_test : Pair;
	-- signal data_top_test_x : integer;
	-- signal data_top_test_y : integer;

	-- signal enpt_test : std_logic;
	-- signal full_test : std_logic;

	-- signal fire : std_logic := '1';

	-- signal data_all_test : resArray;

	type char_file is file of character;
	file output_buf : char_file;

	signal stop_simulation : std_logic := '0';
	component main is
		generic (
			screen_w : integer := 10;
			screen_h : integer := 10
		);
		port (
			-- input
			pixel_clk : in std_logic;
			game_clk : in std_logic;

			reset : in std_logic;

			up : in std_logic;
			down : in std_logic;
			fire : in std_logic;

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
begin
	main_test : main
	generic map(
		screen_w => screen_w,
		screen_h => screen_h
	)
	port map(
		-- input
		pixel_clk => clk_vga,
		game_clk => clk_game,

		reset => reset_game,

		up => up_test,
		down => down_test,
		fire => fire_test,

		-- output
		red => red_test, --red magnitude output to DAC
		green => green_test, --green magnitude output to DAC
		blue => blue_test,

		n_blank => n_blank_test, --direct blacking output to DAC
		n_sync => n_sync_test,
		h_sync => h_sync_test, --horiztonal sync pulse
		v_sync => v_sync_test, --vertical sync pulse

		disp_ena => disp_ena_test
	);

	-- fifo_test : fifo port map(
	-- 	clk => clk,

	-- 	reset => reset_game,
	-- 	pop_enabled => enr_test, --enable read,should be '0' when not in use.
	-- 	push_enabled => enw_test, --enable write,should be '0' when not in use.
	-- 	data_in => data_in_test, --input data
	-- 	data_out.x => data_out_test_x, --output data
	-- 	data_out.y => data_out_test_y, --output data
	-- 	data_top.x => data_top_test_x,
	-- 	data_top.y => data_top_test_y,

	-- 	fifo_empty => enpt_test, --set as '1' when the queue is empty
	-- 	fifo_full => full_test,

	-- 	data_all => data_all_test
	-- );

	-- game clock
	process
	begin
		for i in 0 to 1_000_00 loop
			clk_game <= '0';
			wait for clk_game_period/2; --for 0.5 ns signal is '0'.
			clk_game <= '1';
			wait for clk_game_period/2;
		end loop;
		stop_simulation <= '1';
		wait;
	end process;

	-- video clock (altpll mock) 
	process
	begin
		while (stop_simulation = '0') loop
			clk_vga <= '0';
			wait for clk_vga_period/2;
			clk_vga <= '1';
			wait for clk_vga_period/2;
		end loop;
		wait;
	end process;

	-- process (clk_game)
	-- 	variable firePos : Pair;
	-- 	variable ticks_from_last_fire : integer := 0;
	-- 	variable ticks_before_next_fire : integer := 5;
	-- begin
	-- 	if (rising_edge(clk)) then
	-- 		ticks_from_last_fire := ticks_from_last_fire + 1;

	-- 		enw_test <= '0';
	-- 		enr_test <= '0';

	-- 		if (fire = '1' and ticks_from_last_fire = ticks_before_next_fire) then
	-- 			ticks_from_last_fire := 0;

	-- 			firePos.x := 15;
	-- 			firePos.y := 20;

	-- 			data_in_test <= firePos;
	-- 			data_in_test_x <= firePos.x;
	-- 			data_in_test_y <= firePos.y;

	-- 			enw_test <= '1';
	-- 			enr_test <= '0';
	-- 		end if;
	-- 	end if;
	-- end process; 

	-- video file handler
	process
		variable w, h : std_logic_vector(15 downto 0);
		variable w1, w2, h1, h2 : std_logic_vector(7 downto 0);
	begin
		file_open(output_buf, "test_rgb.bin", write_mode);

		-- store picture size
		w := std_logic_vector (to_unsigned (screen_w, 16));
		h := std_logic_vector (to_unsigned (screen_h, 16));
		w1 := w(15 downto 8);
		w2 := w(7 downto 0);
		h1 := h(15 downto 8);
		h2 := h(7 downto 0);
		write(output_buf, character'val(to_integer(unsigned(w1))));
		write(output_buf, character'val(to_integer(unsigned(w2))));
		write(output_buf, character'val(to_integer(unsigned(h1))));
		write(output_buf, character'val(to_integer(unsigned(h2))));

		wait on stop_simulation;

		file_close(output_buf);
		wait;
	end process;

	-- store picture
	tb1 : process (clk_vga)
	begin
		if (rising_edge(clk_vga)) then
			if (disp_ena_test = '1') then
				write(output_buf, character'val(to_integer(unsigned(red_test))));
				write(output_buf, character'val(to_integer(unsigned(green_test))));
				write(output_buf, character'val(to_integer(unsigned(blue_test))));
			end if;
		end if;
	end process;

end test;