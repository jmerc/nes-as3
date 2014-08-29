package net.johnmercer.nes.system 
{
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
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
			var param1:int = -1;
			var param2:int = -1;
			var paramWord:int = -1;
			
			debugStr = PC.toString(16) + "  ";
			
			instruction = _mapper.readPRGByte(PC++);
			addressingMode = INST_ADDR_MODE[instruction];
			
			switch(addressingMode)
			{
				case ABS:
				case IND:
					paramWord = _mapper.readPRGWord(PC);
					PC += 2;
					break;
				case IMM:
					param1 = _mapper.readPRGByte(PC++);
					break;
				case ZPG:
					param1 = _mapper.readPRGByte(PC++);
					break;
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
				case "JMP":
					instrJMP(addressingMode, param1, param2, paramWord);
					break;
				case "LDX":
					instrLDX(addressingMode, param1, param2, paramWord);
					break;
				case "STX":
					instrSTX(addressingMode, param1, param2, paramWord);
					break;
				case "JSR":
					instrJSR(addressingMode, param1, param2, paramWord);
					break;
				case "NOP":
					instrNOP(addressingMode, param1, param2, paramWord);
					break;
				case "SEC":
					instrSEC(addressingMode, param1, param2, paramWord);
					break;
				default:
					_emulator.log("Unimplemented instruction");
					break;
			}
			
		}
		
		private function pushStack(value:uint):void
		{
			SP = (SP - 1) & 0xFF;
			_mem.position = 0x100 + SP;
			_mem.writeByte(value);
		}
		
		// INSTRUCTIONS
		private function instrJMP(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case ABS:
					PC = paramWord
					break;
				case IND:
					PC = _mapper.readPRGWord(paramWord);
					break;
				default:
					_emulator.log("Invalid addressing mode " + addressingMode + " for Instruction: JMP");
					break;
			}
		}
		
		private function instrLDX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMM:
					X = param1;
					break;
				default:
					_emulator.log("Invalid addressing mode " + addressingMode + " for Instruction: LDX");
					break;
			}
			// Update Flags
			if (X == 0)
				P |= ZERO_FLAG;
			else
				P &= ~ZERO_FLAG;
				
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
			else
				P &= ~NEGATIVE_FLAG;
		}
		
		private function instrSTX(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					_mem.writeByte(X);
					break;
				default:
					_emulator.log("Invalid addressing mode " + addressingMode + " for Instruction: LDX");
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
					_emulator.log("Invalid addressing mode " + addressingMode + " for Instruction: LDX");
					break;
			}
		}
		
		private function instrNOP(addressingMode:uint, param1:uint, param2:uint, paramWord:uint):void
		{
			switch (addressingMode)
			{
				case IMP:
					break;
				default:
					_emulator.log("Invalid addressing mode " + addressingMode + " for Instruction: LDX");
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
					_emulator.log("Invalid addressing mode " + addressingMode + " for Instruction: LDX");
					break;
			}
		}
		
		
		// C000  4C F5 C5  JMP $C5F5                       A:00 X:00 Y:00 P:24 SP:FD CYC:  0 SL:241
		
		private function paramsToStr(p1:int, p2:int, pW:int, inst:uint, addr:uint):String
		{
			var str:String = hexToStr(inst) + " ";
			
			if (pW >= 0)
			{
				p1 = pW & 0x00FF;
				p2 = (pW & 0xFF00) >> 8;
			}
			
			if (p1 >= 0)
			{
				str += hexToStr(p1) + " "; 
			}
			else
			{
				str += "   ";
			}
			
			if (p2 >= 0)
			{
				str += hexToStr(2) + "  "; 
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
					str += hexToStr(pW, 4);
					break;
				case IMM:
					str += "IMM #$" + hexToStr(p1);
					break;
				case ZPG:
					str += "ZPG $" + hexToStr(p1) + " = ";
					str += hexToStr(X);
					break;
				case IMP:
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
		
		private function hexToStr(number:uint, width:int = 2):String 
		{
			var ret:String = number.toString(16);
			while( ret.length < width )
				ret="0" + ret;
			return ret;
		}
		
	}

}