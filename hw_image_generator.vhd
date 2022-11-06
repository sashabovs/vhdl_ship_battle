library work;
use work.DataStructures.Coordinates;
use work.DataStructures.resArray;
use work.DataStructures.Item;

library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;

entity hw_image_generator is
	generic (
		pixels_y : integer := 5; --row that first color will persist until
		pixels_x : integer := 5 --column that first color will persist until
	);
	port (
		disp_ena : in std_logic; --display enable ('1' = display time, '0' = blanking time)
		row : in integer; --row pixel coordinate
		column : in integer; --column pixel coordinate

		cannon_1_pos : in Coordinates;
		shells_1 : in resArray;

		red : out std_logic_vector(7 downto 0) := (others => '0'); --red magnitude output to DAC
		green : out std_logic_vector(7 downto 0) := (others => '0'); --green magnitude output to DAC
		blue : out std_logic_vector(7 downto 0) := (others => '0')); --blue magnitude output to DAC
end hw_image_generator;

architecture a1 of hw_image_generator is
begin
	process (disp_ena, row, column)
	begin
		if (disp_ena = '1') then --display time
			if (row < pixels_y and column < pixels_x) then
				red <= (others => '0');
				green <= (others => '0');
				blue <= (others => '1');
			else
				red <= (others => '1');
				green <= (others => '1');
				blue <= (others => '0');
			end if;

			if (row > 1070 and column > 1900) then
				red <= (others => '1');
				green <= (others => '0');
				blue <= (others => '0');
			end if;

			for i in 0 to 9 loop
				if (shells_1(i).x > column - 5 and shells_1(i).x < column + 5 and shells_1(i).y > row - 5 and shells_1(i).y < row + 5) then
					red <= (others => '1');
					green <= (others => '0');
					blue <= (others => '0');
				end if;
			end loop;

		   if (column > cannon_1_pos.x - 10 and column < cannon_1_pos.x + 10 and row > cannon_1_pos.y - 10 and row < cannon_1_pos.y + 10) then

			   red <= (others => '0');
			   green <= (others => '1');
			   blue <= (others => '0');
			end if;
			

		else --blanking time
			red <= (others => '0');
			green <= (others => '0');
			blue <= (others => '0');
		end if;

	end process;
end a1;