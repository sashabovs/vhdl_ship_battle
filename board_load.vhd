library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.std_logic_textio.all;
use ieee.numeric_std.all;

library work;
use work.DataStructures.resArray;
use work.DataStructures.Pair;

entity board_load is
	port (
		-- input
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
		
		pixel_clk : out std_logic
	);
end board_load;

architecture a1 of board_load is
	constant screen_w : integer := 1920;
	constant screen_h : integer := 1080;

	signal vga_clk_inner : std_logic;

	--signal disp_ena_test : std_logic := '0';

	--constant clk_vga_period : time := 5 ns;

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

	component altpll0 is
		port (
			inclk0 : in std_logic := '0';
			c0 : out std_logic
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
		pixel_clk => vga_clk_inner,
		game_clk => game_clk,

		reset => reset,

		up => up,
		down => down,
		fire => fire,

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

	pixel_clk <= vga_clk_inner;



end a1;