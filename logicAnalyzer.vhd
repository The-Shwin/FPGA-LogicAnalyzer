library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
library UNISIM;
use UNISIM.vcomponents.all;

entity logicAnalyzer is
	port(
		clk:    in    std_logic;
		ra1:    in    std_logic;
		rc1:    in    std_logic;
		rc3:    in    std_logic;
		rb:     inout std_logic_vector(7 downto 0);
		but:    in    std_logic;
		data:   in    std_logic_vector(15 downto 0)
	);
end logicAnalyzer;

architecture arch of logicAnalyzer is
	signal dir:    std_logic_vector(3 downto 0);
	signal ndir:   std_logic;
	signal start:  std_logic_vector(3 downto 0);
	signal shift:  std_logic_vector(3 downto 0);
	type sr is array (3 downto 0) of std_logic_vector(7 downto 0);
	signal rb_in:  sr;
	signal data_in: sr;
	signal rb_out: std_logic_vector(7 downto 0);
	signal doa:    std_logic_vector(31 downto 0);
	signal addra:  std_logic_vector(13 downto 0);
	signal wea:    std_logic_vector(3 downto 0);
	signal dia:    std_logic_vector(31 downto 0);
	signal addrb:  std_logic_vector(13 downto 0);
	signal web:    std_logic_vector(3 downto 0);
	signal dib:    std_logic_vector(31 downto 0);
	signal counta: unsigned(10 downto 0);
	signal countb: unsigned(10 downto 0);
	signal but_reg: std_logic_vector(3 downto 0);
	signal clkfx: std_logic;
begin
	------------------------------------------------------------------
	-- Control signal assignements
	------------------------------------------------------------------
	ndir<=not rc3;

	addra<=std_logic_vector(counta)&"000";
	dia(7 downto 0)<=rb_in(3);
	dia(31 downto 8)<=(others=>'0');
	rb_out<=doa(7 downto 0);
	data_in(0)<=data(15 downto 8);
	dib(7 downto 0)<=data_in(3);
	dib(31 downto 8)<=(others=>'0');
	addrb<=std_logic_vector(countb)&"000";

	------------------------------------------------------------------
	-- I/O buffer instantiation
	------------------------------------------------------------------
	pic_rb: for index in 7 downto 0 generate
		IOBUF_rb: IOBUF generic map(DRIVE=>12,IOSTANDARD=>"LVCMOS33",
			SLEW=>"SLOW") port map(O=>rb_in(0)(index),IO=>rb(index),
			I=>rb_out(index),T=>ndir);
	end generate;

------------------------------------------------------------------
	-- Clock instantiation
	------------------------------------------------------------------

	DCM: DCM_SP
		generic map (
			CLKFX_DIVIDE=>1,
			CLKFX_MULTIPLY=>4,
			CLKIN_PERIOD=>20.8
		) port map (
			CLK0=>open,
			CLK180=>open,
			CLK270=>open,
			CLK2X=>open,
			CLK2X180=>open,
			CLK90=>open,
			CLKDV=>open,
			CLKFX=>clkfx,
			CLKFX180=>open,
			LOCKED=>open,
			PSDONE=>open,
			STATUS=>open,
			CLKFB=>open,
			CLKIN=>clk,
			DSSEN=>'0',
			PSCLK=>'0',
			PSEN=>'0',
			PSINCDEC=>'0',
			RST=>'0'
		);

	------------------------------------------------------------------
	-- Block RAM instantiation
	------------------------------------------------------------------
	mem: RAMB16BWER
		generic map(
			DATA_WIDTH_A=>9,
			DATA_WIDTH_B=>9,
			SIM_DEVICE=>"SPARTAN6"
		)port map(
			DOA=>doa,
			DOPA=>open,
			DOB=>open,
			DOPB=>open,
			ADDRA=>addra,
			CLKA=>clk,
			ENA=>'1',
			REGCEA=>'1',
			RSTA=>'0',
			WEA=>wea,
			DIA=>dia,
			DIPA=>"0000",
			ADDRB=>addrb,
			CLKB=>clkfx,
			ENB=>'1',
			REGCEB=>'1',
			RSTB=>'0',
			WEB=>web,
			DIB=>dib,
			DIPB=>"0000"
		);

	------------------------------------------------------------------
	-- Shift registers for metastability
	------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			-- dir bit shift register for metastability
			dir<=dir(2 downto 0)&rc3;
			-- start bit shift register for metastability
			start<=start(2 downto 0)&ra1;
			-- shift bit shift register for metastability
			shift<=shift(2 downto 0)&rc1;
			-- rb bus shift register for metastability
			rb_in(3 downto 1)<=rb_in(2 downto 0);
			-- button shift register for metastability
			but_reg<=but_reg(2 downto 0)&but;
		end if;
	end process;

	process(clkfx)
	begin
		if rising_edge(clkfx) then
			data_in(3 downto 1)<=data_in(2 downto 0);
		end if;
	end process;

	------------------------------------------------------------------
	-- Port A state machine
	------------------------------------------------------------------
	process(clk)
	begin
		if rising_edge(clk) then
			-- read/write ports
			if (shift(3)='0') and (shift(2)='1') then
				if (start(3)='1') then
					counta<=b"000_0000_0000";
				else
					counta<=counta+1;
				end if;
				if (dir(3)='0') then
					wea<=b"1111";
				else
					wea<="0000";
				end if;
			else
				wea<="0000";
			end if;
		end if;
	end process;

	------------------------------------------------------------------
	-- Port B state machine
	------------------------------------------------------------------

	process(clkfx)
	begin
		if rising_edge(clkfx) then
			if(but_reg(3)='1') then
				countb<=b"000_0000_0000";
				web<=b"1111";
			else
				-- Entered once the count cycles through
				if (countb = b"111_1111_1111") then
					-- Counter is reset and write is set low
					countb<=b"000_0000_0000";
					web<="0000";
				end if;
				countb<=countb+1;
			end if;
		end if;
	end process;

end arch;
