library ieee;
use ieee.std_logic_1164.all;

package DataStructures is
	type Coordinates is record
		x : integer;
		y : integer;
	end record;

	type ShellObject is record
		cord : Coordinates;
		enabled : std_logic;
	end record;


	type ArrayOfShells is array(0 to 9) of ShellObject;

	type ShipType is record
		id : integer;

		color : std_logic_vector (23 downto 0);
		value : integer;

		ship_image_width : integer;
		ship_image_height : integer;
	end record;

	type ShipObject is record
		pos1 : Coordinates;
		ship_type : ShipType;
	end record;

	type ShipArray is array(0 to 4) of ShipObject;

	constant destroyer_id : integer := 1;
	constant battle_ship_id : integer := 2;
	constant civil_ship_id : integer := 3;

	constant destroyer : ShipType := (
		id => destroyer_id,
		color => "011111000000000000011111",
		value => 1,
		ship_image_width => 11,
		ship_image_height => 114
	);
	constant battleShip : ShipType := (
		id => battle_ship_id,
		color => "000000011111000000011111",
		value => 5,
		ship_image_width => 20,
		ship_image_height => 65
	);
	constant civilShip : ShipType := (
		id => civil_ship_id,
		color => "000000000000001111111111",
		value => - 2,
		ship_image_width => 20,
		ship_image_height => 65
	);

	type GraphicMemoryType is array(0 to 1300) of std_logic_vector(7 downto 0);


	type Letter is record
		letter_num : integer;
	end record;

	type Letters is array(0 to 5) of Letter;

	type Text is record
		position : Coordinates;
		array_of_letters : Letters;
	end record;

	constant score_text_1 : Text := (position => (x => 100, y => 560), array_of_letters => (0 => (letter_num => 18), 1 => (letter_num => 2), 2 => (letter_num => 14), 3 => (letter_num => 17), 4 => (letter_num => 4), 5 => (letter_num => 63)));
	constant score_num_text_1 : Text := (position => (x => 175, y => 560), array_of_letters => (0 => (letter_num => 52), 1 => (letter_num => 52), 2 => (letter_num => 52), others => (letter_num => -1)));

	constant score_text_2 : Text := (position => (x => 600, y => 560), array_of_letters => (0 => (letter_num => 18), 1 => (letter_num => 2), 2 => (letter_num => 14), 3 => (letter_num => 17), 4 => (letter_num => 4), 5 => (letter_num => 63)));
	constant score_num_text_2 : Text := (position => (x => 675, y => 560), array_of_letters => (0 => (letter_num => 52), 1 => (letter_num => 52), 2 => (letter_num => 52), others => (letter_num => -1)));

end package DataStructures;



package body DataStructures is
end package body DataStructures;