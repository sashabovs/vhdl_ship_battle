library work;
use work.DataStructures.ArrayOfShells;
use work.DataStructures.Coordinates;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity queue is
	generic (
		--depth of fifo
		depth : integer := 10;
		update_period_in_clk : integer := 20
	);
	port (
		-- input
		clk : in std_logic;
		reset : in std_logic;
		pop_enabled : in std_logic; --enable read,should be '0' when not in use.
		push_enabled : in std_logic; --enable write,should be '0' when not in use.
		data_in : in Coordinates; --input data

		-- output
		data_out : out Coordinates; --output data
		data_top : out Coordinates;

		fifo_empty : out std_logic; --set as '1' when the queue is empty
		fifo_full : out std_logic; --set as '1' when the queue is full

		data_all : out ArrayOfShells
	);
end queue;

architecture a1 of queue is
	--constant Coordinates_INIT : Coordinates := (x := 0, y := 0);

	signal memory : ArrayOfShells; --memory for queue.
	signal readptr, writeptr : integer := 0; --read and write pointers.

	signal empty : std_logic := '1';
	signal full : std_logic := '0';
begin
	fifo_empty <= empty;
	fifo_full <= full;

	process (clk, reset)
		--this is the number of elements stored in fifo at a time.
		--this variable is used to decide whether the fifo is empty or full.
		variable num_elem : integer := 0;
		variable ticks : integer := 0;
	begin
		if (reset = '1') then
			--data_out <= (others => Coordinates_INIT);
			empty <= '1';
			full <= '0';
			readptr <= 0;
			writeptr <= 0;
			num_elem := 0;
		elsif (rising_edge(clk)) then
			ticks := ticks + 1;
			if (ticks = update_period_in_clk) then
				ticks := 0;
				for i in 0 to depth - 1 loop
					if (full = '1')
						then
						memory(i).cord.x <= memory(i).cord.x + 1;
					elsif (readptr < writeptr and i >= readptr and i < writeptr)
						then
						memory(i).cord.x <= memory(i).cord.x + 1;
					elsif (readptr > writeptr and (i >= readptr or i < writeptr))
						then
						memory(i).cord.x <= memory(i).cord.x + 1;
					end if;
				end loop;
			end if;

			---------------------------------------

			if (empty = '0') then
				data_top <= memory(readptr).cord;
			else
			data_top <= (x => -1, y => -1);
			end if;

			--if (push_enabled = '1') then
				if (pop_enabled = '1' and empty = '0') then --read
					data_out <= memory(readptr).cord;
					memory(readptr).enabled <= '0';
					readptr <= readptr + 1;
					num_elem := num_elem - 1;
				end if;

				if (push_enabled = '1' and full = '0') then --write
					memory(writeptr).cord <= data_in;
					memory(writeptr).enabled <= '1'; 
					writeptr <= writeptr + 1;
					num_elem := num_elem + 1;
				end if;

				--rolling over of the indices.
				if (readptr = depth - 1) then --resetting read pointer.
					readptr <= 0;
				end if;
				if (writeptr = depth - 1) then --resetting write pointer.
					writeptr <= 0;
				end if;
				--setting empty and full flags.
				if (num_elem = 0) then
					empty <= '1';
				else
					empty <= '0';
				end if;
				if (num_elem = depth) then
					full <= '1';
				else
					full <= '0';
				end if;
			--end if;
		end if;
	end process;

	process (clk)
	begin
		data_all <= memory;
	end process;
end a1;