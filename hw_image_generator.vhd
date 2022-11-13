library work;
use work.DataStructures.Coordinates;
use work.DataStructures.ArrayOfShells;
use work.DataStructures.ShipType;
use work.DataStructures.ShipObject;
use work.DataStructures.ShipArray;

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity hw_image_generator is
	generic (
		screen_w : integer := 5;
		screen_h : integer := 5
	);
	port (
		disp_ena : in std_logic; --display enable ('1' = display time, '0' = blanking time)
		row : in integer; --row pixel coordinate
		column : in integer; --column pixel coordinate

		first_border_coord : in Coordinates;
		second_border_coord : in Coordinates;

		cannon_1_pos : in Coordinates;
		shells_1 : in ArrayOfShells;
		ships_1 : in ShipArray;

		score_1 : in integer;

		red : out std_logic_vector(7 downto 0) := (others => '0'); --red magnitude output to DAC
		green : out std_logic_vector(7 downto 0) := (others => '0'); --green magnitude output to DAC
		blue : out std_logic_vector(7 downto 0) := (others => '0')); --blue magnitude output to DAC
end hw_image_generator;

architecture a1 of hw_image_generator is
begin
	process (disp_ena, row, column)
	--type num is array (0 to 2, 0 to 4) of std_logic_vector (14 downto 0); 

	begin
		if (disp_ena = '1') then --display time

			-- game area
			if (row > first_border_coord.y and column > first_border_coord.x and row < second_border_coord.y and column < second_border_coord.x) then
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '1');
			end if;


			-- shells 1
			for i in 0 to 9 loop
				if (shells_1(i).enabled = '1') then
					if (shells_1(i).cord.x > column - 5 and shells_1(i).cord.x < column + 5 and shells_1(i).cord.y > row - 5 and shells_1(i).cord.y < row + 5) then
						red <= (others => '1');
						green <= (others => '0');
						blue <= (others => '0');
					end if;
				end if;
			end loop;

			-- cannon 1
			if (column > cannon_1_pos.x - 10 and column < cannon_1_pos.x + 10 and row > cannon_1_pos.y - 10 and row < cannon_1_pos.y + 10) then
				red <= (others => '0');
				green <= (others => '1');
				blue <= (others => '0');
			end if;

			-- ships 1
			for i in 0 to 9 loop
				if (ships_1(i).pos1.x > column - 5 and ships_1(i).pos1.x < column + 5 and ships_1(i).pos1.y > row - 5 and ships_1(i).pos1.y < row + 5) then
					red <= ships_1(i).ship_type.color(23 downto 16);
					green <= ships_1(i).ship_type.color(15 downto 8);
					blue <= ships_1(i).ship_type.color(7 downto 0);
				end if;
			end loop;

			-- border
			if (row > first_border_coord.y and column > first_border_coord.x and row < second_border_coord.y and column < second_border_coord.x) then 
			else
				red <= (others => '1');
				green <= (others => '1');
				blue <= (others => '0');
			end if;

			-- score 1 dont work


		else --blanking time
			red <= (others => '0');
			green <= (others => '0');
			blue <= (others => '0');
		end if;

	end process;
end a1;