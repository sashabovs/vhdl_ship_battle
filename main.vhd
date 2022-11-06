library work;
use work.DataStructures.resArray;
use work.DataStructures.Coordinates;
use work.DataStructures.ShipType;
use work.DataStructures.ShipObject;
use work.DataStructures.ShipArray;

library ieee;
use ieee.std_logic_1164.all;

entity main is
	generic(
		game_speed: integer := 1000;
	
		screen_w: integer := 100;
		screen_h: integer := 100
	);
	port (
		-- input
		pixel_clk : in std_logic;
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

	signal cannon_pos_1_inner : Coordinates;
	signal shells_1_inner : resArray;
	signal ships_1_inner : ShipArray;

	signal cannon_pos_2_inner : Coordinates;

	-- signal temp_vga_clk : std_logic;
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
	signal data_all_test : resArray;

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
	
			cannon_1_pos : in Coordinates;
			shells_1 : in resArray;
			ships_1 : in ShipArray;

			-- output
			red : out std_logic_vector(7 downto 0) := (others => '0'); --red magnitude output to DAC
			green : out std_logic_vector(7 downto 0) := (others => '0'); --green magnitude output to DAC
			blue : out std_logic_vector(7 downto 0) := (others => '0') --blue magnitude output to DAC
		);
	end component;

	component core is
		generic (	
			game_speed: integer;
			screen_w: integer;
			screen_h: integer
		);
		port (
		-- input
		clk : in std_logic;
		cannon_1_up : in std_logic;
		cannon_1_down : in std_logic;
		cannon_1_fire : in std_logic;

		-- output
		cannon_1_pos_out : out Coordinates;
		shells_1_out : out resArray;
		ships_1_out: out ShipArray
		);
	end component;
begin
	reset_low <= reset;

	disp_ena <= disp_ena_inner;

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

		
		cannon_1_pos => cannon_pos_1_inner,
		shells_1 => shells_1_inner,
		ships_1 => ships_1_inner,

		-- output
		red => red,
		green => green,
		blue => blue
	);

	core_1 : core
	generic map(
		game_speed => game_speed,
		screen_w => screen_w,
		screen_h => screen_h
	)
	port map(
	clk	=> game_clk,
	cannon_1_up => up_1,
	cannon_1_down => down_1,
	cannon_1_fire => fire_1,

	cannon_1_pos_out => cannon_pos_1_inner,
	shells_1_out => shells_1_inner,
	ships_1_out => ships_1_inner
	);

	-- clk_vga_c <= temp_vga_clk;

end a1;