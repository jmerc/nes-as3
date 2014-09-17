package net.johnmercer.nes.system 
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.utils.getTimer;
	import net.johnmercer.nes.tests.CPUState;
	import net.johnmercer.nes.utils.Debug;
	import net.johnmercer.nes.utils.StringUtils;
	import net.johnmercer.nes.views.Emulator;
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
		/*0x00*/ instrBRK, instrORA, instrXXX, instrSLO, instrNOP, instrORA, instrASL, instrSLO, 
		         instrPHP, instrORA, instrASL, instrANC, instrNOP, instrORA, instrASL, instrSLO,
		/*0x10*/ instrBPL, instrORA, instrXXX, instrSLO, instrNOP, instrORA, instrASL, instrSLO, 
		         instrCLC, instrORA, instrNOP, instrSLO, instrNOP, instrORA, instrASL, instrSLO,
		/*0x20*/ instrJSR, instrAND, instrXXX, instrRLA, instrBIT, instrAND, instrROL, instrRLA, 
		         instrPLP, instrAND, instrROL, instrANC, instrBIT, instrAND, instrROL, instrRLA,
		/*0x30*/ instrBMI, instrAND, instrXXX, instrRLA, instrNOP, instrAND, instrROL, instrRLA, 
		         instrSEC, instrAND, instrNOP, instrRLA, instrNOP, instrAND, instrROL, instrRLA,
		/*0x40*/ instrRTI, instrEOR, instrXXX, instrSRE, instrNOP, instrEOR, instrLSR, instrSRE, 
		         instrPHA, instrEOR, instrLSR, instrASR, instrJMP, instrEOR, instrLSR, instrSRE,
		/*0x50*/ instrBVC, instrEOR, instrXXX, instrSRE, instrNOP, instrEOR, instrLSR, instrSRE, 
		         instrCLI, instrEOR, instrNOP, instrSRE, instrNOP, instrEOR, instrLSR, instrSRE,
		/*0x60*/ instrRTS, instrADC, instrXXX, instrRRA, instrNOP, instrADC, instrROR, instrRRA, 
		         instrPLA, instrADC, instrROR, instrARR, instrJMP, instrADC, instrROR, instrRRA,
		/*0x70*/ instrBVS, instrADC, instrXXX, instrRRA, instrNOP, instrADC, instrROR, instrRRA, 
		         instrSEI, instrADC, instrNOP, instrRRA, instrNOP, instrADC, instrROR, instrRRA,
		/*0x80*/ instrNOP, instrSTA, instrNOP, instrSAX, instrSTY, instrSTA, instrSTX, instrSAX, 
		         instrDEY, instrNOP, instrTXA, instrANE, instrSTY, instrSTA, instrSTX, instrSAX,
		/*0x90*/ instrBCC, instrSTA, instrXXX, instrSHA, instrSTY, instrSTA, instrSTX, instrSAX, 
		         instrTYA, instrSTA, instrTXS, instrSHS, instrSHY, instrSTA, instrSHX, instrSHA,
		/*0xA0*/ instrLDY, instrLDA, instrLDX, instrLAX, instrLDY, instrLDA, instrLDX, instrLAX, 
		         instrTAY, instrLDA, instrTAX, instrLXA, instrLDY, instrLDA, instrLDX, instrLAX,
		/*0xB0*/ instrBCS, instrLDA, instrXXX, instrLAX, instrLDY, instrLDA, instrLDX, instrLAX, 
		         instrCLV, instrLDA, instrTSX, instrLAS, instrLDY, instrLDA, instrLDX, instrLAX,
		/*0xC0*/ instrCPY, instrCMP, instrNOP, instrDCP, instrCPY, instrCMP, instrDEC, instrDCP, 
		         instrINY, instrCMP, instrDEX, instrSBX, instrCPY, instrCMP, instrDEC, instrDCP,
		/*0xD0*/ instrBNE, instrCMP, instrXXX, instrDCP, instrNOP, instrCMP, instrDEC, instrDCP, 
		         instrCLD, instrCMP, instrNOP, instrDCP, instrNOP, instrCMP, instrDEC, instrDCP,
		/*0xE0*/ instrCPX, instrSBC, instrNOP, instrISB, instrCPX, instrSBC, instrINC, instrISB, 
		         instrINX, instrSBC, instrNOP, instrSBC, instrCPX, instrSBC, instrINC, instrISB,
		/*0xF0*/ instrBEQ, instrSBC, instrXXX, instrISB, instrNOP, instrSBC, instrINC, instrISB, 
		         instrSED, instrSBC, instrNOP, instrISB, instrNOP, instrSBC, instrINC, instrISB
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
		
		// Instruction Parameters
		private var addressingMode:uint;
		private var param1:int;
		private var param2:int;
		private var paramWord:int;
		
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
			
			_currentState = new CPUState();
			
			_mem = new ByteArray();
			_mem.endian = Endian.LITTLE_ENDIAN;
			_mem.length = 0x0800;
		}
		
		public function loadRom(rom:ROM):void
		{
			_rom = rom;
		}
		
		public function get state():CPUState
		{
			return _currentState;
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
			
			param1 = int.MAX_VALUE;
			param2 = int.MAX_VALUE;
			paramWord = int.MAX_VALUE;
			
			//debugStr = hexToStr(PC,4) + "  ";
			
			//_currentState.address = PC;
			
			instruction = readUnsignedByte(PC++);
			addressingMode = INST_ADDR_MODE[instruction];
			
			//_currentState.opcode = instruction;
			
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
				case ZPY:
				case INX:
				case INY:
					param1 = readUnsignedByte(PC++);
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
			//if (paramWord < int.MAX_VALUE)
			//{
			//	param1 = paramWord & 0xff;
			//	param2 = (paramWord & 0xff00) >> 8;
			//}
			
			//_currentState.param1 = param1 == int.MAX_VALUE ? param1 : param1 & 0xFF;
			//_currentState.param2 = param2 == int.MAX_VALUE ? param2 : param2 & 0xFF;
			//_currentState.A = A;
			//_currentState.X = X;
			//_currentState.Y = Y;
			//_currentState.P = P;
			//_currentState.SP = SP;
			
			//debugStr += paramsToStr(param1, param2, paramWord, instruction, addressingMode);
			//debugStr += stateToStr();
			//_emulator.log(debugStr);
			
			// execute instruction
			// Todo: replace switch statement with function lookup table (test speed effect)
			
			_instructions[instruction]();
			
			/*
			switch(INST_NAME[instruction])
			{
				case "ADC":
					instrADC();
					break;
				case "AND":
					instrAND();
					break;
				case "ASL":
					instrASL();
					break;
				case "BCC":
					instrBCC();
					break;
				case "BCS":
					instrBCS();
					break;
				case "BEQ":
					instrBEQ();
					break;
				case "BIT":
					instrBIT();
					break;
				case "BMI":
					instrBMI();
					break;
				case "BNE":
					instrBNE();
					break;
				case "BPL":
					instrBPL();
					break;
				case "BRK":
					instrBRK();
					break;
				case "BVC":
					instrBVC();
					break;
				case "BVS":
					instrBVS();
					break;
				case "CLC":
					instrCLC();
					break;
				case "CLD":
					instrCLD();
					break;
				case "CLI":
					instrCLI();
					break;
				case "CLV":
					instrCLV();
					break;
				case "CMP":
					instrCMP();
					break;
				case "CPX":
					instrCPX();
					break;
				case "CPY":
					instrCPY();
					break;
				case "DEC":
					instrDEC();
					break;
				case "DEX":
					instrDEX();
					break;
				case "DEY":
					instrDEY();
					break;
				case "EOR":
					instrEOR();
					break;
				case "INC":
					instrINC();
					break;
				case "INX":
					instrINX();
					break;
				case "INY":
					instrINY();
					break;
				case "JMP":
					instrJMP();
					break;
				case "JSR":
					instrJSR();
					break;
				case "LDA":
					instrLDA();
					break;
				case "LDX":
					instrLDX();
					break;
				case "LDY":
					instrLDY();
					break;
				case "LSR":
					instrLSR();
					break;
				case "NOP":
					instrNOP();
					break;
				case "ORA":
					instrORA();
					break;
				case "PHA":
					instrPHA();
					break;
				case "PHP":
					instrPHP();
					break;
				case "PLA":
					instrPLA();
					break;
				case "PLP":
					instrPLP();
					break;
				case "ROL":
					instrROL();
					break;
				case "ROR":
					instrROR();
					break;
				case "RTI":
					instrRTI();
					break;
				case "RTS":
					instrRTS();
					break;
				case "SBC":
					instrSBC();
					break;
				case "SEC":
					instrSEC();
					break;
				case "SED":
					instrSED();
					break;
				case "SEI":
					instrSEI();
					break;
				case "STA":
					instrSTA();
					break;
				case "STX":
					instrSTX();
					break;
				case "STY":
					instrSTY();
					break;
				case "TAX":
					instrTAX();
					break;
				case "TAY":
					instrTAY();
					break;
				case "TSX":
					instrTSX();
					break;
				case "TXA":
					instrTXA();
					break;
				case "TXS":
					instrTXS();
					break;
				case "TYA":
					instrTYA();
					break;
				case "XXX":
					instrXXX();
					break;		
				// Undocumented Instructions
				case "DCP":
					instrDCP();
					break;
				case "ISB":
					instrISB();
					break;
				case "LAX":
					instrLAX();
					break;
				case "RLA":
					instrRLA();
					break;
				case "RRA":
					instrRRA();
					break;
				case "SAX":
					instrSAX();
					break;
				case "SLO":
					instrSLO();
					break;
				case "SRE":
					instrSRE();
					break;
				default:
					_emulator.log("Unimplemented instruction " + instruction + ":" + (INST_NAME[instruction]?INST_NAME[instruction]:"Unknown"));
					_currentState.error = true;
					break;
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
		
		private function instrADC():void
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
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF);
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
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
					value = (value + Y) & 0xFFFF;	
					value = readUnsignedByte(value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ADC");
					_currentState.error = true;
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
		
		private function instrAND():void
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
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF);
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
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
						
					value = (value + Y) & 0xFFFF;
					value = readUnsignedByte(value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: AND");
					_currentState.error = true;
					break;
			}
			
			A = A & value & 0xFF;
			
			P &= 0x7D;  // Clear Negative and Zero Flag
			
			if (A == 0)
				P |= ZERO_FLAG;
				
			if (A & 0x80)
				P |= NEGATIVE_FLAG;			
		}
		
		private function instrASL():void
		{
			var value:uint;
			switch (addressingMode)
			{
				case ACM:
					value = A << 1;
					A = value & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte() << 1;
					_mem.position = param1;
					_mem.writeByte(value & 0xFF);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte() << 1;
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(value & 0xFF);
					break;
				case ABS:
					value = readUnsignedByte(paramWord) << 1;
					writeByte(paramWord, value & 0xFF);
					break;
				case ABX:
					value = readUnsignedByte((paramWord + X) & 0xFFFF) << 1;
					writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ASL");
					_currentState.error = true;
					break;
			}
			
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (value & 0x100)
				P |= CARRY_FLAG;
				
			value &= 0xFF;
			
			if (value == 0)
				P |= ZERO_FLAG;
				
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
			
		}
		
		private function instrBCC():void
		{
			var rel:int = param1;
			if ((P & CARRY_FLAG) == 0)
			{
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBCS():void
		{
			var rel:int = param1;
			if (P & CARRY_FLAG)
			{
				PC  = (PC + REL) & 0xFFFF;
			}
		}
		
		private function instrBEQ():void
		{
			var rel:int = param1;
			if (P & ZERO_FLAG)
			{
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBIT():void
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
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: BIT");
					_currentState.error = true;
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
		
		private function instrBMI():void
		{
			var rel:int = param1;
			if (P &  NEGATIVE_FLAG)
			{
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBNE():void
		{
			var rel:int = param1;
			if ((P & ZERO_FLAG) == 0)
			{
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBPL():void
		{
			var rel:int = param1;
			if ((P & NEGATIVE_FLAG) == 0)
			{
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBRK():void
		{
			pushStack((PC & 0xFF00) >> 8);
			pushStack(PC & 0xFF);
			pushStack(P);
			PC = readUnsignedWord(0xFFFE);

			P |= BREAK_FLAG;
		}
		
		private function instrBVC():void
		{
			var rel:int = param1;
			
			if ((P & OVERFLOW_FLAG) == 0)
			{
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrBVS():void
		{
			var rel:int = param1;
			if (P & OVERFLOW_FLAG)
			{
				PC = (PC + rel) & 0xFFFF;
			}
		}
		
		private function instrCLC():void
		{
			P &=  ~CARRY_FLAG;
		}
		
		private function instrCLD():void
		{
			P &= ~DECIMAL_FLAG;
		}
		
		private function instrCLI():void
		{
			P &= ~IRQ_FLAG;
		}
		
		private function instrCLV():void
		{
			P &= ~OVERFLOW_FLAG;
		}
		
		private function instrCMP():void
		{
			var value:uint;
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
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF);
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
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
						
					value = (value + Y) & 0xFFFF;
					value = readUnsignedByte(value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CMP");
					_currentState.error = true;
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
		
		private function instrCPX():void
		{
			var value:uint;
			switch (addressingMode)
			{
				case IMM:
					value = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CPX");
					_currentState.error = true;
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
		
		private function instrCPY():void
		{
			var value:uint;
			switch (addressingMode)
			{
				case IMM:
					value = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: CPY");
					_currentState.error = true;
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
		
		private function instrDEC():void
		{
			var value:uint;
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					value = (_mem.readUnsignedByte() - 1) & 0xFF;
					_mem.position = param1;
					_mem.writeByte(value);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = (_mem.readUnsignedByte() - 1) & 0xFF;
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(value);
					break;
				case ABS:
					value = (readUnsignedByte(paramWord) - 1) & 0xFF;
					writeByte(paramWord, value);
					break;
				case ABX:
					value = (readUnsignedByte((paramWord + X) & 0xFFFF) - 1) & 0xFF;
					writeByte((paramWord + X) & 0xFFFF, value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: INC");
					_currentState.error = true;
					break;
			}
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (value == 0)			
				P |= ZERO_FLAG;
			
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrDEX():void
		{
			X = (X - 1) & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X == 0)
				P |= ZERO_FLAG;
				
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrDEY():void
		{
			Y = (Y - 1) & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (Y == 0)
				P |= ZERO_FLAG;
				
			if (Y & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrEOR():void
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
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF);
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
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
						
					value = (value + Y) & 0xFFFF;
					value = readUnsignedByte(value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ADC");
					_currentState.error = true;
					break;
			}
			A = A ^ value;
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
			
		}
		
		private function instrINC():void
		{
			var value:uint;
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					value = (_mem.readUnsignedByte() + 1) & 0xFF;
					_mem.position = param1;
					_mem.writeByte(value);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = (_mem.readUnsignedByte() + 1) & 0xFF;
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(value);
					break;
				case ABS:
					value = (readUnsignedByte(paramWord) + 1) & 0xFF;
					writeByte(paramWord, value);
					break;
				case ABX:
					value = (readUnsignedByte((paramWord + X) & 0xFFFF) + 1) & 0xFF;
					writeByte((paramWord + X) & 0xFFFF, value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: INC");
					_currentState.error = true;
					break;
			}
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (value == 0)			
				P |= ZERO_FLAG;
			
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
				
		}
		
		private function instrINX():void
		{
			X = (X + 1) & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X == 0)
				P |= ZERO_FLAG;
				
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrINY():void
		{
			Y = (Y + 1) & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (Y == 0)
				P |= ZERO_FLAG;
				
			if (Y & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrJMP():void
		{
			switch (addressingMode)
			{
				case ABS:
					PC = paramWord;
					break;
				case IND:
					// Bug when jump vector is on a page boundary
					if (paramWord & 0xFF == 0xFF)
					{
						PC = readUnsignedByte(paramWord);
						paramWord++;
						paramWord -= 0x100;
						PC |= readUnsignedByte(paramWord) << 8;
					}
					else
					{
						PC = readUnsignedWord(paramWord);
					}
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: JMP");
					_currentState.error = true;
					break;
			}
		}
		
		private function instrJSR():void
		{
			switch (addressingMode)
			{
				case ABS:
					PC--;
					pushStack((PC & 0xFF00) >> 8);
					pushStack(PC & 0xFF);
					PC = paramWord;
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: JSR");
					_currentState.error = true;
					break;
			}
		}
		
		private function instrLDA():void
		{
			var addr:uint;
			
			switch (addressingMode)
			{
				case IMM:
					A = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					A = _mem.readUnsignedByte();
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					A = _mem.readUnsignedByte();
					break;
				case ABS:
					A = readUnsignedByte(paramWord);
					break;
				case ABX:
					A = readUnsignedByte((paramWord + X) & 0xFFFF);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					A = readUnsignedByte((paramWord + Y) & 0xFFFF);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					addr = (param1 + X) & 0xFF; // Pointer to address
					if (addr == 0xFF)  // Page boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort(); // address
					}
						
					A = readUnsignedByte(addr);
					break;
				case INY:
					if (param1 == 0xFF)
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						addr = _mem.readUnsignedShort();
					}
						
					addr = (addr + Y) & 0xFFFF;
					A = readUnsignedByte(addr);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LDA");
					_currentState.error = true;
					break;
			}
			
			P &= 0x7D; // Clear Zero Flag and Negative Flag
			
			if (A == 0)
				P |= ZERO_FLAG;
				
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrLDX():void
		{
			switch (addressingMode)
			{
				case IMM:
					X = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					X = _mem.readUnsignedByte();
					break;
				case ZPY:
					_mem.position = (param1 + Y) & 0xFF;
					X = _mem.readUnsignedByte();
					break;
				case ABS:
					X = readUnsignedByte(paramWord);
					break;
				case ABY:
					X = readUnsignedByte((paramWord + Y) & 0xFFFF);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LDX");
					_currentState.error = true;
					break;
			}
			P &= 0x7D; // Clear Zero and Negative Flags
			
			if (X == 0)
				P |= ZERO_FLAG;
				
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrLDY():void
		{
			switch (addressingMode)
			{
				case IMM:
					Y = param1 & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					Y = _mem.readUnsignedByte();
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					Y = _mem.readUnsignedByte();
					break;
				case ABS:
					Y = readUnsignedByte(paramWord);
					break;
				case ABX:
					Y = readUnsignedByte((paramWord + X) & 0xFFFF);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LDY");
					_currentState.error = true;
					break;
			}
			P &= 0x7D; // Clear Zero and Negative Flags
			
			if (Y == 0)
				P |= ZERO_FLAG;
				
			if (Y & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrLSR():void
		{
			var value:uint;
			var result:uint;
			switch (addressingMode)
			{
				case ACM:
					value = A;
					result = A >> 1;
					A = result;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					result = value >> 1;
					_mem.position = param1;
					_mem.writeByte(result);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					result = value >> 1;
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(result);
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					result = value >> 1;
					writeByte(paramWord, result);
					break;
				case ABX:
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					result = value >> 1;
					writeByte((paramWord + X) & 0xFFFF, result);
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LSR");
					_currentState.error = true;
					break;
			}
			
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			if (value & 0x01)
				P |= CARRY_FLAG;
			
			if (result == 0)
				P |= ZERO_FLAG;
				
			if (result & 0x80)
				P |= NEGATIVE_FLAG;
			
		}
		
		private function instrNOP():void
		{
			return;  // No Op
			
			switch (addressingMode)
			{
				case IMP:
					// No Op
					break;
				case ZPG:  // Undocumented
					break;
				case ABS:  // Undocumented
					break;
				case ZPX:  // Undocumented
					break;
				case IMM:  // Undocumented
					break;
				case ABX:  // Undocumented
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: NOP");
					_currentState.error = true;
					break;
			}
		}
		
		private function instrORA():void
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
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF);
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
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
						
					value = (value + Y) & 0xFFFF;
					value = readUnsignedByte(value);
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ORA");
					_currentState.error = true;
					break;
			}
			A = A | value;
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrPHA():void
		{
			pushStack(A);
		}
		
		private function instrPHP():void
		{
			pushStack(P | BREAK_FLAG);  // Break flag is always pushed with a 1
		}
		
		private function instrPLA():void
		{
			A = popStack();
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrPLP():void
		{
			P = (popStack() & ~BREAK_FLAG) | UNUSED_FLAG;
		}
		
		private function instrROL():void
		{
			var value:uint;
			switch (addressingMode)
			{
				case ACM:
					value = A;
					value = (A << 1) | (P & CARRY_FLAG);
					A = value & 0xFF;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					value = (value << 1) | (P & CARRY_FLAG);
					_mem.position = param1;
					_mem.writeByte(value & 0xFF);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					value = (value << 1) | (P & CARRY_FLAG);
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(value & 0xFF);
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					value = (value << 1) | (P & CARRY_FLAG);
					writeByte(paramWord, value & 0xFF);
					break;
				case ABX:
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					value = (value << 1) | (P & CARRY_FLAG);
					writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ROL");
					_currentState.error = true;
					break;
			}
			
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			if (value & 0x100)
				P |= CARRY_FLAG;
			
			value &= 0xFF;
			
			if (value == 0)
				P |= ZERO_FLAG;
				
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrROR():void
		{
			var value:uint;
			var result:uint;
			switch (addressingMode)
			{
				case ACM:
					value = A;
					result = A >> 1 | ((P & CARRY_FLAG) << 7);
					A = result;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					result = value >> 1 | ((P & CARRY_FLAG) << 7);
					_mem.position = param1;
					_mem.writeByte(result);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					result = value >> 1 | ((P & CARRY_FLAG) << 7);
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(result);
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					result = value >> 1 | ((P & CARRY_FLAG) << 7);
					writeByte(paramWord, result);
					break;
				case ABX:
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					result = value >> 1 | ((P & CARRY_FLAG) << 7);
					writeByte((paramWord + X) & 0xFFFF, result);
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ROR");
					_currentState.error = true;
					break;
			}
			
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			if (value & 0x01)
				P |= CARRY_FLAG;
			
			if (result == 0)
				P |= ZERO_FLAG;
				
			if (result & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrRTI():void
		{
			P = (popStack() & ~BREAK_FLAG) | UNUSED_FLAG;
			PC = popStack();
			PC |= popStack() << 8;
		}
		
		private function instrRTS():void
		{
			PC = popStack();
			PC |= (popStack() << 8);
			PC++;
		}
		
		private function instrSBC():void
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
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF);
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
						value = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						value = _mem.readUnsignedShort();
					}
						
					value = (value + Y) & 0xFFFF;
					value = readUnsignedByte(value);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SBC");
					_currentState.error = true;
					break;
			}
			// A,Z,C,N = A-M-(1-C)
			result = A - value;
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
		
		private function instrSED():void
		{
			P |= DECIMAL_FLAG;
		}
		
		private function instrSEC():void
		{
			P |= CARRY_FLAG;
		}
		
		private function instrSEI():void
		{
			P |= IRQ_FLAG;
		}
		
		private function instrSTA():void
		{
			var addr:uint;
			
			switch (addressingMode)
			{				
				case ZPG:
					_mem.position = param1;
					_mem.writeByte(A);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(A);
					break;
				case ABS:
					writeByte(paramWord, A);
					break;
				case ABX:
					writeByte((paramWord + X) & 0xFFFF, A);
					break;
				case ABY:
					writeByte((paramWord + Y) & 0xFFFF, A);
					break;
				case INX:
					addr = (param1 + X) & 0xFF;
					if (addr == 0xFF) // Page Boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort();
					}
					writeByte(addr, A);
					break;
				case INY:
					if (param1 == 0xFF)  // Page Boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						addr = _mem.readUnsignedShort();
					}
					addr = (addr + Y) & 0xFFFF;
					writeByte(addr, A);
					break;
					
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: STA");
					_currentState.error = true;
					break;
			}
		}
		
		private function instrSTX():void
		{			
			switch (addressingMode)
			{				
				case ZPG:
					_mem.position = param1;
					_mem.writeByte(X);
					break;
				case ZPY:
					_mem.position = (param1 + Y) & 0xFF;
					_mem.writeByte(X);
					break;
				case ABS:
					writeByte(paramWord, X);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: STX");
					_currentState.error = true;
					break;
			}
		}
		
		private function instrSTY():void
		{
			switch (addressingMode)
			{		
				case ZPG:
					_mem.position = param1;
					_mem.writeByte(Y);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(Y);
					break;
				case ABS:
					writeByte(paramWord, Y);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: STY");
					_currentState.error = true;
					break;
			}
		}
		
		private function instrTAX():void
		{
			X = A;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X == 0)
				P |= ZERO_FLAG;
				
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrTAY():void
		{
			Y = A;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (Y == 0)
				P |= ZERO_FLAG;
				
			if (Y & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrTSX():void
		{
			X = SP;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (X == 0)
				P |= ZERO_FLAG;
				
			if (X & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrTXA():void
		{
			A = X;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (A == 0)
				P |= ZERO_FLAG;
				
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrTXS():void
		{
			SP = X;
		}
		
		private function instrTYA():void
		{
			A = Y;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (A == 0)
				P |= ZERO_FLAG;
				
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
		}
		
		private function instrXXX():void
		{
			_emulator.log("Invalid Opcode read, halting");
			_currentState.error = true;
		}
		
		// Undocumented Instructions
		
		private function instrANC():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ANC");
			_currentState.error = true;
		}
		
		private function instrANE():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ANE");
			_currentState.error = true;
		}
		
		private function instrARR():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ARR");
			_currentState.error = true;
		}
		
		private function instrASR():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ASR");
			_currentState.error = true;
		}
		
		private function instrDCP():void
		{
			var addr:uint;
			var value:int;
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					value = (_mem.readByte() - 1);
					_mem.position = param1;
					_mem.writeByte(value & 0xFF);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = (_mem.readByte() - 1);
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(value & 0xFF);
					break;
				case ZPY:
					_mem.position = (param1 + Y) & 0xFF;
					value = (_mem.readByte() - 1);
					_mem.position = (param1 + Y) & 0xFF;
					_mem.writeByte(value & 0xFF);
					break;
				case ABS:
					value = (readByte(paramWord) - 1);
					writeByte(paramWord, value & 0xFF);
					break;
				case ABX:
					value = (readByte((paramWord + X) & 0xFFFF) - 1);
					writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
					// Calculate cycle by checking paramWord + X & 0xFF < paramWord & 0xFF(or param1?)
					break;
				case ABY:
					value = (readByte((paramWord + Y) & 0xFFFF) - 1);
					writeByte((paramWord + Y) & 0xFFFF, value & 0xFF);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					addr = (param1 + X) & 0xFF; // Pointer to address
					if (addr == 0xFF)  // Page boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort(); // address
					}
						
					value = (readByte(addr) - 1);
					writeByte(addr, value & 0xFF);
					break;
				case INY:
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
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: DCP");
					_currentState.error = true;
					break;
			}
			/*
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG);
			
			if (value == 0)			
				P |= ZERO_FLAG;
			
			if (value & 0x80)
				P |= NEGATIVE_FLAG;
			*/
				
			P &= ~(CARRY_FLAG | ZERO_FLAG | NEGATIVE_FLAG);
			
			if (A >= (value & 0xFF))
				P |= CARRY_FLAG;
			
			if (A == (value & 0xFF))
				P |= ZERO_FLAG;
				
			if ((A - value) & 0x80)
				P |= NEGATIVE_FLAG;
			
		}
		
		private function instrISB():void
		{
			var addr:uint;
			var value:uint;
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					value = (_mem.readUnsignedByte() + 1) & 0xFF;
					_mem.position = param1;
					_mem.writeByte(value);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = (_mem.readUnsignedByte() + 1) & 0xFF;
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(value);
					break;
				case ABS:
					value = (readUnsignedByte(paramWord) + 1) & 0xFF;
					writeByte(paramWord, value);
					break;
				case ABX:
					value = (readUnsignedByte((paramWord + X) & 0xFFFF) + 1) & 0xFF;
					writeByte((paramWord + X) & 0xFFFF, value);
					break;
				case ABY:
					value = (readUnsignedByte((paramWord + Y) & 0xFFFF) + 1) & 0xFF;
					writeByte((paramWord + Y) & 0xFFFF, value);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					addr = (param1 + X) & 0xFF; // Pointer to address
					if (addr == 0xFF)  // Page boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort(); // address
					}
						
					value = (readByte(addr) + 1) & 0xFF;
					writeByte(addr, value);
					break;
				case INY:
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
					break;
					
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ISB");
					_currentState.error = true;
					break;
			}
			
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
		
		private function instrLAS():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LAS");
			_currentState.error = true;
		}
		
		private function instrLAX():void
		{
			var addr:uint;
			
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					A = _mem.readUnsignedByte();
					break;
				case ZPY:
					_mem.position = (param1 + Y) & 0xFF;
					A = _mem.readUnsignedByte();
					break;
				case ABS:
					A = readUnsignedByte(paramWord);
					break;
				case ABY:
					A = readUnsignedByte((paramWord + Y) & 0xFFFF);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					addr = (param1 + X) & 0xFF; // Pointer to address
					if (addr == 0xFF)  // Page boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort(); // address
					}
						
					A = readUnsignedByte(addr);
					break;
				case INY:
					if (param1 == 0xFF)
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = param1;
						addr = _mem.readUnsignedShort();
					}
						
					addr = (addr + Y) & 0xFFFF;
					A = readUnsignedByte(addr);
					break;
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LAX");
					_currentState.error = true;
					break;
			}
			
			P &= 0x7D; // Clear Zero Flag and Negative Flag
			
			if (A == 0)
				P |= ZERO_FLAG;
				
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
			
			// Update X to complete undocumented behavior
			X = A;
		}
		
		private function instrLXA():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: LXA");
			_currentState.error = true;
		}
		
		private function instrRLA():void
		{
			var addr:uint;
			var value:uint;
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					value = (value << 1) | (P & CARRY_FLAG);
					_mem.position = param1;
					_mem.writeByte(value & 0xFF);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					value = (value << 1) | (P & CARRY_FLAG);
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(value & 0xFF);
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					value = (value << 1) | (P & CARRY_FLAG);
					writeByte(paramWord, value & 0xFF);
					break;
				case ABX:
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					value = (value << 1) | (P & CARRY_FLAG);
					writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF);
					value = (value << 1) | (P & CARRY_FLAG);
					writeByte((paramWord + Y) & 0xFFFF, value & 0xFF);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					addr = (param1 + X) & 0xFF; // Pointer to address
					if (addr == 0xFF)  // Page boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort(); // address
					}
						
					value = readUnsignedByte(addr);
					value = (value << 1) | (P & CARRY_FLAG);
					writeByte(addr, value & 0xFF);
					break;
				case INY:
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
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: RLA");
					_currentState.error = true;
					break;
			}

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
		
		private function instrRRA():void
		{
			var addr:uint;
			var value:uint;
			var result:uint;
			switch (addressingMode)
			{
				case ACM:
					value = A;
					result = A >> 1 | ((P & CARRY_FLAG) << 7);
					A = result;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					result = value >> 1 | ((P & CARRY_FLAG) << 7);
					_mem.position = param1;
					_mem.writeByte(result);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					result = value >> 1 | ((P & CARRY_FLAG) << 7);
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(result);
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					result = value >> 1 | ((P & CARRY_FLAG) << 7);
					writeByte(paramWord, result);
					break;
				case ABX:
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					result = value >> 1 | ((P & CARRY_FLAG) << 7);
					writeByte((paramWord + X) & 0xFFFF, result);
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF);
					result = value >> 1 | ((P & CARRY_FLAG) << 7);
					writeByte((paramWord + Y) & 0xFFFF, result);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					addr = (param1 + X) & 0xFF; // Pointer to address
					if (addr == 0xFF)  // Page boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort(); // address
					}
						
					value = readUnsignedByte(addr);
					result = (value >> 1) | ((P & CARRY_FLAG) << 7);
					writeByte(addr, result);
					break;
				case INY:
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
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ROR");
					_currentState.error = true;
					break;
			}
			
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
		
		private function instrSAX():void
		{
			var addr:uint;
			
			switch (addressingMode)
			{				
				case ZPG:
					_mem.position = param1;
					_mem.writeByte(A & X);
					break;
				case ZPY:
					_mem.position = (param1 + Y) & 0xFF;
					_mem.writeByte(A & X);
					break;
				case ABS:
					writeByte(paramWord, A & X);
					break;
				case INX:
					addr = (param1 + X) & 0xFF;
					if (addr == 0xFF) // Page Boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort();
					}
					writeByte(addr, A & X);
					break;	
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SAX");
					_currentState.error = true;
					break;
			}
		}
		
		private function instrSBX():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SBX");
			_currentState.error = true;
		}
		
		private function instrSHA():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SHA");
			_currentState.error = true;
		}
		
		private function instrSHS():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SHS");
			_currentState.error = true;
		}
		
		private function instrSHY():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SHY");
			_currentState.error = true;
		}
		
		private function instrSHX():void
		{
			_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SHX");
			_currentState.error = true;
		}
		
		private function instrSLO():void
		{
			var addr:uint;
			var value:uint;
			switch (addressingMode)
			{
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte() << 1;
					_mem.position = param1;
					_mem.writeByte(value & 0xFF);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte() << 1;
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(value & 0xFF);
					break;
				case ABS:
					value = readUnsignedByte(paramWord) << 1;
					writeByte(paramWord, value & 0xFF);
					break;
				case ABX:
					value = readUnsignedByte((paramWord + X) & 0xFFFF) << 1;
					writeByte((paramWord + X) & 0xFFFF, value & 0xFF);
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF) << 1;
					writeByte((paramWord + Y) & 0xFFFF, value & 0xFF);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					addr = (param1 + X) & 0xFF; // Pointer to address
					if (addr == 0xFF)  // Page boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort(); // address
					}
						
					value = readUnsignedByte(addr) << 1;
					writeByte(addr, value & 0xFF);
					break;
				case INY:
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
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: ASL");
					_currentState.error = true;
					break;
			}
			
			A = A | value & 0xFF;
			
			P &= ~(ZERO_FLAG | NEGATIVE_FLAG | CARRY_FLAG);
			if (A == 0)
				P |= ZERO_FLAG;
			if (A & 0x80)
				P |= NEGATIVE_FLAG;
			if (value & 0x100)
				P |= CARRY_FLAG;

		}
		
		private function instrSRE():void
		{
			var addr:uint;
			var value:uint;
			var result:uint;
			switch (addressingMode)
			{
				case ACM:
					value = A;
					result = A >> 1;
					A = result;
					break;
				case ZPG:
					_mem.position = param1;
					value = _mem.readUnsignedByte();
					result = value >> 1;
					_mem.position = param1;
					_mem.writeByte(result);
					break;
				case ZPX:
					_mem.position = (param1 + X) & 0xFF;
					value = _mem.readUnsignedByte();
					result = value >> 1;
					_mem.position = (param1 + X) & 0xFF;
					_mem.writeByte(result);
					break;
				case ABS:
					value = readUnsignedByte(paramWord);
					result = value >> 1;
					writeByte(paramWord, result);
					break;
				case ABX:
					value = readUnsignedByte((paramWord + X) & 0xFFFF);
					result = value >> 1;
					writeByte((paramWord + X) & 0xFFFF, result);
					break;
				case ABY:
					value = readUnsignedByte((paramWord + Y) & 0xFFFF);
					result = value >> 1;
					writeByte((paramWord + Y) & 0xFFFF, result);
					break;
				case INX:
					// Address to read value from is at (param1 + X) & 0xFF
					addr = (param1 + X) & 0xFF; // Pointer to address
					if (addr == 0xFF)  // Page boundary
						addr = readUnsignedByte(0xFF) | (readUnsignedByte(0) << 8);
					else
					{
						_mem.position = addr;
						addr = _mem.readUnsignedShort(); // address
					}
						
					value = readUnsignedByte(addr);
					result = value >> 1;
					writeByte(addr, result);
					break;
				case INY:
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
					break;
				
				default:
					_emulator.log("Invalid addressing mode " + ADDR_NAME[addressingMode] + " for Instruction: SRE");
					_currentState.error = true;
					break;
			}
			
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
					str += "REL $" + StringUtils.hexToStr((PC + p1) & 0x1FFFF,4);
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