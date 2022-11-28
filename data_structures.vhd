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
		ship_image_width => 10,
		ship_image_height => 40
	);
	constant civilShip : ShipType := (
		id => civil_ship_id,
		color => "000000000000001111111111",
		value => - 2,
		ship_image_width => 20,
		ship_image_height => 65
	);

	-- letters
	constant text_string_length: integer range 0 to 21 := 21;
	constant text_num: integer range 0 to 3 := 3;

	type Letter is record
		letter_num : integer;
	end record;

	type Text is record
		position : Coordinates;
		array_of_letters : string(1 to text_string_length);
	end record;

	type array_of_digits is array(1 to text_string_length) of integer;
	type DigitsArray is array(0 to text_num - 1) of array_of_digits;

	type TextArray is array(0 to text_num - 1) of Text;

	constant all_texts_start_game : TextArray := (
		0 => (position => (x => 200, y => 260), array_of_letters => "Start Game           "),
		1 => (position => (x => 200, y => 290), array_of_letters => "Press 'KEY0' to start"),
		2 => (position => (x => 0, y => 0), array_of_letters => (others => ' '))
	);

	constant all_texts_play_game_header : TextArray := (
		0 => (position => (x => 350, y => 10), array_of_letters => ("00:00" & (6 to text_string_length => ' '))),
		1 => (position => (x => 0, y => 0), array_of_letters => (others => ' ')),
		2 => (position => (x => 0, y => 0), array_of_letters => (others => ' '))
	);

	constant all_texts_play_game_footer : TextArray := (
		0 => (position => (x => 100, y => 560), array_of_letters => "Score: 000           "),
		1 => (position => (x => 600, y => 560), array_of_letters => "Score: 000           "),
		2 => (position => (x => 0, y => 0), array_of_letters => (others => ' '))
	);

	constant all_texts_end_game : TextArray := (
		0 => (position => (x => 200, y => 260), array_of_letters => "Game over            "),
		1 => (position => (x => 200, y => 290), array_of_letters => "Press 'KEY0' to play "),
		2 => (position => (x => 200, y => 290), array_of_letters => "Press 'KEY1' to reset")
	);
	constant letter_size : Coordinates := (x => 12, y => 14);

	---------------------
	type GameStates is (
		GAME_START,
		GAME_PLAY,
		GAME_END
	);
end package DataStructures;

package body DataStructures is
end package body DataStructures;