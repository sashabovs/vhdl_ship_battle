library work;
use work.DataStructures.resArray;
use work.DataStructures.Pair;

library ieee;
use ieee.std_logic_1164.all;

entity main is
	generic(
		screen_w: integer := 100;
		screen_h: integer := 100
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

		-- for testing
		disp_ena : out std_logic
	);
end main;

architecture a1 of main is
	signal disp_ena_inner : std_logic; --display enable ('1' = display time, '0' = blanking time)
	signal column_inner : integer; --horizontal pixel coordinate
	signal row_inner : integer; --vertical pixel coordinate
	-- signal cannon_x_1 : integer;
	-- signal cannon_y_1 : integer;

	-- signal shells_1 : resArray;

	signal reset_low : std_logic := '1';

	-- signal ground : std_logic := '0';

	-- signal temp_x : integer := 10;
	-- signal temp_y : integer := 10;

	-- signal temp_vga_clk : std_logic;
	signal up_inner : std_logic := '0';
	signal down_inner : std_logic := '0';
	signal fire_inner : std_logic := '0';

	signal enr_test : std_logic := '0';
	signal enw_test : std_logic := '0';
	signal data_in_test : Pair;

	signal data_out_test : Pair;
	signal data_top_test : Pair;
	signal enpt_test : std_logic := '0';
	signal full_test : std_logic := '0';
	signal data_all_test : resArray;

	component queue is
		generic (
			depth : integer := 10;
			update_period_in_clk : integer := 20
		);
		port (
			-- input
			clk : in std_logic;
			reset : in std_logic;
			pop_enabled : in std_logic; --enable pop,should be '0' when not in use.
			push_enabled : in std_logic; --enable push,should be '0' when not in use.
			data_in : in Pair;

			-- output
			data_out : out Pair;
			data_top : out Pair;

			fifo_empty : out std_logic;
			fifo_full : out std_logic;

			data_all : out resArray
		);
	end component;

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
			pixels_y : integer := 5; --row that first color will persist until
			pixels_x : integer := 5); --column that first color will persist until
		port (
			-- input
			disp_ena : in std_logic; --display enable ('1' = display time, '0' = blanking time)
			row : in integer; --row pixel coordinate
			column : in integer; --column pixel coordinate
			-- cannon_1_x : in integer;
			-- cannon_1_y : in integer;
			--shells : IN resArray;

			-- output
			red : out std_logic_vector(7 downto 0) := (others => '0'); --red magnitude output to DAC
			green : out std_logic_vector(7 downto 0) := (others => '0'); --green magnitude output to DAC
			blue : out std_logic_vector(7 downto 0) := (others => '0') --blue magnitude output to DAC
		);
	end component;

	-- component cannon is
	-- 	generic (
	-- 		speed : integer := 10
	-- 	);
	-- 	port (
	-- 		clk : in std_logic;
	-- 		up : in std_logic;
	-- 		down : in std_logic;

	-- 		x : out integer := 0; --row pixel coordinate
	-- 		y : out integer := 200); --column pixel coordinate
	-- end component;

	-- component core is

	-- 	port (
	-- 		clk : in std_logic;
	-- 		fire : in std_logic;
	-- 		cannon_1_x : in integer;
	-- 		cannon_1_y : in integer;
	-- 		shells : out resArray);

	-- end component;

	-- component altpll0 is
	-- 	port (
	-- 		areset : in std_logic := '0';
	-- 		inclk0 : in std_logic := '0';
	-- 		c0 : out std_logic
	-- 	);
	-- end component;


begin
	reset_low <= reset;

	up_inner <= up;
	down_inner <= down;
	fire_inner <= fire;

	disp_ena <= disp_ena_inner;

	-- altpll0_ob : altpll0 port map(
	-- 	areset => ground,
	-- 	inclk0 => clk,
	-- 	c0 => temp_vga_clk

	-- );

	vga_controller_1 : vga_controller port map(
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

	hw_image_generator_1 : hw_image_generator port map(
		-- input	
		disp_ena => disp_ena_inner,
		row => row_inner,
		column => column_inner,
		-- cannon_1_x => temp_x,
		-- cannon_1_y => temp_y,

		--shells => shells_1,

		-- output
		red => red,
		green => green,
		blue => blue
	);

	bullet_queue : queue port map(
		-- input
		clk => game_clk,

		reset => reset,
		pop_enabled => enr_test, --enable read,should be '0' when not in use.
		push_enabled => enw_test, --enable write,should be '0' when not in use.
		data_in => data_in_test, --input data

		-- output
		data_out => data_out_test, --output data
		data_top => data_top_test,

		fifo_empty => enpt_test, --set as '1' when the queue is empty
		fifo_full => full_test,

		data_all => data_all_test
	);

	--cannon_1: cannon port map(
	-- 	clk	    => game_clk,
	--	up	=> up,
	--	down	=> down,

	--   	x     => cannon_x_1,
	--  	y   => cannon_y_1
	--);

	--core_1:core port map(
	--clk	=> game_clk,
	--fire	=> fire,
	--	cannon_1_x => cannon_x_1,
	--	cannon_1_y => cannon_y_1,
	--	shells => shells_1

	--);

	-- clk_vga_c <= temp_vga_clk;

end a1;