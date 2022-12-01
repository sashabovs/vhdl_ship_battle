library ieee;
use ieee.std_logic_1164.all;

package DataStructures is
	type Coordinates is record
		x : integer;
		y : integer;
	end record;

	type Boundaries is record
		start_pos : integer;
		end_pos : integer;
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

		ship_memory_offset: integer;
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
		ship_image_height => 114,
		ship_memory_offset => 1300
	);
	constant battleShip : ShipType := (
		id => battle_ship_id,
		color => "000000011111000000011111",
		value => 5,
		ship_image_width => 10,
		ship_image_height => 40,
		ship_memory_offset => 2554
	);
	constant civilShip : ShipType := (
		id => civil_ship_id,
		color => "000000000000001111111111",
		value => - 2,
		ship_image_width => 20,
		ship_image_height => 65,
		ship_memory_offset => 0
	);

	-- letters
	constant text_string_length : integer range 0 to 21 := 21;
	constant text_num : integer range 0 to 3 := 3;

	type Letter is record
		letter_num : integer;
	end record;

	type array_of_ranges is array(positive range <>) of Boundaries;

	type Text is record
		range_y : Boundaries;
		array_of_letters : string(1 to text_string_length);
		ranges_x : array_of_ranges(1 to text_string_length);
	end record;

	type array_of_digits is array(1 to text_string_length) of integer;
	type DigitsArray is array(0 to text_num - 1) of array_of_digits;

	type TextArray is array(0 to text_num - 1) of Text;

	function GetText(
		input_text : string;
		position : Coordinates
	) return Text;

	constant letter_size : Coordinates := (x => 12, y => 14);

	constant font_start_byte : integer := 5908;
	constant font_row_size_byte : integer := 1152;

	type LetterStartArray is array(0 to 127) of integer;
	function GenerateLetterStart return LetterStartArray;
	type LetterFontRowStartArray is array(0 to letter_size.y) of integer;
	function GenerateLetterFontRowStart return LetterFontRowStartArray;

	constant all_texts_start_game : TextArray;
	constant all_texts_play_game_header : TextArray;
	constant all_texts_play_game_footer : TextArray;
	constant all_texts_end_game : TextArray;
	constant all_texts_end_game_result : TextArray;


	constant font_letter_start_pos_x : LetterStartArray;
	constant font_row_start_pos_y : LetterFontRowStartArray;
	---------------------
	type GameStates is (
		GAME_LOAD,
		GAME_START,
		GAME_PLAY,
		GAME_END
	);
end package DataStructures;

package body DataStructures is
	function GetText(
		input_text : string(1 to text_string_length);
		position : Coordinates
	) return Text is
		variable temp_text : Text;
	begin
		temp_text.range_y.start_pos := position.y;
		temp_text.range_y.end_pos := position.y + letter_size.y;

		temp_text.array_of_letters := input_text;

		for i in input_text'range loop
			temp_text.ranges_x(i).start_pos := position.x + (i - 1) * (letter_size.x + 3);
			temp_text.ranges_x(i).end_pos := position.x + (i - 1) * (letter_size.x + 3) + letter_size.x;
		end loop;

		return temp_text;
	end function;

	function GenerateLetterStart return LetterStartArray is
		variable tmp_font_letter_start_pos_x : LetterStartArray;
	begin
		for i in 0 to 127 loop
			tmp_font_letter_start_pos_x(i) := letter_size.x * i;
		end loop;

		return tmp_font_letter_start_pos_x;
	end function;

	function GenerateLetterFontRowStart return LetterFontRowStartArray is
		variable tmp_font_row_start_pos_y : LetterFontRowStartArray;
	begin
		for i in 0 to letter_size.y loop
			tmp_font_row_start_pos_y(i) := font_row_size_byte * i;
		end loop;

		return tmp_font_row_start_pos_y;
	end function;

	constant all_texts_start_game : TextArray := (
		0 => GetText("Start Game           ", (x => 290, y => 260)),
		1 => GetText("Press 'KEY0' to start", (x => 200, y => 290)),
		2 => GetText("                     ", (x => 0, y => 0))
	);

	constant all_texts_play_game_header : TextArray := (
		0 => GetText("00:00                ", (x => 350, y => 10)),
		1 => GetText("                     ", (x => 0, y => 0)),
		2 => GetText("                     ", (x => 0, y => 0))
	);

	constant all_texts_play_game_footer : TextArray := (
		0 => GetText("Score: 000           ", (x => 100, y => 560)),
		1 => GetText("Score: 000           ", (x => 600, y => 560)),
		2 => GetText("                     ", (x => 0, y => 0))
	);

	constant all_texts_end_game : TextArray := (
		0 => GetText("Game over            ", (x => 300, y => 260)),
		1 => GetText("Press 'KEY0' to play ", (x => 250, y => 520)),
		2 => GetText("Press 'KEY1' to reset", (x => 250, y => 550))
	);

	constant all_texts_end_game_result : TextArray := (
		0 => GetText("Player 1 won         ", (x => 280, y => 290)),
		1 => GetText("Player 2 won         ", (x => 280, y => 290)),
		2 => GetText("Draw                 ", (x => 330, y => 290))
	);

	constant font_letter_start_pos_x : LetterStartArray := GenerateLetterStart;
	constant font_row_start_pos_y : LetterFontRowStartArray := GenerateLetterFontRowStart;

end package body DataStructures;