package net.johnmercer.nes.system 
{
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import net.johnmercer.nes.utils.Debug;
	import net.johnmercer.nes.view.Emulator;
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class CPU 
	{	
		// Processor Status Flags
		private static const CARRY_FLAG:uint    = 0x01;
		private static const ZERO_FLAG:uint     = 0x02;
		private static const IRQ_FLAG:uint      = 0x04;
		private static const DECIMAL_FLAG:uint  = 0x08; // Unused
		private static const BREAK_FLAG:uint    = 0x10;
		private static const UNUSED_FLAG:uint   = 0x20;
		private static const OVERFLOW_FLAG:uint = 0x40;
		private static const NEGATIVE_FLAG:uint = 0x80;
		
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
		private static var INST_NAME:Array = [
		/*0x00*/ "BRK", "ORA", "XXX", "SLO", "NOP", "ORA", "ASL", "SLO", "PHP", "ORA", "ASL", "ANC", "NOP", "ORA", "ASL", "SLO",
		/*0x10*/ "BPL", "ORA", "XXX", "SLO", "NOP", "ORA", "ASL", "SLO", "CLC", "ORA", "NOP", "SLO", "NOP", "ORA", "ASL", "SLO",
		/*0x20*/ "JSR", "AND", "XXX", "RIA", "BIT", "AND", "ROL", "RLA", "PLP", "AND", "ROL", "ANC", "BIT", "AND", "ROL", "RLA",
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
		
		// Addressing Types
		private static const IMP:uint = 0; // Implicit
		private static const IMM:uint = 1; // Immediate
		private static const ZPG:uint = 2; // Zero Page
		private static const ZPX:uint = 3; // Zero Page, X
		private static const ZPY:uint = 4; // Zero Page, Y
		private static const ABS:uint = 5; // Absolute
		private static const ABX:uint = 6; // Absolute, X
		private static const ABY:uint = 7; // Absolute, Y
		private static const IND:uint = 8; // Indirect
		private static const INX:uint = 9; // (Indirect, X)
		private static const INY:uint = 10; // (Indirect), Y
		private static const REL:uint = 11; // Relative
		private static const ACM:uint = 12; // Accumulator
		private static var ADDR_NAME:Array = [
		"IMP", "IMM", "ZPG", "ZPX", "ZPY", "ABS", "ABX", "ABY", "IND", "INX", "INY", "REL", "ACM"
		];
		
		
		// Addressing mode of instruction
		private static var INST_ADDR_MODE:Array = [
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
		private var _rom:ROM;
		private var _mapper:Mapper;
		
		// Emulation values
		private var _cycleCount:uint = 0;
		private var _scanLine:uint = 0;
		
		
		public function CPU(emulator:Emulator, rom:ROM, mapper:Mapper) 
		{
			_emulator = emulator;
			_rom = rom;
			_mapper = mapper;
			
			_mem = new ByteArray();
			_mem.length = 0x0800;
		}
		
		public function loadRom(rom:ROM):void
		{
			_rom = rom;
		}
		
		public function start(address:uint):void
		{
			PC = address;
			_cycleCount = 0;
			SP = 0xFD;
			A = X = Y = 0;
			P = 0x24;
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
				instructions++;
			}
			var endTime:int = getTimer();
			var deltaTime:Number = (endTime - startTime);
			trace("Finished execution: " + numInstructions + " in " + deltaTime + " milliseconds (" +
			(numInstructions / deltaTime) + "KHz).");
		}
		
		public function execute():void
		{
			var debugStr:String = "";
			var instruction:uint;
			var addressingMode:uint;
			var param1:int = int.MAX_VALUE;
			var param2:int = int.MAX_VALUE;
			var paramWord:int = int.MAX_VALUE;
			
			debugStr = hexToStr(PC,4) + "  ";
			
			instruction = readUnsignedByte(PC++);
			addressingMode = INST_ADDR_MODE[instruction];
			
			switch(addressingMode)
			{
				// Two bytes for an unsigned word
				case ABS:
				case ABX:
				case ABY:
				case IND:
					paramWord = readUnsignedWord(PC);
					PC += 2;
					break;
					
				// One byte for a signed value
				case IMM:
				case REL:
					param1 = readByte(PC++);
					break;
					
				// One byte for an unsigned value
				case ZPG:
				case ZPX:
				case ZPX:
				case INX:
				case INY:
					param1 = readUnsignedByte(PC++);
					break;
					
				// No paramaters
				case IMP:
					break;
				default:
					_emulator.log("Unimplemented Addressing Mode: " + addressingMode);
					break;
			}
			
			debugStr += paramsToStr(param1, param2, paramWord, instruction, addressingMode);
			debugStr += stateToStr();
			_emulator.log(debugStr);
			
			// execute instruction
			// Todo: replace switch statement with function lookup table (test speed effect)
			switch(INST_NAME[instruction])
			{
				case "ADC":
					instrADC(addressingMode, param1, param2, paramWord);
					break;
				case "AND":
					instrAND(addressingMode, param1, param2, paramWord);
					break;
				case "ASL":
					instrASL(addressingMode, param1, param2, paramWord);
					break;
				case "BCC":
					instrBCC(addressingMode, param1, param2, paramWord);
					break;
				case "BCS":
					instrBCS(addressingMode, param1, param2, paramWord);
					break;
				case "BEQ":
					instrBEQ(addressingMode, param1, param2, paramWord);
					break;
				case "BIT":
					instrBIT(addressingMode, param1, param2, paramWord);
					break;
				case "BMI":
					instrBMI(addressingMode, param1, param2, paramWord);
					break;
				case "BNE":
					instrBNE(addressingMode, param1, param2, paramWord);
					break;
				case "BPL":
					instrBPL(addressingMode, param1, param2, paramWord);
					break;
				case "BRK":
					instrBRK(addressingMode, param1, param2, paramWord);
					break;
				case "BVC":
					instrBVC(addressingMode, param1, param2, paramWord);
					break;
				case "BVS":
					instrBVS(addressingMode, param1, param2, paramWord);
					break;
				case "CLC":
					instrCLC(addressingMode, param1, param2, paramWord);
					break;
				case "CLD":
					instrCLD(addressingMode, param1, param2, paramWord);
					break;
				case "CLI":
					instrCLI(addressingMode, param1, param2, paramWord);
					break;
				case "CLV":
					instrCLV(addressingMode, param1, param2, paramWord);
					break;
				case "CMP":
					instrCMP(addressingMode, param1, param2, paramWord);
					break;
				case "CPX":
					instrCPX(addressingMode, param1, param2, paramWord);
					break;
				case "CPY":
					instrCPY(addressingMode, param1, param2, paramWord);
					break;
				case "DEC":
					instrDEC(addressingMode, param1, param2, paramWord);
					break;
				case "DEX":
					instrDEX(addressingMode, param1, param2, paramWord);
					break;
				case "DEY":
					instrDEY(addressingMode, param1, param2, paramWord);
					break;
				case "EOR":
					instrEOR(addressingMode, param1, param2, paramWord);
					break;
				case "INC":
					instrINC(addressingMode, param1, param2, paramWord);
					break;
				case "INX":
					instrINX(addressingMode, param1, param2, paramWord);
					break;
				case "INY":
					instrINY(addressingMode, param1, param2, paramWord);
					break;
				case "JMP":
					instrJMP(addressingMode, param1, param2, paramWord);
					break;
				case "JSR":
					instrJSR(addressingMode, param1, param2, paramWord);
					break;
				case "LDA":
					instrLDA(addressingMode, param1, param2, paramWord);
					break;
				case "LDX":
					instrLDX(addressingMode, param1, param2, paramWord);
					break;
				case "LDY":
					instrLDY(addressingMode, param1, param2, paramWord);
					break;
				case "LSR":
					instrLSR(addressingMode, param1, param2, paramWord);
					break;
				case "NOP":
					instrNOP(addressingMode, param1, param2, paramWord);
					break;
				case "ORA":
					instrORA(addressingMode, param1, param2, paramWord);
					break;
				case "PHA":
					instrPHA(addressingMode, param1, param2, paramWord);
					break;
				case "PHP":
					instrPHP(addressingMode, param1, param2, paramWord);
					break;
				case "PLA":
					instrPLA(addressingMode, param1, param2, paramWord);
					break;
				case "PLP":
					instrPLP(addressingMode, param1, param2, paramWord);
					break;
				case "ROL":
					instrROL(addressingMode, param1, param2, paramWord);
					break;
				case "ROR":
					instrROR(addressingMode, param1, param2, paramWord);
					break;
				case "RTI":
					instrRTI(addressingMode, param1, param2, paramWord);
					break;
				case "RTS":
					instrRTS(addressingMode, param1, param2, paramWord);
					break;
				case "SBC":
					instrSBC(addressingMode, param1, param2, paramWord);
					break;
				case "SEC":
					instrSEC(addressingMode, param1, param2, paramWord);
					break;
				case "SED":
					instrSED(addressingMode, param1, param2, paramWord);
					break;
				case "SEI":
					instrSEI(addressingMode, param1, param2, paramWord);
					break;
				case "STA":
					instrSTA(addressingMode, param1, param2, paramWord);
					break;
				case "STX":
					instrSTX(addressingMode, param1, param2, paramWord);
					break;
				case "STY":
					instrSTY(addressingMode, param1, param2, paramWord);
					break;
				case "TAX":
					instrTAX(addressingMode, param1, param2, paramWord);
					break;
				case "TAY":
					instrTAY(addressingMode, param1, param2, paramWord);
					break;
				case "TSX":
					instrTSX(addressingMode, param1, param2, paramWord);
					break;
				case "TXA":
					instrTXA(addressingMode, param1, param2, paramWord);
					break;
				case "TXS":
					instrTXS(addressingMode, param1, param2, paramWord);
					break;
				case "TYA":
					instrTYA(addressingMode, param1, param2, paramWord);
					break;
				case "XXX":
					instrXXX(addressingMode, param1, param2, paramWord);
					break;					
				default:
					_emulator.log("Unimplemented instruction" + instruction + ":" + (INST_NAME[instruction]?INST_NAME[instruction]:"Unknown"));
					break;
			}
			
		}
		
		// Memory access
		private function pushStack(value:uint):void
		{
			SP = (SP - 1) & 0xFF;
			_mem.position = 0x100 + SP;
			_mem.writeByte(value);
		}
		
		private function popStack():uint
		{
			_mem.position = 0x100 + SP;
			SP = (SP + 1) & 0xFF;
			return _mem.readUnsignedByte();
		}
		
		private function writeByte(addr:uint, value:uint):void
		{
			_mem.position = addr;
			_mem.writeByte(value);
		}
		
		private function readByte(addr:uint):int
		{
			// Determine where we are trying to read
			if (addr < 0x1800)  // Internal Ram
			{
				addr &= 0x0FFF;
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
			else
			{
				return _mapper.readByte(addr);
			}
		}
		
		private function readUnsignedByte(addr:uint):uint
		{
			// Determine where we are trying to read
			if (addr < 0x1800)  // Internal Ram
			{
				addr &= 0x0FFF;
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
			else
			{
				return _mapper.readUnsignedByte(addr);
			}
		}

		private function readWord(addr:uint):int
		{
			// Determine where we are trying to read
			if (addr < 0x1800)  // Internal Ram
			{
				addr &= 0x0FFF;
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
			else
			{
				return _mapper.readWord(addr);
			}
		}
		private function readUnsignedWord(addr:uint):uint
		{
			// Determine where we are trying to read
			if (addr < 0x1800)  // Internal Ram
			{
				addr &= 0x0FFF;
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
			else
			{
				return _mapper.readUnsignedWord(addr);
			}
		}
		// INSTRUCTIONS
		
		private function instrADC(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			var value:uint = 0;
			var result:uint = 0;
			switch (addressingMode)
			{
				case IMM:
					value = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					break;
				case ABX:
					value = readUnsignedByte(paramWord + X);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte(paramWord + Y);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					value = (param1 + X) & 0xFF; // Pointer to address
					if (value == 0xFF)  // Page boundary
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = value;
						value = _mem.readUnsignedShort(); // address
					}
						
					value = readUnsignedByte(value);
					break;
				case INY:
					if (param1 == 0xFF)
						value = readUnsignedByte(value) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
						
					value += Y;
					value = readUnsignedByte(value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ADC");
					break;
			}
			
			result = A + value;
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
		
		private function instrAND(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			var value:uint = 0;
			switch (addressingMode)
			{
				case IMM:
					value = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					break;
				case ABX:
					value = readUnsignedByte(paramWord + X);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte(paramWord + Y);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					value = (param1 + X) & 0xFF; // Pointer to address
					if (value == 0xFF)  // Page boundary
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = value;
						value = _mem.readUnsignedShort(); // address
					}
						
					value = readUnsignedByte(value);
					break;
				case INY:
					if (param1 == 0xFF)
						value = readUnsignedByte(value) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
						
					value += Y;
					value = readUnsignedByte(value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: AND");
					break;
			}
			
			A = A & value & 0xFF;
			
			P &= 0x7D;  // Clear Negative and Zero Flag
			
			if (A == 0)
				P |= ZERO_FLAG;
				
			if (A & 0x80)
				P |= NEGATIVE_FLAG;			
		}
		
		private function instrASL(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ASL");
					break;
			}
		}
		
		private function instrBCC(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case REL:
					if ((P & CARRY_FLAG) == 0)
					{
						PC += param1;
					}
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BCC");
					break;
			}
		}
		
		private function instrBCS(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case REL:
					if (P & CARRY_FLAG)
					{
						PC += param1;
					}
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BCS");
					break;
			}
		}
		
		private function instrBEQ(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case REL:
					if (P & ZERO_FLAG)
					{
						PC += param1;
					}
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BEQ");
					break;
			}
		}
		
		private function instrBIT(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			var result:uint = 0;
			var value:uint = 0;
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BIT");
					break;
			}
			result = value & A;
			
			P &= 0x3D; // Clear Zero, Overflow, and Negative Flag
			if (result == 0)
				P |= ZERO_FLAG
				
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
			
			if (value & 0x40)
				P |= OVERFLOW_FLAG;
		}
		
		private function instrBMI(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case REL:
					if (P &  NEGATIVE_FLAG)
					{
						PC += param1;
					}
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BMI");
					break;
			}
		}
		
		private function instrBNE(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case REL:
					if ((P & ZERO_FLAG) == 0)
					{
						PC += param1;
					}
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BNE");
					break;
			}
		}
		
		private function instrBPL(addressingMode:uint, param1:int, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case REL:
					if ((P & NEGATIVE_FLAG) == 0)
					{
						PC += param1;
					}
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BPL");
					break;
			}
		}
		
		private function instrBRK(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BRK");
					break;
			}
		}
		
		private function instrBVC(addressingMode:uint, param1:int, param2:uint, paramWord:uint):void
		{
			var address:uint = 0;
			switch (addressingMode)
			{
				case REL:
					address = PC + param1;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BVC");
					break;
			}
			if ((P & OVERFLOW_FLAG) == 0)
			{
				PC = address;
			}
		}
		
		private function instrBVS(addressingMode:uint, param1:int, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case REL:
					if (P & OVERFLOW_FLAG)
					{
						PC += param1;
					}
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BVS");
					break;
			}
		}
		
		private function instrCLC(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					P &=  ~CARRY_FLAG;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CLC");
					break;
			}
		}
		
		private function instrCLD(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					P &= ~DECIMAL_FLAG;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CLD");
					break;
			}
		}
		
		private function instrCLI(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					P &= ~IRQ_FLAG;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CLI");
					break;
			}
		}
		
		private function instrCLV(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					P &= ~OVERFLOW_FLAG;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CLV");
					break;
			}
		}
		
		private function instrCMP(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			var value:uint;
			switch (addressingMode)
			{
				case IMM:
					value = param1 & 0xFF;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CMP");
					break;
			}
			
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (A >= value)
				P |= CARRY_FLAG;
			
			if (A == value)
				P |= ZERO_FLAG;
				
			if ((A - value) & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrCPX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			var value:uint;
			switch (addressingMode)
			{
				case IMM:
					value = param1 & 0xFF;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CPX");
					break;
			}
			
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X >= value)
				P |= CARRY_FLAG;
			
			if (X == value)
				P |= ZERO_FLAG;
				
			if ((X - value) & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrCPY(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			var value:uint;
			switch (addressingMode)
			{
				case IMM:
					value = param1 & 0xFF;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CPY");
					break;
			}
			
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (Y >= value)
				P |= CARRY_FLAG;
			
			if (Y == value)
				P |= ZERO_FLAG;
				
			if ((Y - value) & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrDEC(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: DEC");
					break;
			}
		}
		
		private function instrDEX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: DEX");
					break;
			}
		}
		
		private function instrDEY(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: DEY");
					break;
			}
		}
		
		private function instrEOR(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			var value:uint = 0;
			switch (addressingMode)
			{
				case IMM:
					value = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					break;
				case ABX:
					value = readUnsignedByte(paramWord + X);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte(paramWord + Y);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					value = (param1 + X) & 0xFF; // Pointer to address
					if (value == 0xFF)  // Page boundary
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = value;
						value = _mem.readUnsignedShort(); // address
					}
						
					value = readUnsignedByte(value);
					break;
				case INY:
					if (param1 == 0xFF)
						value = readUnsignedByte(value) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
						
					value += Y;
					value = readUnsignedByte(value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ADC");
					break;
			}
			A = A ^ value;
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
			
		}
		
		private function instrINC(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: INC");
					break;
			}
		}
		
		private function instrINX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: INX");
					break;
			}
		}
		
		private function instrINY(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: INY");
					break;
			}
		}
		
		private function instrJMP(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case ABS:
					PC = paramWord
					break;
				case IND:
					PC = readWord(paramWord);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: JMP");
					break;
			}
		}
		
		private function instrJSR(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case ABS:
					pushStack((PC & 0xFF00) >> 8);
					pushStack(PC & 0xFF);
					PC = paramWord;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: JSR");
					break;
			}
		}
		
		private function instrLDA(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMM:
					A = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					A = _mem.readUnsignedByte();
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LDA");
					break;
			}
			
			P &= 0x7D; // Clear Zero Flag and Negative Flag
			
			if (A == 0)
				P |= ZERO_FLAG;
				
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrLDX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMM:
					X = param1;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LDX");
					break;
			}
			P &= 0x7D; // Clear Zero and Negative Flags
			
			if (X == 0)
				P |= ZERO_FLAG;
				
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrLDY(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LDY");
					break;
			}
		}
		
		private function instrLSR(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LSR");
					break;
			}
		}
		
		private function instrNOP(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					// No Op
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: NOP");
					break;
			}
		}
		
		private function instrORA(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			var value:uint = 0;
			switch (addressingMode)
			{
				case IMM:
					value = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					break;
				case ABX:
					value = readUnsignedByte(paramWord + X);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte(paramWord + Y);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					value = (param1 + X) & 0xFF; // Pointer to address
					if (value == 0xFF)  // Page boundary
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = value;
						value = _mem.readUnsignedShort(); // address
					}
						
					value = readUnsignedByte(value);
					break;
				case INY:
					if (param1 == 0xFF)
						value = readUnsignedByte(value) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
						
					value += Y;
					value = readUnsignedByte(value);
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ORA");
					break;
			}
			A = A | value;
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrPHA(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:	
					pushStack(A);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: PHA");
					break;
			}
		}
		
		private function instrPHP(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					pushStack(P | BREAK_FLAG);  // Break flag is always pushed with a 1
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: PHP");
					break;
			}
		}
		
		private function instrPLA(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					A = popStack();
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: PLA");
					break;
			}
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrPLP(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					P = (popStack() & ~BREAK_FLAG) | UNUSED_FLAG;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: PLP");
					break;
			}
		}
		
		private function instrROL(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ROL");
					break;
			}
		}
		
		private function instrROR(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ROR");
					break;
			}
		}
		
		private function instrRTI(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: RTL");
					break;
			}
		}
		
		private function instrRTS(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					PC = popStack();
					PC |= (popStack() << 8);
					break;					
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: RTS");
					break;
			}
		}
		
		private function instrSBC(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SBC");
					break;
			}
		}
		
		private function instrSED(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					P |= DECIMAL_FLAG;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SED");
					break;
			}
		}
		
		private function instrSEC(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					P |= CARRY_FLAG;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SEC");
					break;
			}
		}
		
		private function instrSEI(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					P |= IRQ_FLAG;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SEI");
					break;
			}
		}
		
		private function instrSTA(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					_mem.writeByte(A);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: STA");
					break;
			}
		}
		
		private function instrSTX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case ZPG:
					_mem.writeByte(X);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: STX");
					break;
			}
		}
		
		private function instrSTY(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: STY");
					break;
			}
		}
		
		private function instrTAX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: TAX");
					break;
			}
		}
		
		private function instrTAY(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: TAY");
					break;
			}
		}
		
		private function instrTSX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: TSX");
					break;
			}
		}
		
		private function instrTXA(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: TXA");
					break;
			}
		}
		
		private function instrTXS(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: TXS");
					break;
			}
		}
		
		private function instrTYA(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: TYA");
					break;
			}
		}
		
		private function instrXXX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			_emulator.log("Invalid Opcode read, ignoring");
		}
		
		
		
		
		// C000  4C F5 C5  JMP $C5F5                       A:00 X:00 Y:00 P:24 SP:FD CYC:  0 SL:241
		
		private function paramsToStr(p1:uint, p2:uint, pW:uint, inst:uint, addr:uint):String
		{
			var str:String = hexToStr(inst) + " ";

			if (pW != int.MAX_VALUE)
			{
				p1 = pW & 0x00FF;
				p2 = (pW & 0xFF00) >> 8;
			}
			
			if (p1 != int.MAX_VALUE)
			{
				str += hexToStr(p1 & 0xFF) + " "; 
			}
			else
			{
				str += "   ";
			}
			
			if (p2 != int.MAX_VALUE)
			{
				str += hexToStr(p2 & 0xFF) + "  "; 
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
					str += hexToStr(pW & 0xFFFF, 4);
					break;
				case IMM:
					str += "IMM #$" + hexToStr(p1 & 0xFF);
					break;
				case ZPG:
					str += "ZPG $" + hexToStr(p1 & 0xFF) + " = ";
					_mem.position = p1 & 0xFF;
					str += hexToStr(_mem.readUnsignedByte());
					break;
				case IMP:
					break;
				case REL:
					str += "REL $" + hexToStr((PC + p1) & 0x1FFFF,4);
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
			var str:String = "A:" + hexToStr(A);
			str += " X:" + hexToStr(X);
			str += " Y:" + hexToStr(Y);
			str += " P:" + hexToStr(P);
			str += " SP:" + hexToStr(SP);
			str += " CYC:" + _cycleCount;
			str += " SL:" + _scanLine;
			return str;
		}
		
		private function hexToStr(value:uint, width:int = 2):String 
		{
			var ret:String;
			if (width == 2)
			{
				ret = (value).toString(16);
			}
			else if (width == 4)
			{
				ret = (value).toString(16);				
			}
			else
			{
				ret = value.toString(16);				
			}
			while( ret.length < width )
				ret="0" + ret;
			return ret.toUpperCase();
		}
		
	}

}