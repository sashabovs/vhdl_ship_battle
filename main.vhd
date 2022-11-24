library work;
use work.DataStructures.ArrayOfShells;
use work.DataStructures.Coordinates;
use work.DataStructures.ShipType;
use work.DataStructures.ShipObject;
use work.DataStructures.ShipArray;
use work.DataStructures.GraphicMemoryType;

library ieee;
use ieee.std_logic_1164.all;

entity main is
	generic(
		game_speed: integer := 1000;
	
		screen_w: integer;
		screen_h: integer
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

		--graphic_memory : in GraphicMemoryType;

		data : in std_logic_vector (15 downto 0);
		
		we : in std_logic;

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

		sram_addres_read	: out std_logic_vector(19 downto 0);
		LED : out std_logic_vector(7 downto 0)
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
	signal cannon_pos_2_inner : Coordinates;
	signal shells_1_inner : ArrayOfShells;
	signal shells_2_inner : ArrayOfShells;
	signal ships_1_inner : ShipArray;
	signal ships_2_inner : ShipArray;

	--signal cannon_pos_2_inner : Coordinates;

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
	
	signal score_1_inner : integer := 0;
	signal score_2_inner : integer := 0;

	signal first_border_coord_inner : Coordinates;
	signal second_border_coord_inner : Coordinates;

	--signal graphic_memory_inner : GraphicMemoryType;

	signal graphic_memory_read_address_inner : integer range 0 to 1300;
	signal graphic_memory_q_inner : std_logic_vector (31 downto 0);


	--signal ship_1_memory_begin_inner : integer := 0;

	--constant ship_1_image_width_inner : integer := 20;
	--constant ship_1_image_height_inner : integer := 65;
	

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

			--graphic_memory : in GraphicMemoryType;

			-- ship_1_memory_begin : in integer;
			-- ship_1_image_width : in integer;
			-- ship_1_image_height : in integer;

			data : in std_logic_vector (15 downto 0);
	 		-- write_address : in integer range 0 to 1300;
			 game_clk : in std_logic;
			 we : in std_logic;
			--graphic_memory_q : in std_logic_vector (31 downto 0);

			-- output
			--graphic_memory_read_address : out integer range 0 to 1300;
			sram_addres_read	: out std_logic_vector(19 downto 0);

			red : out std_logic_vector(7 downto 0) := (others => '0'); --red magnitude output to DAC
			green : out std_logic_vector(7 downto 0) := (others => '0'); --green magnitude output to DAC
			blue : out std_logic_vector(7 downto 0) := (others => '0'); --blue magnitude output to DAC

			LED : out std_logic_vector(7 downto 0)
		);
	end component;

	component core is
		generic (	
			game_speed: integer;
			screen_w: integer;
			screen_h: integer

--			ship_1_image_width : integer;
--			ship_1_image_height : integer
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
	end component;

	-- component single_clock_ram is
	-- 	port (
	-- 		clock : in std_logic;
	-- 		data : in std_logic_vector (7 downto 0);
	-- 		write_address : in integer range 0 to 1300;
	-- 		read_address : in integer range 0 to 1300;
	-- 		we : in std_logic;
	-- 		q : out std_logic_vector (31 downto 0)
	-- 	);
	-- end component;
begin
	reset_low <= reset;

	disp_ena <= disp_ena_inner;

	gen_vga_controller: if (screen_w = 800) generate

	vga_controller_1 : vga_controller 
	generic map (
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

		--graphic_memory => graphic_memory,

		--ship_1_memory_begin => ship_1_memory_begin_inner,
		--ship_1_image_width => ship_1_image_width_inner,
		--ship_1_image_height => ship_1_image_height_inner,

 		data => data,
 		-- write_address => write_address,
		 game_clk => game_clk,

		 we => we,
		--graphic_memory_q => graphic_memory_q_inner,

		-- output
		--graphic_memory_read_address => graphic_memory_read_address_inner,

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

		-- ship_1_image_width => ship_1_image_width_inner,
		-- ship_1_image_height => ship_1_image_height_inner
	)
	port map(
	pixel_clk => pixel_clk,
	clk	=> game_clk,
	cannon_1_up => up_1,
	cannon_1_down => down_1,
	cannon_1_fire => fire_1,
	cannon_2_up => up_2,
	cannon_2_down => down_2,
	cannon_2_fire => fire_2,

	cannon_1_pos_out => cannon_pos_1_inner,
	cannon_2_pos_out => cannon_pos_2_inner,
	shells_1_out => shells_1_inner,
	shells_2_out => shells_2_inner,
	ships_1_out => ships_1_inner,
	ships_2_out => ships_2_inner,

	score_1 => score_1_inner,
	score_2 => score_2_inner,

	first_border_coord => first_border_coord_inner,
	second_border_coord => second_border_coord_inner
	);

	-- memory_ram : single_clock_ram 
	-- 	port map(
	-- 		clock => game_clk,
	-- 		data => data,
	-- 		write_address => write_address,
	-- 		read_address => graphic_memory_read_address_inner,
	-- 		we => we,
	-- 		q => graphic_memory_q_inner

	-- 	);

	-- clk_vga_c <= temp_vga_clk;

end a1;