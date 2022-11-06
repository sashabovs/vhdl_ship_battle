library ieee;
use ieee.std_logic_1164.all;

package DataStructures is
	type Coordinates is record
		x : integer;
		y : integer;
	end record;

	type resArray is array(0 to 9) of Coordinates;

	type ShipType is record
		color : std_logic_vector (23 downto 0);
		value : integer;
	end record;

	type ShipObject is record
		pos1 : Coordinates;
		ship_type : ShipType;
	end record;

	type ShipArray is array(0 to 9) of ShipObject;
end package DataStructures;



package body DataStructures is
end package body DataStructures;