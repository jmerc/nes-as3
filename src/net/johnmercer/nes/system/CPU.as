package net.johnmercer.nes.system
{
	import flash.utils.*;
	import net.johnmercer.nes.enums.*;
	import net.johnmercer.nes.system.Mappers.*;
	import net.johnmercer.nes.tests.*;
	import net.johnmercer.nes.utils.*;
	import net.johnmercer.nes.views.*;
	
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class CPU
	{
		// Processor Status Flags
		public static const CARRY_FLAG:uint    = 0x01;
		public static const ZERO_FLAG:uint     = 0x02;
		public static const IRQ_FLAG:uint      = 0x04;
		public static const DECIMAL_FLAG:uint  = 0x08;  // Unused
		public static const BREAK_FLAG:uint    = 0x10;
		public static const UNUSED_FLAG:uint   = 0x20;
		public static const OVERFLOW_FLAG:uint = 0x40;
		public static const NEGATIVE_FLAG:uint = 0x80;
		
		// Cycle counts by instruction
		private static var INST_COUNT:Array = [
		/*0x00*/ 7,6,2,8,3,3,5,5,3,2,2,2,4,4,6,6,
		/*0x10*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		/*0x20*/ 6,6,2,8,3,3,5,5,4,2,2,2,4,4,6,6,
		/*0x30*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		/*0x40*/ 6,6,2,8,3,3,5,5,3,2,2,2,3,4,6,6,
		/*0x50*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		/*0x60*/ 6,6,2,8,3,3,5,5,4,2,2,2,5,4,6,6,
		/*0x70*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		/*0x80*/ 2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,
		/*0x90*/ 2,6,2,6,4,4,4,4,2,5,2,5,5,5,5,5,
		/*0xA0*/ 2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,
		/*0xB0*/ 2,5,2,5,4,4,4,4,2,4,2,4,4,4,4,4,
		/*0xC0*/ 2,6,2,8,3,3,5,5,2,2,2,2,4,4,6,6,
		/*0xD0*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		/*0xE0*/ 2,6,3,8,3,3,5,5,2,2,2,2,4,4,6,6,
		/*0xF0*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		];
		
		// Names of instructions
		public static var INST_NAME:Array = [
		/*0x00*/ "BRK", "ORA", "XXX", "SLO", "NOP", "ORA", "ASL", "SLO", "PHP", "ORA", "ASL", "ANC", "NOP", "ORA", "ASL", "SLO",
		/*0x10*/ "BPL", "ORA", "XXX", "SLO", "NOP", "ORA", "ASL", "SLO", "CLC", "ORA", "NOP", "SLO", "NOP", "ORA", "ASL", "SLO",
		/*0x20*/ "JSR", "AND", "XXX", "RLA", "BIT", "AND", "ROL", "RLA", "PLP", "AND", "ROL", "ANC", "BIT", "AND", "ROL", "RLA",
		/*0x30*/ "BMI", "AND", "XXX", "RLA", "NOP", "AND", "ROL", "RLA", "SEC", "AND", "NOP", "RLA", "NOP", "AND", "ROL", "RLA",
		/*0x40*/ "RTI", "EOR", "XXX", "SRE", "NOP", "EOR", "LSR", "SRE", "PHA", "EOR", "LSR", "ASR", "JMP", "EOR", "LSR", "SRE",
		/*0x50*/ "BVC", "EOR", "XXX", "SRE", "NOP", "EOR", "LSR", "SRE", "CLI", "EOR", "NOP", "SRE", "NOP", "EOR", "LSR", "SRE",
		/*0x60*/ "RTS", "ADC", "XXX", "RRA", "NOP", "ADC", "ROR", "RRA", "PLA", "ADC", "ROR", "ARR", "JMP", "ADC", "ROR", "RRA",
		/*0x70*/ "BVS", "ADC", "XXX", "RRA", "NOP", "ADC", "ROR", "RRA", "SEI", "ADC", "NOP", "RRA", "NOP", "ADC", "ROR", "RRA",
		/*0x80*/ "NOP", "STA", "NOP", "SAX", "STY", "STA", "STX", "SAX", "DEY", "NOP", "TXA", "ANE", "STY", "STA", "STX", "SAX",
		/*0x90*/ "BCC", "STA", "XXX", "SHA", "STY", "STA", "STX", "SAX", "TYA", "STA", "TXS", "SHS", "SHY", "STA", "SHX", "SHA",
		/*0xA0*/ "LDY", "LDA", "LDX", "LAX", "LDY", "LDA", "LDX", "LAX", "TAY", "LDA", "TAX", "LXA", "LDY", "LDA", "LDX", "LAX",
		/*0xB0*/ "BCS", "LDA", "XXX", "LAX", "LDY", "LDA", "LDX", "LAX", "CLV", "LDA", "TSX", "LAS", "LDY", "LDA", "LDX", "LAX",
		/*0xC0*/ "CPY", "CMP", "NOP", "DCP", "CPY", "CMP", "DEC", "DCP", "INY", "CMP", "DEX", "SBX", "CPY", "CMP", "DEC", "DCP",
		/*0xD0*/ "BNE", "CMP", "XXX", "DCP", "NOP", "CMP", "DEC", "DCP", "CLD", "CMP", "NOP", "DCP", "NOP", "CMP", "DEC", "DCP",
		/*0xE0*/ "CPX", "SBC", "NOP", "ISB", "CPX", "SBC", "INC", "ISB", "INX", "SBC", "NOP", "SBC", "CPX", "SBC", "INC", "ISB",
		/*0xF0*/ "BEQ", "SBC", "XXX", "ISB", "NOP", "SBC", "INC", "ISB", "SED", "SBC", "NOP", "ISB", "NOP", "SBC", "INC", "ISB",
		];
		
		private var _instructions:Vector.<Function> = new <Function>[
		//////// 00  /  08     01  /  09     02  /  0A     03  /  0B     04  /  0C     05  /  0D     06  /  0E     07  /  0F
		/*0x00*/ instrBRK_IMP, instrORA_INX, instrXXX_XXX, instrSLO_INX, instrNOP_ZPG, instrORA_ZPG, instrASL_ZPG, instrSLO_ZPG, 
		         instrPHP_IMP, instrORA_IMM, instrASL_ACM, instrANC_IMM, instrNOP_ABS, instrORA_ABS, instrASL_ABS, instrSLO_ABS,
		/*0x10*/ instrBPL_REL, instrORA_INY, instrXXX_XXX, instrSLO_INY, instrNOP_ZPX, instrORA_ZPX, instrASL_ZPX, instrSLO_ZPX, 
		         instrCLC_IMP, instrORA_ABY, instrNOP_IMP, instrSLO_ABY, instrNOP_ABX, instrORA_ABX, instrASL_ABX, instrSLO_ABX,
		/*0x20*/ instrJSR_ABS, instrAND_INX, instrXXX_XXX, instrRLA_INX, instrBIT_ZPG, instrAND_ZPG, instrROL_ZPG, instrRLA_ZPG, 
		         instrPLP_IMP, instrAND_IMM, instrROL_ACM, instrANC_IMM, instrBIT_ABS, instrAND_ABS, instrROL_ABS, instrRLA_ABS,
		/*0x30*/ instrBMI_REL, instrAND_INY, instrXXX_XXX, instrRLA_INY, instrNOP_ZPX, instrAND_ZPX, instrROL_ZPX, instrRLA_ZPX, 
		         instrSEC_IMP, instrAND_ABY, instrNOP_IMP, instrRLA_ABY, instrNOP_ABX, instrAND_ABX, instrROL_ABX, instrRLA_ABX,
		/*0x40*/ instrRTI_IMP, instrEOR_INX, instrXXX_XXX, instrSRE_INX, instrNOP_ZPG, instrEOR_ZPG, instrLSR_ZPG, instrSRE_ZPG, 
		         instrPHA_IMP, instrEOR_IMM, instrLSR_ACM, instrASR_IMM, instrJMP_ABS, instrEOR_ABS, instrLSR_ABS, instrSRE_ABS,
		/*0x50*/ instrBVC_REL, instrEOR_INY, instrXXX_XXX, instrSRE_INY, instrNOP_ZPX, instrEOR_ZPX, instrLSR_ZPX, instrSRE_ZPX, 
		         instrCLI_IMP, instrEOR_ABY, instrNOP_IMP, instrSRE_ABY, instrNOP_ABX, instrEOR_ABX, instrLSR_ABX, instrSRE_ABX,
		/*0x60*/ instrRTS_IMP, instrADC_INX, instrXXX_XXX, instrRRA_INX, instrNOP_ZPG, instrADC_ZPG, instrROR_ZPG, instrRRA_ZPG, 
		         instrPLA_IMP, instrADC_IMM, instrROR_ACM, instrARR_IMM, instrJMP_IND, instrADC_ABS, instrROR_ABS, instrRRA_ABS,
		/*0x70*/ instrBVS_REL, instrADC_INY, instrXXX_XXX, instrRRA_INY, instrNOP_ZPX, instrADC_ZPX, instrROR_ZPX, instrRRA_ZPX, 
		         instrSEI_IMP, instrADC_ABY, instrNOP_IMP, instrRRA_ABY, instrNOP_ABX, instrADC_ABX, instrROR_ABX, instrRRA_ABX,
		/*0x80*/ instrNOP_IMM, instrSTA_INX, instrNOP_IMM, instrSAX_INX, instrSTY_ZPG, instrSTA_ZPG, instrSTX_ZPG, instrSAX_ZPG, 
		         instrDEY_IMP, instrNOP_IMM, instrTXA_IMP, instrANE_IMM, instrSTY_ABS, instrSTA_ABS, instrSTX_ABS, instrSAX_ABS,
		/*0x90*/ instrBCC_REL, instrSTA_INY, instrXXX_XXX, instrSHA_INY, instrSTY_ZPX, instrSTA_ZPX, instrSTX_ZPY, instrSAX_ZPY, 
		         instrTYA_IMP, instrSTA_ABY, instrTXS_IMP, instrSHS_ABY, instrSHY_ABX, instrSTA_ABX, instrSHX_ABX, instrSHA_ABX,
		/*0xA0*/ instrLDY_IMM, instrLDA_INX, instrLDX_IMM, instrLAX_INX, instrLDY_ZPG, instrLDA_ZPG, instrLDX_ZPG, instrLAX_ZPG, 
		         instrTAY_IMP, instrLDA_IMM, instrTAX_IMP, instrLXA_IMM, instrLDY_ABS, instrLDA_ABS, instrLDX_ABS, instrLAX_ABS,
		/*0xB0*/ instrBCS_REL, instrLDA_INY, instrXXX_XXX, instrLAX_INY, instrLDY_ZPX, instrLDA_ZPX, instrLDX_ZPY, instrLAX_ZPY, 
		         instrCLV_IMP, instrLDA_ABY, instrTSX_IMP, instrLAS_ABY, instrLDY_ABX, instrLDA_ABX, instrLDX_ABY, instrLAX_ABY,
		/*0xC0*/ instrCPY_IMM, instrCMP_INX, instrNOP_IMM, instrDCP_INX, instrCPY_ZPG, instrCMP_ZPG, instrDEC_ZPG, instrDCP_ZPG, 
		         instrINY_IMP, instrCMP_IMM, instrDEX_IMP, instrSBX_IMM, instrCPY_ABS, instrCMP_ABS, instrDEC_ABS, instrDCP_ABS,
		/*0xD0*/ instrBNE_REL, instrCMP_INY, instrXXX_XXX, instrDCP_INY, instrNOP_ZPX, instrCMP_ZPX, instrDEC_ZPX, instrDCP_ZPX, 
		         instrCLD_IMP, instrCMP_ABY, instrNOP_IMP, instrDCP_ABY, instrNOP_ABX, instrCMP_ABX, instrDEC_ABX, instrDCP_ABX,
		/*0xE0*/ instrCPX_IMM, instrSBC_INX, instrNOP_IMM, instrISB_INX, instrCPX_ZPG, instrSBC_ZPG, instrINC_ZPG, instrISB_ZPG, 
		         instrINX_IMP, instrSBC_IMM, instrNOP_IMP, instrSBC_IMM, instrCPX_ABS, instrSBC_ABS, instrINC_ABS, instrISB_ABS,
		/*0xF0*/ instrBEQ_REL, instrSBC_INY, instrXXX_XXX, instrISB_INY, instrNOP_ZPX, instrSBC_ZPX, instrINC_ZPX, instrISB_ZPX, 
		         instrSED_IMP, instrSBC_ABY, instrNOP_IMP, instrISB_ABY, instrNOP_ABX, instrSBC_ABX, instrINC_ABX, instrISB_ABX
		];
		
		// Addressing Types
		private static const IMP:uint = 0;  // Implicit
		private static const IMM:uint = 1;  // Immediate
		private static const ZPG:uint = 2;  // Zero Page
		private static const ZPX:uint = 3;  // Zero Page, X
		private static const ZPY:uint = 4;  // Zero Page, Y
		private static const ABS:uint = 5;  // Absolute
		private static const ABX:uint = 6;  // Absolute, X
		private static const ABY:uint = 7;  // Absolute, Y
		private static const IND:uint = 8;  // Indirect
		private static const INX:uint = 9;  // (Indirect, X)
		private static const INY:uint = 10;  // (Indirect), Y
		private static const REL:uint = 11;  // Relative
		private static const ACM:uint = 12;  // Accumulator
		public static var ADDR_NAME:Array = [
		"IMP", "IMM", "ZPG", "ZPX", "ZPY", "ABS", "ABX", "ABY", "IND", "INX", "INY", "REL", "ACM"
		];
		
		// Addressing mode of instruction
		public static var INST_ADDR_MODE:Array = [
		/*         0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F */
		/*0x00*/ IMP, INX, IMM, INX, ZPG, ZPG, ZPG, ZPG, IMP, IMM, ACM, IMM, ABS, ABS, ABS, ABS,
		/*0x10*/ REL, INY, IMP, INY, ZPX, ZPX, ZPX, ZPX, IMP, ABY, IMP, ABY, ABX, ABX, ABX, ABX,
		/*0x20*/ ABS, INX, IMM, INX, ZPG, ZPG, ZPG, ZPG, IMP, IMM, ACM, IMM, ABS, ABS, ABS, ABS,
		/*0x30*/ REL, INY, IMP, INY, ZPX, ZPX, ZPX, ZPX, IMP, ABY, IMP, ABY, ABX, ABX, ABX, ABX,
		/*0x40*/ IMP, INX, IMM, INX, ZPG, ZPG, ZPG, ZPG, IMP, IMM, ACM, IMM, ABS, ABS, ABS, ABS,
		/*0x50*/ REL, INY, IMP, INY, ZPX, ZPX, ZPX, ZPX, IMP, ABY, IMP, ABY, ABX, ABX, ABX, ABX,
		/*0x60*/ IMP, INX, IMM, INX, ZPG, ZPG, ZPG, ZPG, IMP, IMM, ACM, IMM, IND, ABS, ABS, ABS,
		/*0x70*/ REL, INY, IMP, INY, ZPX, ZPX, ZPX, ZPX, IMP, ABY, IMP, ABY, ABX, ABX, ABX, ABX,
		/*0x80*/ IMM, INX, IMM, INX, ZPG, ZPG, ZPG, ZPG, IMP, IMM, IMP, IMM, ABS, ABS, ABS, ABS,
		/*0x90*/ REL, INY, IMP, INY, ZPX, ZPX, ZPY, ZPY, IMP, ABY, IMP, ABY, ABX, ABX, ABY, ABY,
		/*0xA0*/ IMM, INX, IMM, INX, ZPG, ZPG, ZPG, ZPG, IMP, IMM, IMP, IMM, ABS, ABS, ABS, ABS,
		/*0xB0*/ REL, INY, IMP, INY, ZPX, ZPX, ZPY, ZPY, IMP, ABY, IMP, ABY, ABX, ABX, ABY, ABY,
		/*0xC0*/ IMM, INX, IMM, INX, ZPG, ZPG, ZPG, ZPG, IMP, IMM, IMP, IMM, ABS, ABS, ABS, ABS,
		/*0xD0*/ REL, INY, IMP, INY, ZPX, ZPX, ZPX, ZPX, IMP, ABY, IMP, ABY, ABX, ABX, ABX, ABX,
		/*0xE0*/ IMM, INX, IMM, INX, ZPG, ZPG, ZPG, ZPG, IMP, IMM, IMP, IMM, ABS, ABS, ABS, ABS,
		/*0xF0*/ REL, INY, IMP, INY, ZPX, ZPX, ZPX, ZPX, IMP, ABY, IMP, ABY, ABX, ABX, ABX, ABX,
		];
		
		
		// Registers
		private var PC:uint;  // Program Counter
		private var SP:uint;  // Stack Pointer
		private var P:uint;  // Processor Status
		private var A:uint;  // Accumulator
		private var X:uint;  // Index register X
		private var Y:uint;  // Index register Y
		
		// Instruction Parameters
		private var addressingMode:uint;
		private var param1:int;
		private var param2:int;
		private var paramWord:int;
		private var paramValue:uint;
		
		private var _currentState:CPUState;
		
		// Memory
		// $0000-$07FF - Internal Ram
		// $0800-$17FF - Mirror of Internal Ram
		// Internal Ram
		// $0000-$00FF - Zero Page
		// $0100-$01FF - Stack
		private var _mem:ByteArray;
		
		// External Addresses
		// $2000-$2007 - PPU Registers
		// $2008-$3FFF - Mirror of PPU Registers
		// $4000-$401F - NES APU and IO
		// $4020-$FFFF - Cartridge Space
		
		// View
		private var _emulator:Emulator;
		
		// External Components
		private var _mapper:IMapper;
		
		// Emulation values
		private var _cycleCount:uint = 0;
		private var _scanLine:int = 0;
		
		public function CPU(emulator:Emulator)
		{
			_emulator = emulator;
			
			_currentState = new CPUState();
			
			_mem = new ByteArray();
			_mem.endian = Endian.LITTLE_ENDIAN;
			_mem.length = 0x0800;
		}
		
		public function set mapper(value:IMapper):void
		{
			// TODO: Check for mapper before start/run/execute commands proceed
			_mapper = value;
		}
		
		public function get state():CPUState
		{
			return _currentState;
		}
		
		public function get cycleCount():uint
		{
			return _cycleCount;
		}
		
		public function resetCycleCount():void
		{
			_cycleCount = 0;
		}
		
		public function start(address:uint):void
		{
			PC = readUnsignedWord(address);
			_cycleCount = 7;
			_scanLine = 241;
			SP = 0xFF;
			A = X = Y = 0;
			P = 0x24;
			
			_mem = new ByteArray();
			_mem.endian = Endian.LITTLE_ENDIAN;
			_mem.length = 0x0800;
			
			for (var i:int = 0; i < 800; i++)
			{
				_mem.writeByte(0xFF);
			}
			// set $0008 to $F7
			_mem.position = 0x0008;
			_mem.writeByte(0xF7);
			// set $0009 to $EF
			_mem.position = 0x0009;
			_mem.writeByte(0xEF);
			// Set $000A to $DF
			_mem.position = 0x000A;
			_mem.writeByte(0xDF);
			// set $000F to $BF
			_mem.position = 0x000F;
			_mem.writeByte(0xBF);
			
			// Set up stack
			pushStack(0xFF);
			pushStack(0xFF);
			pushStack(0x00);
			pushStack(0x02);
			pushStack(0x30);  // SP should be 0xFA now
		}
		
		// TODO: change to cycles
		public function run(numInstructions:uint):void
		{
			// Do stuff.
			var instructions:uint = 0;
			var startTime:int = getTimer();
			while (instructions < numInstructions)
			{
				execute();
				if (_currentState.error == true)
				{
					break;
				}
				instructions++;
			}
			var endTime:int = getTimer();
			var deltaTime:Number = (endTime - startTime);
			trace("Finished execution: " + numInstructions + " in " + deltaTime + " milliseconds (" + (numInstructions / deltaTime) + "KIPS).");
			trace(_cycleCount + " cycles: " + (_cycleCount / deltaTime / 1000) + "MHz.");
		}
		
		public function execute():void
		{
			var instruction:uint;
			
			param1 = int.MAX_VALUE;
			param2 = int.MAX_VALUE;
			paramWord = int.MAX_VALUE;
			
			if (Globals.MODE != Globals.NORMAL)
			{
				_currentState.address = PC;
			}
			
			instruction = readUnsignedByte(PC++);
			addressingMode = INST_ADDR_MODE[instruction];
			
			//  Used by automated testing
			if (Globals.MODE != Globals.NORMAL)
			{
				_currentState.opcode = instruction;
				switch (addressingMode)
				{
					// Two bytes for an unsigned word
					case ABS: 
						paramWord = readUnsignedWord(PC);
						paramValue = readUnsignedByte(paramWord);
						break;
					case ABX: 
					case ABY: 
					case IND: 
						paramWord = readUnsignedWord(PC);
						break;
					
					// One byte for a signed value
					case IMM: 
					case REL: 
						param1 = readByte(PC);
						break;
					
					// One byte for an unsigned value
					case ZPG: 
					case ZPX: 
					case ZPY: 
					case INX: 
					case INY: 
						param1 = readUnsignedByte(PC);
						break;
					
					// No paramaters
					case IMP: 
					case ACM: 
						break;
					default: 
						_emulator.log("Unimplemented Addressing Mode: " + addressingMode);
						_currentState.error = true;
						break;
				}
				if (paramWord < int.MAX_VALUE)
				{
					param1 = paramWord & 0xff;
					param2 = (paramWord & 0xff00) >> 8;
				}
				
				_currentState.param1 = param1 == int.MAX_VALUE ? param1 : param1 & 0xFF;
				_currentState.param2 = param2 == int.MAX_VALUE ? param2 : param2 & 0xFF;
				_currentState.A = A;
				_currentState.X = X;
				_currentState.Y = Y;
				_currentState.P = P;
				_currentState.SP = SP;
				_currentState.CYC = _cycleCount;
				_currentState.SL = _scanLine;
			}
			
			// execute instruction			
			_instructions[instruction]();
		
		/*
		   // Calculate scanline
		   if (_cycleCount >= 341)
		   {
		   _scanLine++;
		   _cycleCount -= 341;
		   }
		   if (_scanLine > 260)
		   {
		   _scanLine -= 262;
		   }
		 */
		}
		
		// Memory access
		private function pushStack(value:uint):void
		{
			_mem.position = 0x100 + SP;
			_mem.writeByte(value);
			SP = (SP - 1) & 0xFF;
		}
		
		private function popStack():uint
		{
			SP = (SP + 1) & 0xFF;
			_mem.position = 0x100 + SP;
			return _mem.readUnsignedByte();
		}
		
		private function writeByte(addr:uint, value:uint):void
		{
			value &= 0xFF;
			if (addr < 0x1800)  // Internal Ram
			{
				addr &= 0x7FF;
				_mem.position = addr;
				_mem.writeByte(value);
			}
			else if (addr < 0x4000)  // PPU Registers
			{
				addr &= 0x7;
				// TODO: Write PPU Register
				// for PPU Registers, add write to a queue with # clock cycles since VBI
			}
			else if (addr < 0x4020)
			{
				// Write NES APU/IO Values
			}
			else if (addr < 0x6000)  // Cartridge Expansion Rom??
			{
				// Nothing to write
			}
			else if (addr < 0x8000)  // SRAM (save RAM)
			{
				_mapper.writePrgRamByte(addr, value);
			}
			else  // PRG Rom
			{
				_mapper.writePrgRomByte(addr, value);
			}
		}
		
		public function readByte(addr:uint):int
		{
			// Determine where we are trying to read
			if (addr < 0x1800)  // Internal Ram
			{
				addr &= 0x7FF;
				_mem.position = addr;
				return _mem.readByte();
			}
			else if (addr < 0x4000)  // PPU Registers
			{
				addr &= 0x7;
				// TODO: Get PPU Register
				return 0;
			}
			else if (addr < 0x4020)
			{
				// Get NES APU/IO Values
				return 0;
			}
			else if (addr < 0x6000)  // Cartridge Expansion Rom??
			{
				return 0;
			}
			else if (addr < 0x8000)  // SRAM (save RAM)
			{
				return _mapper.readPrgRomByte(addr);
			}
			else  // PRG Rom
			{
				return _mapper.readPrgRomByte(addr);
			}
		}
		
		private function readUnsignedByte(addr:uint):uint
		{
			// Determine where we are trying to read
			if (addr < 0x1800)  // Internal Ram
			{
				addr &= 0x7FF;
				_mem.position = addr;
				return _mem.readUnsignedByte();
			}
			else if (addr < 0x4000)  // PPU Registers
			{
				addr &= 0x7;
				// TODO: Get PPU Register
				return 0;
			}
			else if (addr < 0x4020)
			{
				// Get NES APU/IO Values
				return 0;
			}
			else if (addr < 0x6000)  // Cartridge Expansion Rom??
			{
				return 0;
			}
			else if (addr < 0x8000)  // SRAM (save RAM)
			{
				return _mapper.readPrgRomUnsignedByte(addr);
			}
			else  // PRG Rom
			{
				return _mapper.readPrgRomUnsignedByte(addr);
			}
		}
		
		private function readWord(addr:uint):int
		{
			// Determine where we are trying to read
			if (addr < 0x1800)  // Internal Ram
			{
				addr &= 0x7FF;
				_mem.position = addr;
				return _mem.readShort();
			}
			else if (addr < 0x4000)  // PPU Registers
			{
				addr &= 0x7;
				// TODO: Get PPU Register
				return 0;
			}
			else if (addr < 0x4020)
			{
				// Get NES APU/IO Values
				return 0;
			}
			else if (addr < 0x6000)  // Cartridge Expansion Rom??
			{
				return 0;
			}
			else if (addr < 0x8000)  // SRAM (save RAM)
			{
				return _mapper.readPrgRomWord(addr);
			}
			else  // PRG Rom
			{
				return _mapper.readPrgRomWord(addr);
			}
		}
		
		private function readUnsignedWord(addr:uint):uint
		{
			// Determine where we are trying to read
			if (addr < 0x1800)  // Internal Ram
			{
				addr &= 0x7FF;
				_mem.position = addr;
				return _mem.readUnsignedShort();
			}
			else if (addr < 0x4000)  // PPU Registers
			{
				addr &= 0x7;
				// TODO: Get PPU Register
				return 0;
			}
			else if (addr < 0x4020)
			{
				// Get NES APU/IO Values
				return 0;
			}
			else if (addr < 0x6000)  // Cartridge Expansion Rom??
			{
				return 0;
			}
			else if (addr < 0x8000)  // SRAM (save RAM)
			{
				return _mapper.readPrgRomUnsignedWord(addr);
			}
			else  // PRG Rom
			{
				return _mapper.readPrgRomUnsignedWord(addr);
			}
		}
		
		// INSTRUCTIONS
		
		private function instrADC_IMM():void
		{
			param1 = readByte(PC++);
			var value:uint = 0;
			value = param1 & 0xFF;
			instrADC(value);
			_cycleCount += 2;
		}
		
		private function instrADC_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			instrADC(value);
			_cycleCount += 3;
		}
		
		private function instrADC_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			instrADC(value);
			_cycleCount += 4;
		}
		
		private function instrADC_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			instrADC(value);
			_cycleCount += 4;
		}
		
		private function instrADC_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			instrADC(value);
			
			// Check for page boundary cross
			if ((paramWord & 0xFF00) != ((paramWord + X) & 0xFF00))
				_cycleCount += 5;
			else
				_cycleCount += 4;
		
		}
		
		private function instrADC_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF);
			instrADC(value);
			
			// Check for page boundary cross
			if ((paramWord & 0xFF00) != ((paramWord + Y) & 0xFF00))
				_cycleCount += 5;
			else
				_cycleCount += 4;
		}
		
		private function instrADC_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			value = (param1 + X) & 0xFF;  // Pointer to address
			if (value == 0xFF)  // Page boundary
				value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = value;
				value = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(value);
			instrADC(value);
			_cycleCount += 6;
		}
		
		private function instrADC_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			value = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(value);
			instrADC(value);
			
			// Check for page boundary cross
			if ((addr & 0xFF00) != ((addr + Y) & 0xFF00))
				_cycleCount += 6;
			else
				_cycleCount += 5;
		}
		
		private function instrADC(value:uint):void
		{
			var result:uint = A + value;
			if (P & CARRY_FLAG)
				result++;
			
			P &= ~(NEGATIVE_FLAG | CARRY_FLAG | OVERFLOW_FLAG | ZERO_FLAG);
			
			if (result & 0x80)
				P |= NEGATIVE_FLAG;
			if (result & 0x100)
				P |= CARRY_FLAG;
			
			var sign:uint = 0;
			// Overflow if A and Value have the same sign, but result is a different sign
			// Could check wtih (A & V & ~R | ~A & ~V & R) & 0x80 .. is that faster?
			if (((sign = A & 0x80) == (value & 0x80)) && (sign != (result & 0x80)))
				P |= OVERFLOW_FLAG;
			
			result &= 0xFF;
			if (result == 0)
				P |= ZERO_FLAG;
			
			A = result;
		}
		
		private function instrAND_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			value = param1 & 0xFF;
			instrAND(value);
			_cycleCount += 2;
		}
		
		private function instrAND_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			instrAND(value);
			_cycleCount += 3;
		}
		
		private function instrAND_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			instrAND(value);
			_cycleCount += 4;
		}
		
		private function instrAND_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			instrAND(value);
			_cycleCount += 4;
		}
		
		private function instrAND_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			instrAND(value);
			
			// Check for page boundary cross
			if ((paramWord & 0xFF00) != ((paramWord + X) & 0xFF00))
				_cycleCount += 5;
			else
				_cycleCount += 4;
		}
		
		private function instrAND_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF);
			instrAND(value);
			
			// Check for page boundary cross
			if ((paramWord & 0xFF00) != ((paramWord + Y) & 0xFF00))
				_cycleCount += 5;
			else
				_cycleCount += 4;
		}
		
		private function instrAND_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			value = (param1 + X) & 0xFF;  // Pointer to address
			if (value == 0xFF)  // Page boundary
				value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = value;
				value = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(value);
			instrAND(value);
			_cycleCount += 6;
		}
		
		private function instrAND_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var addr:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			value = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(value);
			instrAND(value);
			
			// Check for page boundary cross
			if ((addr & 0xFF00) != ((addr + Y) & 0xFF00))
				_cycleCount += 6;
			else
				_cycleCount += 5;
		}
		
		private function instrAND(value:uint):void
		{
			A = A & value & 0xFF;
			
			P &= 0x7D;  // Clear Negative and Zero Flag
			
			if (A == 0)
				P |= ZERO_FLAG;
			
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrASL_ACM():void
		{
			var value:uint = 0;
			value = A << 1;
			A = value & 0xFF;
			instrASL(value);
			_cycleCount += 2;
		}
		
		private function instrASL_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte() << 1;
			_mem.position = param1;
			_mem.writeByte(value & 0xFF);
			instrASL(value);
			_cycleCount += 5;
		}
		
		private function instrASL_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte() << 1;
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(value & 0xFF);
			instrASL(value);
			_cycleCount += 6;
		}
		
		private function instrASL_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord) << 1;
			writeByte(paramWord, value & 0xFF);
			instrASL(value);
			_cycleCount += 6;
		}
		
		private function instrASL_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF) << 1;
			writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
			instrASL(value);
			_cycleCount += 7;
		}
		
		private function instrASL(value:uint):void
		{
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (value & 0x100)
				P |= CARRY_FLAG;
			
			value &= 0xFF;
			
			if (value == 0)
				P |= ZERO_FLAG;
			
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
		
		}
		
		private function instrBCC_REL():void
		{
			param1 = readByte(PC++);
			var rel:int = param1;
			_cycleCount += 2;
			if ((P & CARRY_FLAG) == 0)
			{
				if ((PC & 0xFF00) == ((PC + rel) & 0xFF00))
					_cycleCount += 1;
				else
					_cycleCount += 2;
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBCS_REL():void
		{
			param1 = readByte(PC++);
			var rel:int = param1;
			_cycleCount += 2;
			if (P & CARRY_FLAG)
			{
				if ((PC & 0xFF00) == ((PC + rel) & 0xFF00))
					_cycleCount += 1;
				else
					_cycleCount += 2;
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBEQ_REL():void
		{
			param1 = readByte(PC++);
			var rel:int = param1;
			_cycleCount += 2;
			if (P & ZERO_FLAG)
			{
				if ((PC & 0xFF00) == ((PC + rel) & 0xFF00))
					_cycleCount += 1;
				else
					_cycleCount += 2;
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBIT_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			instrBIT(value);
			_cycleCount += 3;
		}
		
		private function instrBIT_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			instrBIT(value);
			_cycleCount += 4;
		}
		
		private function instrBIT(value:uint):void
		{
			var result:uint = value & A;
			
			P &= 0x3D;  // Clear Zero, Overflow, and Negative Flag
			if (result == 0)
				P |= ZERO_FLAG
			
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
			
			if (value & 0x40)
				P |= OVERFLOW_FLAG;
		}
		
		private function instrBMI_REL():void
		{
			param1 = readByte(PC++);
			var rel:int = param1;
			_cycleCount += 2;
			if (P & NEGATIVE_FLAG)
			{
				if ((PC & 0xFF00) == ((PC + rel) & 0xFF00))
					_cycleCount += 1;
				else
					_cycleCount += 2;
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBNE_REL():void
		{
			param1 = readByte(PC++);
			var rel:int = param1;
			_cycleCount += 2;
			if ((P & ZERO_FLAG) == 0)
			{
				if ((PC & 0xFF00) == ((PC + rel) & 0xFF00))
					_cycleCount += 1;
				else
					_cycleCount += 2;
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBPL_REL():void
		{
			param1 = readByte(PC++);
			var rel:int = param1;
			_cycleCount += 2;
			if ((P & NEGATIVE_FLAG) == 0)
			{
				if ((PC & 0xFF00) == ((PC + rel) & 0xFF00))
					_cycleCount += 1;
				else
					_cycleCount += 2;
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBRK_IMP():void
		{
			pushStack((PC & 0xFF00) >> 8);
			pushStack(PC & 0xFF);
			pushStack(P);
			PC = readUnsignedWord(0xFFFE);
			
			P |= BREAK_FLAG;
			_cycleCount += 7;
		}
		
		private function instrBVC_REL():void
		{
			param1 = readByte(PC++);
			var rel:int = param1;
			_cycleCount += 2;
			if ((P & OVERFLOW_FLAG) == 0)
			{
				if ((PC & 0xFF00) == ((PC + rel) & 0xFF00))
					_cycleCount += 1;
				else
					_cycleCount += 2;
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBVS_REL():void
		{
			param1 = readByte(PC++);
			var rel:int = param1;
			_cycleCount += 2;
			if (P & OVERFLOW_FLAG)
			{
				if ((PC & 0xFF00) == ((PC + rel) & 0xFF00))
					_cycleCount += 1;
				else
					_cycleCount += 2;
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrCLC_IMP():void
		{
			P &= ~CARRY_FLAG;
			_cycleCount += 2;
		}
		
		private function instrCLD_IMP():void
		{
			P &= ~DECIMAL_FLAG;
			_cycleCount += 2;
		}
		
		private function instrCLI_IMP():void
		{
			P &= ~IRQ_FLAG;
			_cycleCount += 2;
		}
		
		private function instrCLV_IMP():void
		{
			P &= ~OVERFLOW_FLAG;
			_cycleCount += 2;
		}
		
		private function instrCMP_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			value = param1 & 0xFF;
			instrCMP(value);
			_cycleCount += 2;
		}
		
		private function instrCMP_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			instrCMP(value);
			_cycleCount += 3;
		}
		
		private function instrCMP_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			instrCMP(value);
			_cycleCount += 4;
		}
		
		private function instrCMP_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			instrCMP(value);
			_cycleCount += 4;
		}
		
		private function instrCMP_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			instrCMP(value);
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + X) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrCMP_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF);
			instrCMP(value);
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + Y) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrCMP_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			value = (param1 + X) & 0xFF;  // Pointer to address
			if (value == 0xFF)  // Page boundary
				value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = value;
				value = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(value);
			instrCMP(value);
			_cycleCount += 6;
		}
		
		private function instrCMP_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var addr:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			value = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(value);
			instrCMP(value);
			// Check for page boundary cross
			if ((addr & 0xFF00) == ((addr + Y) & 0xFF00))
				_cycleCount += 5;
			else
				_cycleCount += 6;
		}
		
		private function instrCMP(value:uint):void
		{
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (A >= value)
				P |= CARRY_FLAG;
			
			if (A == value)
				P |= ZERO_FLAG;
			
			if ((A - value) & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrCPX_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			value = param1 & 0xFF;
			instrCPX(value);
			_cycleCount += 2;
		}
		
		private function instrCPX_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			instrCPX(value);
			_cycleCount += 3;
		}
		
		private function instrCPX_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			instrCPX(value);
			_cycleCount += 4;
		}
		
		private function instrCPX(value:uint):void
		{
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X >= value)
				P |= CARRY_FLAG;
			
			if (X == value)
				P |= ZERO_FLAG;
			
			if ((X - value) & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrCPY_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			value = param1 & 0xFF;
			instrCPY(value);
			_cycleCount += 2;
		}
		
		private function instrCPY_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			instrCPY(value);
			_cycleCount += 3;
		}
		
		private function instrCPY_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			instrCPY(value);
			_cycleCount += 4;
		}
		
		private function instrCPY(value:uint):void
		{
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (Y >= value)
				P |= CARRY_FLAG;
			
			if (Y == value)
				P |= ZERO_FLAG;
			
			if ((Y - value) & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrDEC_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = (_mem.readUnsignedByte() - 1) & 0xFF;
			_mem.position = param1;
			_mem.writeByte(value);
			instrDEC(value);
			_cycleCount += 5;
		}
		
		private function instrDEC_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = (_mem.readUnsignedByte() - 1) & 0xFF;
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(value);
			instrDEC(value);
			_cycleCount += 6;
		}
		
		private function instrDEC_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = (readUnsignedByte(paramWord) - 1) & 0xFF;
			writeByte(paramWord, value);
			instrDEC(value);
			_cycleCount += 6;
		}
		
		private function instrDEC_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = (readUnsignedByte((paramWord + X) & 0xFFFF) - 1) & 0xFF;
			writeByte((paramWord + X) & 0xFFFF, value);
			instrDEC(value);
			_cycleCount += 7;
		}
		
		private function instrDEC(value:uint):void
		{
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (value == 0)
				P |= ZERO_FLAG;
			
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrDEX_IMP():void
		{
			X = (X - 1) & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X == 0)
				P |= ZERO_FLAG;
			
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
			
			_cycleCount += 2;
		}
		
		private function instrDEY_IMP():void
		{
			Y = (Y - 1) & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (Y == 0)
				P |= ZERO_FLAG;
			
			if (Y & 0x80)
				P |= NEGATIVE_FLAG;
			
			_cycleCount += 2;
		}
		
		private function instrEOR_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			value = param1 & 0xFF;
			instrEOR(value);
			_cycleCount += 2;
		}
		
		private function instrEOR_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			instrEOR(value);
			_cycleCount += 3;
		}
		
		private function instrEOR_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			instrEOR(value);
			_cycleCount += 4;
		}
		
		private function instrEOR_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			instrEOR(value);
			_cycleCount += 4;
		}
		
		private function instrEOR_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			instrEOR(value);
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + X) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		
		}
		
		private function instrEOR_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF);
			instrEOR(value);
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + Y) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrEOR_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			value = (param1 + X) & 0xFF;  // Pointer to address
			if (value == 0xFF)  // Page boundary
				value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = value;
				value = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(value);
			instrEOR(value);
			_cycleCount += 6;
		}
		
		private function instrEOR_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			value = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(value);
			instrEOR(value);
			// Check for page boundary cross
			if ((addr & 0xFF00) == ((addr + Y) & 0xFF00))
				_cycleCount += 5;
			else
				_cycleCount += 6;
		}
		
		private function instrEOR(value:uint):void
		{
			A = A ^ value;
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrINC_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = (_mem.readUnsignedByte() + 1) & 0xFF;
			_mem.position = param1;
			_mem.writeByte(value);
			instrINC(value);
			_cycleCount += 5;
		}
		
		private function instrINC_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = (_mem.readUnsignedByte() + 1) & 0xFF;
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(value);
			instrINC(value);
			_cycleCount += 6;
		}
		
		private function instrINC_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = (readUnsignedByte(paramWord) + 1) & 0xFF;
			writeByte(paramWord, value);
			instrINC(value);
			_cycleCount += 6;
		}
		
		private function instrINC_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = (readUnsignedByte((paramWord + X) & 0xFFFF) + 1) & 0xFF;
			writeByte((paramWord + X) & 0xFFFF, value);
			instrINC(value);
			_cycleCount += 7;
		}
		
		private function instrINC(value:uint):void
		{
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (value == 0)
				P |= ZERO_FLAG;
			
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
		
		}
		
		private function instrINX_IMP():void
		{
			X = (X + 1) & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X == 0)
				P |= ZERO_FLAG;
			
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
			
			_cycleCount += 2;
		}
		
		private function instrINY_IMP():void
		{
			Y = (Y + 1) & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (Y == 0)
				P |= ZERO_FLAG;
			
			if (Y & 0x80)
				P |= NEGATIVE_FLAG;
			
			_cycleCount += 2;
		}
		
		private function instrJMP_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			PC = paramWord;
			_cycleCount += 3;
		}
		
		private function instrJMP_IND():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			if (paramWord & 0xFF == 0xFF)
			{
				PC = readUnsignedByte(paramWord);
				paramWord &= 0xFF00;  // +1, -100
				PC |= readUnsignedByte(paramWord) << 8;
			}
			else
			{
				PC = readUnsignedWord(paramWord);
			}
			_cycleCount += 5;
		}
		
		private function instrJSR_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC++;  // JSR saves PC - 1 to stack, no need to +2 then -1
			pushStack((PC & 0xFF00) >> 8);
			pushStack(PC & 0xFF);
			PC = paramWord;
			_cycleCount += 6;
		}
		
		private function instrLDA_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			A = param1 & 0xFF;
			instrLDA();
			_cycleCount += 2;
		}
		
		private function instrLDA_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = param1;
			A = _mem.readUnsignedByte();
			instrLDA();
			_cycleCount += 3;
		}
		
		private function instrLDA_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = (param1 + X) & 0xFF;
			A = _mem.readUnsignedByte();
			instrLDA();
			_cycleCount += 4;
		}
		
		private function instrLDA_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			A = readUnsignedByte(paramWord);
			instrLDA();
			_cycleCount += 4;
		}
		
		private function instrLDA_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			A = readUnsignedByte((paramWord + X) & 0xFFFF);
			instrLDA();
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + X) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrLDA_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			A = readUnsignedByte((paramWord + Y) & 0xFFFF);
			instrLDA();
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + Y) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrLDA_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			addr = (param1 + X) & 0xFF;  // Pointer to address
			if (addr == 0xFF)  // Page boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();  // address
			}
			
			A = readUnsignedByte(addr);
			instrLDA();
			_cycleCount += 6;
		}
		
		private function instrLDA_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			addr = (addr + Y) & 0xFFFF;
			A = readUnsignedByte(addr);
			instrLDA();
			// Check for page boundary cross
			if ((addr & 0xFF00) == ((addr - Y) & 0xFF00))
				_cycleCount += 5;
			else
				_cycleCount += 6;
		}
		
		private function instrLDA():void
		{
			P &= 0x7D;  // Clear Zero Flag and Negative Flag
			
			if (A == 0)
				P |= ZERO_FLAG;
			
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrLDX_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			X = param1 & 0xFF;
			instrLDX();
			_cycleCount += 2;
		}
		
		private function instrLDX_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = param1;
			X = _mem.readUnsignedByte();
			instrLDX();
			_cycleCount += 3;
		}
		
		private function instrLDX_ZPY():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = (param1 + Y) & 0xFF;
			X = _mem.readUnsignedByte();
			instrLDX();
			_cycleCount += 4;
		}
		
		private function instrLDX_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			X = readUnsignedByte(paramWord);
			instrLDX();
			_cycleCount += 4;
		}
		
		private function instrLDX_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			X = readUnsignedByte((paramWord + Y) & 0xFFFF);
			instrLDX();
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + Y) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrLDX():void
		{
			P &= 0x7D;  // Clear Zero and Negative Flags
			
			if (X == 0)
				P |= ZERO_FLAG;
			
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrLDY_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			Y = param1 & 0xFF;
			instrLDY();
			_cycleCount += 2;
		}
		
		private function instrLDY_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = param1;
			Y = _mem.readUnsignedByte();
			instrLDY();
			_cycleCount += 3;
		}
		
		private function instrLDY_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = (param1 + X) & 0xFF;
			Y = _mem.readUnsignedByte();
			instrLDY();
			_cycleCount += 4;
		}
		
		private function instrLDY_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			Y = readUnsignedByte(paramWord);
			instrLDY();
			_cycleCount += 4;
		}
		
		private function instrLDY_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			Y = readUnsignedByte((paramWord + X) & 0xFFFF);
			instrLDY();
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + X) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrLDY():void
		{
			P &= 0x7D;  // Clear Zero and Negative Flags
			
			if (Y == 0)
				P |= ZERO_FLAG;
			
			if (Y & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrLSR_ACM():void
		{
			var value:uint = 0;
			var result:uint = 0;
			value = A;
			result = A >> 1;
			A = result;
			instrLSR(value, result);
			_cycleCount += 2;
		}
		
		private function instrLSR_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var result:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			result = value >> 1;
			_mem.position = param1;
			_mem.writeByte(result);
			instrLSR(value, result);
			_cycleCount += 5;
		}
		
		private function instrLSR_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var result:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			result = value >> 1;
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(result);
			instrLSR(value, result);
			_cycleCount += 6;
		}
		
		private function instrLSR_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte(paramWord);
			result = value >> 1;
			writeByte(paramWord, result);
			instrLSR(value, result);
			_cycleCount += 6;
		}
		
		private function instrLSR_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			result = value >> 1;
			writeByte((paramWord + X) & 0xFFFF, result);
			instrLSR(value, result);
			_cycleCount += 7;
		}
		
		private function instrLSR(value:uint, result:uint):void
		{
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			if (value & 0x01)
				P |= CARRY_FLAG;
			
			if (result == 0)
				P |= ZERO_FLAG;
			
			if (result & 0x80)
				P |= NEGATIVE_FLAG;
		
		}
		
		private function instrNOP_IMP():void
		{
			_cycleCount += 2;
			return;
		}
		
		private function instrNOP_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			_cycleCount += 3;
			return;
		}
		
		private function instrNOP_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			_cycleCount += 4;
			return;
		}
		
		private function instrNOP_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			_cycleCount += 4;
			return;
		}
		
		private function instrNOP_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			_cycleCount += 2;
			return;
		}
		
		private function instrNOP_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + X) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
			return;
		}
		
		private function instrORA_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			value = param1 & 0xFF;
			instrORA(value);
			_cycleCount += 2;
		}
		
		private function instrORA_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			instrORA(value);
			_cycleCount += 3;
		}
		
		private function instrORA_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			instrORA(value);
			_cycleCount += 4;
		}
		
		private function instrORA_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			instrORA(value);
			_cycleCount += 4;
		}
		
		private function instrORA_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			instrORA(value);
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + X) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrORA_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF);
			instrORA(value);
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + Y) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrORA_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			value = (param1 + X) & 0xFF;  // Pointer to address
			if (value == 0xFF)  // Page boundary
				value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = value;
				value = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(value);
			instrORA(value);
			_cycleCount += 6;
		}
		
		private function instrORA_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			value = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(value);
			instrORA(value);
			// Check for page boundary cross
			if ((addr & 0xFF00) == ((addr + Y) & 0xFF00))
				_cycleCount += 5;
			else
				_cycleCount += 6;
		}
		
		private function instrORA(value:uint):void
		{
			A = A | value;
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrPHA_IMP():void
		{
			pushStack(A);
			_cycleCount += 3;
		}
		
		private function instrPHP_IMP():void
		{
			pushStack(P | BREAK_FLAG);  // Break flag is always pushed with a 1			
			_cycleCount += 3;
		}
		
		private function instrPLA_IMP():void
		{
			A = popStack();
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
			_cycleCount += 4;
		}
		
		private function instrPLP_IMP():void
		{
			P = (popStack() & ~BREAK_FLAG) | UNUSED_FLAG;
			_cycleCount += 4;
		}
		
		private function instrROL_ACM():void
		{
			var value:uint = 0;
			value = A;
			value = (A << 1) | (P & CARRY_FLAG);
			A = value & 0xFF;
			instrROL(value);
			_cycleCount += 2;
		}
		
		private function instrROL_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			value = (value << 1) | (P & CARRY_FLAG);
			_mem.position = param1;
			_mem.writeByte(value & 0xFF);
			instrROL(value);
			_cycleCount += 5;
		}
		
		private function instrROL_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			value = (value << 1) | (P & CARRY_FLAG);
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(value & 0xFF);
			instrROL(value);
			_cycleCount += 6;
		}
		
		private function instrROL_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			value = (value << 1) | (P & CARRY_FLAG);
			writeByte(paramWord, value & 0xFF);
			instrROL(value);
			_cycleCount += 6;
		}
		
		private function instrROL_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			value = (value << 1) | (P & CARRY_FLAG);
			writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
			instrROL(value);
			_cycleCount += 7;
		}
		
		private function instrROL(value:uint):void
		{
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			if (value & 0x100)
				P |= CARRY_FLAG;
			
			value &= 0xFF;
			
			if (value == 0)
				P |= ZERO_FLAG;
			
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrROR_ACM():void
		{
			var value:uint = 0;
			var result:uint = 0;
			value = A;
			result = A >> 1 | ((P & CARRY_FLAG) << 7);
			A = result;
			instrROR(value, result);
			_cycleCount += 2;
		}
		
		private function instrROR_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var result:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			result = value >> 1 | ((P & CARRY_FLAG) << 7);
			_mem.position = param1;
			_mem.writeByte(result);
			instrROR(value, result);
			_cycleCount += 5;
		}
		
		private function instrROR_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var result:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			result = value >> 1 | ((P & CARRY_FLAG) << 7);
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(result);
			instrROR(value, result);
			_cycleCount += 6;
		}
		
		private function instrROR_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte(paramWord);
			result = value >> 1 | ((P & CARRY_FLAG) << 7);
			writeByte(paramWord, result);
			instrROR(value, result);
			_cycleCount += 6;
		}
		
		private function instrROR_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			result = value >> 1 | ((P & CARRY_FLAG) << 7);
			writeByte((paramWord + X) & 0xFFFF, result);
			instrROR(value, result);
			_cycleCount += 7;
		}
		
		private function instrROR(value:uint, result:uint):void
		{
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			if (value & 0x01)
				P |= CARRY_FLAG;
			
			if (result == 0)
				P |= ZERO_FLAG;
			
			if (result & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrRTI_IMP():void
		{
			P = (popStack() & ~BREAK_FLAG) | UNUSED_FLAG;
			PC = popStack();
			PC |= popStack() << 8;
			_cycleCount += 6;
		}
		
		private function instrRTS_IMP():void
		{
			PC = popStack();
			PC |= (popStack() << 8);
			PC++;
			_cycleCount += 6;
		}
		
		private function instrSBC_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			value = param1 & 0xFF;
			instrSBC(value);
			_cycleCount += 2;
		}
		
		private function instrSBC_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			instrSBC(value);
			_cycleCount += 3;
		}
		
		private function instrSBC_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			instrSBC(value);
			_cycleCount += 4;
		}
		
		private function instrSBC_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			instrSBC(value);
			_cycleCount += 4;
		}
		
		private function instrSBC_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			instrSBC(value);
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + X) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrSBC_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF);
			instrSBC(value);
			// Check for page boundary cross
			if ((paramWord & 0xFF00) == ((paramWord + Y) & 0xFF00))
				_cycleCount += 4;
			else
				_cycleCount += 5;
		}
		
		private function instrSBC_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			value = (param1 + X) & 0xFF;  // Pointer to address
			if (value == 0xFF)  // Page boundary
				value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = value;
				value = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(value);
			instrSBC(value);
			_cycleCount += 6;
		}
		
		private function instrSBC_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			value = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(value);
			instrSBC(value);
			// Check for page boundary cross
			if ((addr & 0xFF00) == ((addr + Y) & 0xFF00))
				_cycleCount += 5;
			else
				_cycleCount += 6;
		}
		
		private function instrSBC(value:uint):void
		{
			// A,Z,C,N = A-M-(1-C)
			var result:uint = A - value;
			if ((P & CARRY_FLAG) == 0)
				result--;
			
			P &= ~(NEGATIVE_FLAG | OVERFLOW_FLAG | ZERO_FLAG);
			
			if (result & 0x80)
				P |= NEGATIVE_FLAG;
			
			P |= CARRY_FLAG;
			if (result & 0x100)
				P &= ~CARRY_FLAG;
			
			var sign:uint = 0;
			// Overflow if neg - pos = pos or pos - neg = neg
			
			if (((sign = A & 0x80) != (value & 0x80)) && (sign != (result & 0x80)))
				P |= OVERFLOW_FLAG;
			
			result &= 0xFF;
			if (result == 0)
				P |= ZERO_FLAG;
			
			A = result;
		}
		
		private function instrSED_IMP():void
		{
			P |= DECIMAL_FLAG;
			_cycleCount += 2;
		}
		
		private function instrSEC_IMP():void
		{
			P |= CARRY_FLAG;
			_cycleCount += 2;
		}
		
		private function instrSEI_IMP():void
		{
			P |= IRQ_FLAG;
			_cycleCount += 2;
		}
		
		private function instrSTA_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = param1;
			_mem.writeByte(A);
			_cycleCount += 3;
		}
		
		private function instrSTA_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(A);
			_cycleCount += 4;
		}
		
		private function instrSTA_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			writeByte(paramWord, A);
			_cycleCount += 4;
		}
		
		private function instrSTA_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			writeByte((paramWord + X) & 0xFFFF, A);
			_cycleCount += 5;
		}
		
		private function instrSTA_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			writeByte((paramWord + Y) & 0xFFFF, A);
			_cycleCount += 5;
		}
		
		private function instrSTA_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			addr = (param1 + X) & 0xFF;
			if (addr == 0xFF)  // Page Boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();
			}
			writeByte(addr, A);
			_cycleCount += 6;
		}
		
		private function instrSTA_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			if (param1 == 0xFF)  // Page Boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			addr = (addr + Y) & 0xFFFF;
			writeByte(addr, A);
			_cycleCount += 6;
		}
		
		private function instrSTX_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = param1;
			_mem.writeByte(X);
			_cycleCount += 3;
		}
		
		private function instrSTX_ZPY():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = (param1 + Y) & 0xFF;
			_mem.writeByte(X);
			_cycleCount += 4;
		}
		
		private function instrSTX_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			writeByte(paramWord, X);
			_cycleCount += 4;
		}
		
		private function instrSTY_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = param1;
			_mem.writeByte(Y);
			_cycleCount += 3;
		}
		
		private function instrSTY_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(Y);
			_cycleCount += 4;
		}
		
		private function instrSTY_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			writeByte(paramWord, Y);
			_cycleCount += 4;
		}
		
		private function instrTAX_IMP():void
		{
			X = A;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X == 0)
				P |= ZERO_FLAG;
			
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
			_cycleCount += 2;
		}
		
		private function instrTAY_IMP():void
		{
			Y = A;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (Y == 0)
				P |= ZERO_FLAG;
			
			if (Y & 0x80)
				P |= NEGATIVE_FLAG;
			_cycleCount += 2;
		}
		
		private function instrTSX_IMP():void
		{
			X = SP;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X == 0)
				P |= ZERO_FLAG;
			
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
			_cycleCount += 2;
		}
		
		private function instrTXA_IMP():void
		{
			A = X;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (A == 0)
				P |= ZERO_FLAG;
			
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
			_cycleCount += 2;
		}
		
		private function instrTXS_IMP():void
		{
			SP = X;
			_cycleCount += 2;
		}
		
		private function instrTYA_IMP():void
		{
			A = Y;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (A == 0)
				P |= ZERO_FLAG;
			
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
			_cycleCount += 2;
		}
		
		private function instrXXX_XXX():void
		{
			_emulator.log("Invalid instruction.");
			_currentState.error = true;
		}
		
		// Undocumented Instructions
		
		private function instrANC_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			_emulator.log("Unimplemented Instruction: ANC IMM");
			_currentState.error = true;
		}
		
		private function instrANE_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			_emulator.log("Unimplemented Instruction: ANE IMM");
			_currentState.error = true;
		}
		
		private function instrARR_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			_emulator.log("Unimplemented Instruction:  ARR IMM");
			_currentState.error = true;
		}
		
		private function instrASR_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			_emulator.log("Unimplemented Instruction:  ASR IMM");
			_currentState.error = true;
		}
		
		private function instrDCP_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:int = 0;
			_mem.position = param1;
			value = (_mem.readByte() - 1);
			_mem.position = param1;
			_mem.writeByte(value & 0xFF);
			instrDCP(value);
		}
		
		private function instrDCP_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:int = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = (_mem.readByte() - 1);
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(value & 0xFF);
			instrDCP(value);
		}
		
		private function instrDCP_ZPY():void
		{
			param1 = readUnsignedByte(PC++);
			var value:int = 0;
			_mem.position = (param1 + Y) & 0xFF;
			value = (_mem.readByte() - 1);
			_mem.position = (param1 + Y) & 0xFF;
			_mem.writeByte(value & 0xFF);
			instrDCP(value);
		}
		
		private function instrDCP_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:int = 0;
			value = (readByte(paramWord) - 1);
			writeByte(paramWord, value & 0xFF);
			instrDCP(value);
		}
		
		private function instrDCP_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:int = 0;
			value = (readByte((paramWord + X) & 0xFFFF) - 1);
			writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
			instrDCP(value);
		}
		
		private function instrDCP_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:int = 0;
			value = (readByte((paramWord + Y) & 0xFFFF) - 1);
			writeByte((paramWord + Y) & 0xFFFF, value & 0xFF);
			instrDCP(value);
		}
		
		private function instrDCP_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:int = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			addr = (param1 + X) & 0xFF;  // Pointer to address
			if (addr == 0xFF)  // Page boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();  // address
			}
			
			value = (readByte(addr) - 1);
			writeByte(addr, value & 0xFF);
			instrDCP(value);
		}
		
		private function instrDCP_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:int = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			addr = (addr + Y) & 0xFFFF;
			value = (readByte(addr) - 1);
			writeByte(addr, value & 0xFF);
			instrDCP(value);
		}
		
		private function instrDCP(value:uint):void
		{
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (A >= (value & 0xFF))
				P |= CARRY_FLAG;
			
			if (A == (value & 0xFF))
				P |= ZERO_FLAG;
			
			if ((A - value) & 0x80)
				P |= NEGATIVE_FLAG;
		
		}
		
		private function instrISB_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = (_mem.readUnsignedByte() + 1) & 0xFF;
			_mem.position = param1;
			_mem.writeByte(value);
			instrISB(value);
		}
		
		private function instrISB_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = (_mem.readUnsignedByte() + 1) & 0xFF;
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(value);
			instrISB(value);
		}
		
		private function instrISB_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = (readUnsignedByte(paramWord) + 1) & 0xFF;
			writeByte(paramWord, value);
			instrISB(value);
		}
		
		private function instrISB_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = (readUnsignedByte((paramWord + X) & 0xFFFF) + 1) & 0xFF;
			writeByte((paramWord + X) & 0xFFFF, value);
			instrISB(value);
		}
		
		private function instrISB_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = (readUnsignedByte((paramWord + X) & 0xFFFF) + 1) & 0xFF;
			writeByte((paramWord + X) & 0xFFFF, value);
			instrISB(value);
		}
		
		private function instrISB_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			addr = (param1 + X) & 0xFF;  // Pointer to address
			if (addr == 0xFF)  // Page boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();  // address
			}
			
			value = (readByte(addr) + 1) & 0xFF;
			writeByte(addr, value);
			instrISB(value);
		}
		
		private function instrISB_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			addr = (addr + Y) & 0xFFFF;
			value = (readByte(addr) + 1) & 0xFF;
			writeByte(addr, value);
			instrISB(value);
		}
		
		private function instrISB(value:uint):void
		{
			// A,Z,C,N = A-M-(1-C)
			var result:uint = A - value;
			
			if ((P & CARRY_FLAG) == 0)
				result--;
			
			P &= ~(NEGATIVE_FLAG | OVERFLOW_FLAG | ZERO_FLAG);
			
			if (result & 0x80)
				P |= NEGATIVE_FLAG;
			
			P |= CARRY_FLAG;
			if (result & 0x100)
				P &= ~CARRY_FLAG;
			
			var sign:uint = 0;
			// Overflow if neg - pos = pos or pos - neg = neg
			
			if (((sign = A & 0x80) != (value & 0x80)) && (sign != (result & 0x80)))
				P |= OVERFLOW_FLAG;
			
			result &= 0xFF;
			if (result == 0)
				P |= ZERO_FLAG;
			
			A = result;
		
		}
		
		private function instrLAS_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			_emulator.log("Unimplemented Instruction: LAS ABY");
			_currentState.error = true;
		}
		
		private function instrLAX_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = param1;
			A = _mem.readUnsignedByte();
			instrLAX();
		}
		
		private function instrLAX_ZPY():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = (param1 + Y) & 0xFF;
			A = _mem.readUnsignedByte();
			instrLAX();
		}
		
		private function instrLAX_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			A = readUnsignedByte(paramWord);
			instrLAX();
		}
		
		private function instrLAX_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			A = readUnsignedByte((paramWord + Y) & 0xFFFF);
			instrLAX();
		}
		
		private function instrLAX_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			addr = (param1 + X) & 0xFF;  // Pointer to address
			if (addr == 0xFF)  // Page boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();  // address
			}
			
			A = readUnsignedByte(addr);
			instrLAX();
		}
		
		private function instrLAX_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			addr = (addr + Y) & 0xFFFF;
			A = readUnsignedByte(addr);
			instrLAX();
		}
		
		private function instrLAX():void
		{
			P &= 0x7D;  // Clear Zero Flag and Negative Flag
			
			if (A == 0)
				P |= ZERO_FLAG;
			
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
			
			// Update X to complete undocumented behavior
			X = A;
		}
		
		private function instrLXA_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			_emulator.log("Unimplemented Instruction: LXA imm");
			_currentState.error = true;
		}
		
		private function instrRLA_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			value = (value << 1) | (P & CARRY_FLAG);
			_mem.position = param1;
			_mem.writeByte(value & 0xFF);
			instrRLA(value);
		}
		
		private function instrRLA_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			value = (value << 1) | (P & CARRY_FLAG);
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(value & 0xFF);
			instrRLA(value);
		}
		
		private function instrRLA_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord);
			value = (value << 1) | (P & CARRY_FLAG);
			writeByte(paramWord, value & 0xFF);
			instrRLA(value);
		}
		
		private function instrRLA_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			value = (value << 1) | (P & CARRY_FLAG);
			writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
			instrRLA(value);
		}
		
		private function instrRLA_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF);
			value = (value << 1) | (P & CARRY_FLAG);
			writeByte((paramWord + Y) & 0xFFFF, value & 0xFF);
			instrRLA(value);
		}
		
		private function instrRLA_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			addr = (param1 + X) & 0xFF;  // Pointer to address
			if (addr == 0xFF)  // Page boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(addr);
			value = (value << 1) | (P & CARRY_FLAG);
			writeByte(addr, value & 0xFF);
			instrRLA(value);
		}
		
		private function instrRLA_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			addr = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(addr);
			value = (value << 1) | (P & CARRY_FLAG);
			writeByte(addr, value & 0xFF);
			instrRLA(value);
		}
		
		private function instrRLA(value:uint):void
		{
			A = A & value & 0xFF;
			
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			if (value & 0x100)
				P |= CARRY_FLAG;
			
			value &= 0xFF;
			
			if (A == 0)
				P |= ZERO_FLAG;
			
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrRRA_ACM():void
		{
			var value:uint = 0;
			var result:uint = 0;
			value = A;
			result = A >> 1 | ((P & CARRY_FLAG) << 7);
			A = result;
			instrRRA(value, result);
		}
		
		private function instrRRA_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var result:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			result = value >> 1 | ((P & CARRY_FLAG) << 7);
			_mem.position = param1;
			_mem.writeByte(result);
			instrRRA(value, result);
		}
		
		private function instrRRA_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var result:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			result = value >> 1 | ((P & CARRY_FLAG) << 7);
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(result);
			instrRRA(value, result);
		}
		
		private function instrRRA_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte(paramWord);
			result = value >> 1 | ((P & CARRY_FLAG) << 7);
			writeByte(paramWord, result);
			instrRRA(value, result);
		}
		
		private function instrRRA_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			result = value >> 1 | ((P & CARRY_FLAG) << 7);
			writeByte((paramWord + X) & 0xFFFF, result);
			instrRRA(value, result);
		}
		
		private function instrRRA_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF);
			result = value >> 1 | ((P & CARRY_FLAG) << 7);
			writeByte((paramWord + Y) & 0xFFFF, result);
			instrRRA(value, result);
		}
		
		private function instrRRA_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			var result:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			addr = (param1 + X) & 0xFF;  // Pointer to address
			if (addr == 0xFF)  // Page boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(addr);
			result = (value >> 1) | ((P & CARRY_FLAG) << 7);
			writeByte(addr, result);
			instrRRA(value, result);
		}
		
		private function instrRRA_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			var result:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			addr = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(addr);
			result = (value >> 1) | ((P & CARRY_FLAG) << 7);
			writeByte(addr, result);
			instrRRA(value, result);
		}
		
		private function instrRRA(value:uint, result:uint):void
		{
			P &= ~(NEGATIVE_FLAG | CARRY_FLAG | OVERFLOW_FLAG | ZERO_FLAG);
			
			if (value & 0x01)
				P |= CARRY_FLAG;
			
			value = result;
			
			result = A + value;
			if (P & CARRY_FLAG)
				result++;
			
			P &= ~CARRY_FLAG;
			
			if (result & 0x80)
				P |= NEGATIVE_FLAG;
			if (result & 0x100)
				P |= CARRY_FLAG;
			
			var sign:uint = 0;
			// Overflow if A and Value have the same sign, but result is a different sign
			// Could check wtih (A & V & ~R | ~A & ~V & R) & 0x80 .. is that faster?
			if (((sign = A & 0x80) == (value & 0x80)) && (sign != (result & 0x80)))
				P |= OVERFLOW_FLAG;
			
			result &= 0xFF;
			if (result == 0)
				P |= ZERO_FLAG;
			
			A = result;
		}
		
		private function instrSAX_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = param1;
			_mem.writeByte(A & X);
		}
		
		private function instrSAX_ZPY():void
		{
			param1 = readUnsignedByte(PC++);
			_mem.position = (param1 + Y) & 0xFF;
			_mem.writeByte(A & X);
		}
		
		private function instrSAX_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			writeByte(paramWord, A & X);
		}
		
		private function instrSAX_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint;
			addr = (param1 + X) & 0xFF;
			if (addr == 0xFF)  // Page Boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();
			}
			writeByte(addr, A & X);
		}
		
		private function instrSBX_IMM():void
		{
			param1 = readUnsignedByte(PC++);
			_emulator.log("Unimplemented Instruction: SBX IMM");
			_currentState.error = true;
		}
		
		private function instrSHA_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			_emulator.log("Unimplemented Instruction: SHA ABX");
			_currentState.error = true;
		}
		
		private function instrSHA_INY():void
		{
			param1 = readUnsignedByte(PC++);
			_emulator.log("Unimplemented Instruction: SHA INY");
			_currentState.error = true;
		}
		
		private function instrSHS_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			_emulator.log("Unimplemented Instruction: SHS ABY");
			_currentState.error = true;
		}
		
		private function instrSHY_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			_emulator.log("Unimplemented Instruction: SHY ABX");
			_currentState.error = true;
		}
		
		private function instrSHX_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			_emulator.log("Unimplemented Instruction: SHX ABX");
			_currentState.error = true;
		}
		
		private function instrSLO_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte() << 1;
			_mem.position = param1;
			_mem.writeByte(value & 0xFF);
			instrSLO(value);
		}
		
		private function instrSLO_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte() << 1;
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(value & 0xFF);
			instrSLO(value);
		}
		
		private function instrSLO_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte(paramWord) << 1;
			writeByte(paramWord, value & 0xFF);
			instrSLO(value);
		}
		
		private function instrSLO_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF) << 1;
			writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
			instrSLO(value);
		}
		
		private function instrSLO_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF) << 1;
			writeByte((paramWord + Y) & 0xFFFF, value & 0xFF);
			instrSLO(value);
		}
		
		private function instrSLO_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			addr = (param1 + X) & 0xFF;  // Pointer to address
			if (addr == 0xFF)  // Page boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(addr) << 1;
			writeByte(addr, value & 0xFF);
			instrSLO(value);
		}
		
		private function instrSLO_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			addr = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(addr) << 1;
			writeByte(addr, value & 0xFF);
			instrSLO(value);
		}
		
		private function instrSLO(value:uint):void
		{
			A = A | value & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG | CARRY_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
			if (value & 0x100)
				P |= CARRY_FLAG;
		
		}
		
		private function instrSRE_ACM():void
		{
			var value:uint = 0;
			var result:uint = 0;
			value = A;
			result = A >> 1;
			A = result;
			instrSRE(value, result);
		}
		
		private function instrSRE_ZPG():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var result:uint = 0;
			_mem.position = param1;
			value = _mem.readUnsignedByte();
			result = value >> 1;
			_mem.position = param1;
			_mem.writeByte(result);
			instrSRE(value, result);
		}
		
		private function instrSRE_ZPX():void
		{
			param1 = readUnsignedByte(PC++);
			var value:uint = 0;
			var result:uint = 0;
			_mem.position = (param1 + X) & 0xFF;
			value = _mem.readUnsignedByte();
			result = value >> 1;
			_mem.position = (param1 + X) & 0xFF;
			_mem.writeByte(result);
			instrSRE(value, result);
		}
		
		private function instrSRE_ABS():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte(paramWord);
			result = value >> 1;
			writeByte(paramWord, result);
			instrSRE(value, result);
		}
		
		private function instrSRE_ABX():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte((paramWord + X) & 0xFFFF);
			result = value >> 1;
			writeByte((paramWord + X) & 0xFFFF, result);
			instrSRE(value, result);
		}
		
		private function instrSRE_ABY():void
		{
			paramWord = readUnsignedWord(PC);
			PC += 2;
			var value:uint = 0;
			var result:uint = 0;
			value = readUnsignedByte((paramWord + Y) & 0xFFFF);
			result = value >> 1;
			writeByte((paramWord + Y) & 0xFFFF, result);
			instrSRE(value, result);
		}
		
		private function instrSRE_INX():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			var result:uint = 0;
			// Address to read value from is at (param1 + X) & 0xFF
			addr = (param1 + X) & 0xFF;  // Pointer to address
			if (addr == 0xFF)  // Page boundary
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = addr;
				addr = _mem.readUnsignedShort();  // address
			}
			
			value = readUnsignedByte(addr);
			result = value >> 1;
			writeByte(addr, result);
			instrSRE(value, result);
		}
		
		private function instrSRE_INY():void
		{
			param1 = readUnsignedByte(PC++);
			var addr:uint = 0;
			var value:uint = 0;
			var result:uint = 0;
			if (param1 == 0xFF)
				addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
			else
			{
				_mem.position = param1;
				addr = _mem.readUnsignedShort();
			}
			
			addr = (addr + Y) & 0xFFFF;
			value = readUnsignedByte(addr);
			result = value >> 1;
			writeByte(addr, result);
			instrSRE(value, result);
		}
		
		private function instrSRE(value:uint, result:uint):void
		{
			A = A ^ result;
			
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (value & 0x01)
				P |= CARRY_FLAG;
			
			if (A == 0)
				P |= ZERO_FLAG;
			
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		// C000  4C F5 C5  JMP $C5F5                       A:00 X:00 Y:00 P:24 SP:FD CYC:  0 SL:241
		
		private function paramsToStr(p1:uint, p2:uint, pW:uint, inst:uint, addr:uint):String
		{
			var str:String = StringUtils.hexToStr(inst) + " ";
			
			if (pW != int.MAX_VALUE)
			{
				p1 = pW & 0x00FF;
				p2 = (pW & 0xFF00) >> 8;
			}
			
			if (p1 != int.MAX_VALUE)
			{
				str += StringUtils.hexToStr(p1 & 0xFF) + " ";
			}
			else
			{
				str += "   ";
			}
			
			if (p2 != int.MAX_VALUE)
			{
				str += StringUtils.hexToStr(p2 & 0xFF) + "  ";
			}
			else
			{
				str += "    ";
			}
			
			str += INST_NAME[inst] + " ";
			
			switch (addr)
			{
				case ABS: 
					str += "ABS $";
					str += StringUtils.hexToStr(pW & 0xFFFF, 4);
					break;
				case IMM: 
					str += "IMM #$" + StringUtils.hexToStr(p1 & 0xFF);
					break;
				case ZPG: 
					str += "ZPG $" + StringUtils.hexToStr(p1 & 0xFF) + " = ";
					_mem.position = p1 & 0xFF;
					str += StringUtils.hexToStr(_mem.readUnsignedByte());
					break;
				case IMP: 
					break;
				case REL: 
					str += "REL $" + StringUtils.hexToStr((PC + p1) & 0x1FFFF, 4);
					break;
				default: 
					str += "?????";
			}
			
			// Pad params with spaces
			while (str.length < 42)
				str += " ";
			return str;
		}
		
		// A:11 X:23 Y:11 P:65 SP:FB CYC:190 SL:13
		private function stateToStr():String
		{
			var str:String = "A:" + StringUtils.hexToStr(A);
			str += " X:" + StringUtils.hexToStr(X);
			str += " Y:" + StringUtils.hexToStr(Y);
			str += " P:" + StringUtils.hexToStr(P);
			str += " SP:" + StringUtils.hexToStr(SP);
			str += " CYC:" + _cycleCount;
			str += " SL:" + _scanLine;
			return str;
		}
	
	}

}