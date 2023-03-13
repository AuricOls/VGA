--Equipo 5
--Auric
--Eric
--Demian
LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY vga IS
	GENERIC (
		Ha: INTEGER := 96; --Hpulse
		Hb: INTEGER := 144; --Hpulse+HBP
		Hc: INTEGER := 784; --Hpulse+HBP+Hactive
		Hd: INTEGER := 800; --Hpulse+HBP+Hactive+HFP
		Va: INTEGER := 2; --Vpulse
		Vb: INTEGER := 35; --Vpulse+VBP
		Vc: INTEGER := 515; --Vpulse+VBP+Vactive
		Vd: INTEGER := 525); --Vpulse+VBP+Vactive+VFP
	PORT (
		clk: IN STD_LOGIC; --50MHz in our board
		update_mode:in std_logic:='1'; --button to update the image
		sw_selector: IN STD_LOGIC_vector(1 downto 0);
		pixel_clk: BUFFER STD_LOGIC;
		Hsync, Vsync: BUFFER STD_LOGIC;
		R, G, B: OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
		nblanck, nsync : OUT STD_LOGIC);
	END vga;

ARCHITECTURE vga OF vga IS
SIGNAL Hactive, Vactive, dena: STD_LOGIC;
constant counter_limit  : natural := 50000000;
BEGIN
-------------------------------------------------------
--Part 1: CONTROL GENERATOR
-------------------------------------------------------
	--Static signals for DACs:
	nblanck <= '1'; --no direct blanking
	nsync <= '0'; --no sync on green
	--Create pixel clock (50MHz->25MHz):
	PROCESS (clk)
	BEGIN
		IF (clk'EVENT AND clk='1') THEN pixel_clk <= NOT pixel_clk;
		END IF;
	END PROCESS;
	--Horizontal signals generation:
	PROCESS (pixel_clk)
	VARIABLE Hcount: INTEGER RANGE 0 TO Hd;
	BEGIN
		IF (pixel_clk'EVENT AND pixel_clk='1') THEN Hcount := Hcount + 1;
			IF (Hcount=Ha) THEN Hsync <= '1';
			ELSIF (Hcount=Hb) THEN Hactive <= '1';
			ELSIF (Hcount=Hc) THEN Hactive <= '0';
			ELSIF (Hcount=Hd) THEN Hsync <= '0'; Hcount := 0;
			END IF;
		END IF;
	END PROCESS;
	--Vertical signals generation:
	PROCESS (Hsync)
	VARIABLE Vcount: INTEGER RANGE 0 TO Vd;
	BEGIN
		IF (Hsync'EVENT AND Hsync='0') THEN Vcount := Vcount + 1;
			IF (Vcount=Va) THEN Vsync <= '1';
			ELSIF (Vcount=Vb) THEN Vactive <= '1';
			ELSIF (Vcount=Vc) THEN Vactive <= '0';
			ELSIF (Vcount=Vd) THEN Vsync <= '0'; Vcount := 0;
			END IF;
		END IF;
	END PROCESS;
	---Display enable generation:
	dena <= Hactive AND Vactive;
	-------------------------------------------------------
	--Part 2: IMAGE GENERATOR
	-------------------------------------------------------
	PROCESS (Hsync, Vsync,Hactive, Vactive, dena)
	
	VARIABLE line_counter: INTEGER RANGE 0 TO Vc;
	Variable column_counter: integer range 0 to Hc;
	variable left_limit:integer range Hb to 640:=300;
	variable right_limit:integer range Hb to 640:=340;
	variable up_limit:integer range 0 to 480:=200;
	variable down_limit:integer range 0 to 480:=240;
	variable step:integer:=10;
	variable counter_time:integer  range 0 to 5:=0;

	
	BEGIN
		

		IF (Vsync='0') THEN
			line_counter := 0;
		ELSIF (Hsync'EVENT AND Hsync='1') THEN
			IF (Vactive='1') THEN
				line_counter := line_counter + 1;
			END IF;
		END IF;
		IF (Hsync='0') THEN
			column_counter := 0;
		ELSIF (pixel_clk'EVENT AND pixel_clk='1') THEN
			IF (Hactive='1') THEN
				column_counter := column_counter + 1;
			END IF;
		END IF;
		
		IF (dena='1') THEN 
		
			if (column_counter<=left_limit or column_counter>=right_limit) then

					R <= (OTHERS => '1');
					G <= (OTHERS => '1');
					B <= (OTHERS => '1');

			
			elsif (column_counter>=left_limit or column_counter<=right_limit) then
			
				if (line_counter >up_limit and line_counter<down_limit) then
					R <= (OTHERS => '0');
					G <= (OTHERS => '0');
					B <= (OTHERS => '1');
				else
					R <= (OTHERS => '1');
					G <= (OTHERS => '1');
					B <= (OTHERS => '1');
				end if; --line counter if
				
			end if; -- column counter if
					
		ELSE
			R <= (OTHERS => '0');
			G <= (OTHERS => '0');
			B <= (OTHERS => '0');
		END IF; --if dena
		

				
			
			--11 go up, 00 go down, 01 go left, 10 go right

				if (rising_edge(clk)) then
					if (update_mode='1') then
						counter_time:=0;
						end if;
					case sw_selector is
						when "11" =>
							if (update_mode='0' and counter_time<10) then 
								counter_time:=counter_time+1;
								up_limit:= up_limit-step;
								down_limit:= down_limit-step;
							end if;
							
						when "00" =>
							if (update_mode='0' and counter_time=0) then 
								counter_time:=counter_time+1;
								up_limit:= up_limit+step;
								down_limit:= down_limit+step;
							end if;
							
						when "01" =>
							if (update_mode='0' and counter_time=0) then 
								counter_time:=counter_time+1;
								left_limit:= left_limit-step;
								right_limit:= right_limit-step;
							end if;	
						when "10" =>
							if (update_mode='0' and counter_time=0) then 
								counter_time:=counter_time+1;
								left_limit:= left_limit+step;
								right_limit:= right_limit+step;
							end if;							
						when others=>
							null;
							
					end case;
				end if;
	


	END PROCESS;
END vga;
