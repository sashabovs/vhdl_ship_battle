library work;
use work.DataStructures.ArrayOfShells;
use work.DataStructures.Coordinates;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity queue is
	generic (
		--size of fifo
		depth : integer := 10;
		-- speed of shells
		update_period_in_clk : integer := 20;
		-- shells flight direction (1 - left_to_right, -1 - right_to_left)
		direction : integer
	);
	port (
		-- INPUT
		--clock
		clk : in std_logic;
		--reset
		queue_reset : in std_logic;
		--enable read
		pop_enabled : in std_logic;
		--enable write
		push_enabled : in std_logic;
		--input data
		data_in : in Coordinates;

		-- OUTPUT
		-- top element
		data_top : out Coordinates;
		-- all elements
		data_all : out ArrayOfShells
	);
end queue;

architecture a1 of queue is
	--memory for queue
	signal memory : ArrayOfShells;
	--read and write pointers
	signal readptr, writeptr : integer := 0;

	-- queue flags
	signal empty : std_logic := '1';
	signal full : std_logic := '0';
begin

	process (clk)
		variable num_elem : integer := 0;
		-- variable for slowing the speed of shells
		variable ticks : integer := 0;
	begin
		if (rising_edge(clk)) then
			if (queue_reset = '1') then
				-- reset
				for i in memory'range loop
					memory(i).enabled <= '0';
				end loop;

				empty <= '1';
				full <= '0';
				readptr <= 0;
				writeptr <= 0;
				num_elem := 0;
			else
				-- move all existing shells 
				ticks := ticks + 1;
				if (ticks = update_period_in_clk) then
					ticks := 0;
					for i in 0 to depth - 1 loop
						-- when the writing pointer reaches the end of the array, he returns to the beginning
						-- if fifo full, move all elemnts
						if (full = '1') then
							memory(i).cord.x <= memory(i).cord.x + direction;

						-- if the writing pointer is to the right of the reading pointer
						-- move elements between pointers
						elsif (readptr < writeptr and i >= readptr and i < writeptr) then
							memory(i).cord.x <= memory(i).cord.x + direction;

						-- if the writing pointer is to the left of the reading pointer
						-- move elements that is in range from read pointer to end of fifo and from begin to write pointer
						elsif (readptr > writeptr and (i >= readptr or i < writeptr)) then
							memory(i).cord.x <= memory(i).cord.x + direction;
						end if;
					end loop;
				end if;

				---------------------------------------
				-- update fifo parameters
				
				-- if fifo not empty send als top element first element, else invalid element
				if (empty = '0') then
					data_top <= memory(readptr).cord;
				else
					data_top <= (x => 400, y => - 1);
				end if;

				-- read from fifo
				if (pop_enabled = '1' and empty = '0') then 
					-- 'disable' element, move read pointer, decrease num of elements
					memory(readptr).enabled <= '0';
					readptr <= readptr + 1;
					num_elem := num_elem - 1;
				end if;

				-- write in fifo
				if (push_enabled = '1' and full = '0') then 
				-- save valid data in element, 'enable' element, move write pointer, increase num of elements
					memory(writeptr).cord <= data_in;
					memory(writeptr).enabled <= '1';
					writeptr <= writeptr + 1;
					num_elem := num_elem + 1;
				end if;

				-- rolling over of the indices
				-- resetting read pointer when comes to the end of array
				if (readptr = depth - 1) then 
					readptr <= 0;
				end if;
				-- resetting write pointer when comes to the end of array
				if (writeptr = depth - 1) then 
					writeptr <= 0;
				end if;
				-- setting empty and full flags
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
			end if;
		end if;
	end process;

	-- send out all array
	process (clk)
	begin
		data_all <= memory;
	end process;
end a1;