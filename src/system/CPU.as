package system 
{
	import tests.CPUState;
	/**
	 * ...
	 * @author John
	 */
	public class CPU 
	{
		public static const IRQ_NORMAL:uint = 0;
		public static const IRQ_NMI:uint = 1;
		public static const IRQ_RESET:uint = 2;
		
		// Flags for status update
		public static const CARRY_FLAG:uint    = 0x01;
		public static const ZERO_FLAG:uint     = 0x02;
		public static const IRQ_FLAG:uint      = 0x04;
		public static const DECIMAL_FLAG:uint  = 0x08;  // Unused
		public static const BREAK_FLAG:uint    = 0x10;
		public static const UNUSED_FLAG:uint   = 0x20;
		public static const OVERFLOW_FLAG:uint = 0x40;
		public static const NEGATIVE_FLAG:uint = 0x80;
		
		private var nes:NES;
		
		private var _reg_acc:uint;
		private var _reg_x:uint;
		private var _reg_y:uint;
		private var _reg_sp:uint;
		private var _reg_pc:uint;
		private var _reg_pc_new:uint;
		private var _reg_status:uint;
		
		private var _f_carry:uint;
		private var _f_decimal:uint;
		private var _f_interrupt:uint;
		private var _f_interrupt_new:uint;
		private var _f_overflow:uint;
		private var _f_sign:uint;
		private var _f_zero:uint;
		private var _f_notused:uint;
		private var _f_notused_new:uint;
		private var _f_brk:uint;
		private var _f_brk_new:uint;
		
		private var _opdata:Vector.<uint>;
		private var _instructions:Vector.<Function>;
		public var cyclesToHalt:uint;
		private var _crash:Boolean
		private var _irqRequested:Boolean;
		private var _irqType:uint;
		
		public var cpuState:CPUState;
		
		public var mem:Vector.<uint>;
		public var loadHandlers:Vector.<int>;
		public var writeHandlers:Vector.<int>;
		private var _handlerJumpTable:Vector.<Function>;
		
		public function CPU(nes:NES) 
		{
			//cpuState = new //cpuState();
			this.nes = nes;
			reset();
		}
		
		public function registerHandler(handler:Function):int
		{
			var index:int = _handlerJumpTable.length;
			_handlerJumpTable[index] = handler;
			return index;
		}
		
		public function resetHandlers():void
		{
			loadHandlers = new Vector.<int>(0x10000);
			writeHandlers = new Vector.<int>(0x10000);
			_handlerJumpTable = new <Function>[null];
		}
		
		private function generateInstJumpTable():void
		{
			_instructions = new Vector.<Function>();
			if (OpData.instname == null) { return; }
			
			_instructions.length = 0xFF;
			for (var i:int = 0; i < OpData.instname.length; i++)
			{
				_instructions[i] = this["instr" + OpData.instname[i]] as Function;
			}
			_instructions[0xFF] = instrXXX;
		}
		
		public function reset(startAddr:uint = 0x8000):void
		{
			var i:uint;
			
			// Main memory
			mem = new Vector.<uint>(0x10000);

			for (i = 0; i < 0x2000; i++)
			{
				mem[i] = 0xFF;
			}
			
			for (var p:uint = 0; p < 4; p++)
			{
				i = p * 0x800;
				mem[i + 0x008] = 0xF7;
				mem[i + 0x009] = 0xEF;
				mem[i + 0x00A] = 0xDF;
				mem[i + 0x00F] = 0xBF;
			}
			for (i = 0x2001; i < mem.length; i++)
			{
				mem[i] = 0;
			}
			
			// CPU Registers
			_reg_acc = _reg_x = _reg_y = 0;
			// Reset stack pointer
			_reg_sp = 0x01FD;
			// Reset program counter
			_reg_pc = _reg_pc_new = startAddr - 1;
			// Reset status register
			_reg_status = 0x28;
			
			setStatus(0x28);
			
			// Set flags:
			_f_carry = _f_decimal = _f_overflow = _f_sign = 0;
			_f_interrupt = _f_interrupt_new = _f_zero = 1;
			_f_notused = _f_notused_new = _f_brk = _f_brk_new = 1;
			
			_opdata = (new OpData()).opdata;
			generateInstJumpTable();
			cyclesToHalt = 0;
			
			// Reset crash flag
			_crash = false;
			
			// Interrupt Notifcation
			_irqRequested = false;
			_irqType = 0;
		}
		
		public function setAddress(addr:uint):void
		{
			_reg_pc_new = _reg_pc = (addr - 1) & 0xFFFF;
			_irqRequested = false;
			
			setStatus(0x24);
		}
		
		public function emulate():uint
		{
			var temp:int;
			var add:uint;
			
			// Check interrupts:
			if(_irqRequested){
				temp =
					(_f_carry)|
					((_f_zero===0?1:0)<<1)|
					(_f_interrupt<<2)|
					(_f_decimal<<3)|
					0|//(f_brk<<4)|  - Brk flag is pushed as 0
					(_f_notused<<5)|
					(_f_overflow<<6)|
					(_f_sign<<7);

				_reg_pc_new = _reg_pc;
				_f_interrupt_new = _f_interrupt;
				switch(_irqType){
					case 0: {
						// Normal IRQ:
						if(_f_interrupt!=0){
							trace("Interrupt was masked.");
							break;
						}
						doIrq(temp);
						trace("Did normal IRQ. I="+_f_interrupt);
						break;
					}case 1:{
						// NMI:
						doNonMaskableInterrupt(temp);
						break;

					}case 2:{
						// Reset:
						doResetInterrupt();
						break;
					}
				}

				_reg_pc = _reg_pc_new;
				_f_interrupt = _f_interrupt_new;
				_f_brk = _f_brk_new;
				_irqRequested = false;
			}

			var opCode:uint = load(_reg_pc + 1);
			var opinf:uint = _opdata[opCode];
			var cycleCount:uint = (opinf>>24);
			var cycleAdd:uint = 0;
			
			
			// Find address mode:
			var addrMode:uint = (opinf >> 8) & 0xFF;

			// Increment PC by number of op bytes:
			var opaddr:uint = _reg_pc;
			_reg_pc += ((opinf >> 16) & 0xFF);
			
			
			//cpuState.address = opaddr + 1;
			//cpuState.opcode = opCode;
			//cpuState.param1 = int.MAX_VALUE;
			//cpuState.param2 = int.MAX_VALUE;
			//cpuState.P = getStatus();
			//cpuState.A = _reg_acc;
			//cpuState.X = _reg_x;
			//cpuState.Y = _reg_y;
			//cpuState.SP = _reg_sp & 0xFF;
			
			
			var addr:uint = 0;
			var addrHi:uint = 0;
			var param1:uint = int.MAX_VALUE;
			var param2:uint = int.MAX_VALUE;
			switch(addrMode){
				case 0:{
					// Zero Page mode. Use the address given after the opcode, 
					// but without high byte.
					addr = load(opaddr + 2);
					//cpuState.param1 = addr;
					break;

				}case 1:{
					// Relative mode.
					addr = load(opaddr+2);
					//cpuState.param1 = addr;
					if(addr<0x80){
						addr += _reg_pc;
					}else{
						addr += _reg_pc-256;
					}
					break;
				}case 2:{
					// Ignore. Address is implied in instruction.
					break;
				}case 3:{
					// Absolute mode. Use the two bytes following the opcode as 
					// an address.
					addr = load16bit(opaddr + 2);
					//cpuState.param1 = addr & 0xFF;
					//cpuState.param2 = (addr >> 8) & 0xFF;
					break;
				}case 4:{
					// Accumulator mode. The address is in the accumulator 
					// register.
					addr = _reg_acc;
					break;
				}case 5:{
					// Immediate mode. The value is given after the opcode.
					addr = _reg_pc;
					//cpuState.param1 = load(_reg_pc);
					break;
				}case 6:{
					// Zero Page Indexed mode, X as index. Use the address given 
					// after the opcode, then add the
					// X register to it to get the final address.
					param1 = load(opaddr + 2);
					//cpuState.param1 = param1;
					addr = (param1 + _reg_x) & 0xFF;
					break;
				}case 7:{
					// Zero Page Indexed mode, Y as index. Use the address given 
					// after the opcode, then add the
					// Y register to it to get the final address.
					param1 = load(opaddr + 2);
					//cpuState.param1 = param1;
					addr = (param1 + _reg_y) & 0xFF;
					break;
				}case 8:{
					// Absolute Indexed Mode, X as index. Same as zero page 
					// indexed, but with the high byte.
					addr = load16bit(opaddr + 2);
					//cpuState.param1 = addr & 0xff;
					//cpuState.param2 = (addr >> 8) & 0xff;
					if((addr&0xFF00)!=((addr+_reg_x)&0xFF00)){
						cycleAdd = 1;
					}
					addr+=_reg_x;
					break;
				}case 9:{
					// Absolute Indexed Mode, Y as index. Same as zero page 
					// indexed, but with the high byte.
					addr = load16bit(opaddr+2);
					//cpuState.param1 = addr & 0xff;
					//cpuState.param2 = (addr >> 8) & 0xff;
					if((addr&0xFF00)!=((addr+_reg_y)&0xFF00)){
						cycleAdd = 1;
					}
					addr+=_reg_y;
					break;
				}case 10:{
					// Pre-indexed Indirect mode. Find the 16-bit address 
					// starting at the given location plus
					// the current X register. The value is the contents of that 
					// address.
					addr = load(opaddr+2);
					//cpuState.param1 = addr & 0xff;
					if((addr&0xFF00)!=((addr+_reg_x)&0xFF00)){
						cycleAdd = 1;
					}
					addr+=_reg_x;
					addr&=0xFF;
					addrHi = (addr + 1) & 0xFF;
					addr = load(addr);
					addr |= load(addrHi) << 8;
					break;
				}case 11:{
					// Post-indexed Indirect mode. Find the 16-bit address 
					// contained in the given location
					// (and the one following). Add to that address the contents 
					// of the Y register. Fetch the value
					// stored at that adress.
					addr = load(opaddr + 2);
					//cpuState.param1 = addr;
					addrHi = (addr + 1) & 0xFF;
					addr = load(addr);
					addr |= load(addrHi) << 8;
					
					if((addr&0xFF00)!=((addr+_reg_y)&0xFF00)){
						cycleAdd = 1;
					}
					addr += _reg_y;
					break;
				}case 12:{
					// Indirect Absolute mode. Find the 16-bit address contained 
					// at the given location.
					addr = load16bit(opaddr + 2);// Find op					
					//cpuState.param1 = addr & 0xff;
					//cpuState.param2 = (addr >> 8) & 0xff;

					if(addr < 0x1FFF) {
						addr = mem[addr] + (mem[(addr & 0xFF00) | (((addr & 0xFF) + 1) & 0xFF)] << 8);// Read from address given in op
					}
					else{
						addr = load(addr) + (load((addr & 0xFF00) | (((addr & 0xFF) + 1) & 0xFF)) << 8);
					}
					break;

				}

			}
			// Wrap around for addresses above 0xFFFF:
			addr&=0xFFFF;

			// ----------------------------------------------------------------------------------------------------
			// Decode & execute instruction:
			// ----------------------------------------------------------------------------------------------------
			//cycleCount = _instructions[opinf & 0xFF].apply(null, [opaddr, addr, addrMode, cycleCount, cycleAdd]);
			cycleCount = _instructions[opinf & 0xFF](opaddr, addr, addrMode, cycleCount, cycleAdd);
			
			//cpuState.CYC = cycleCount;

			return cycleCount;
		}
		
		private function instrADC(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * ADC * - case 0
			// *******
			var temp:int;
			// Add with carry.
			temp = _reg_acc + load(addr) + _f_carry;
			_f_overflow = ((!(((_reg_acc ^ load(addr)) & 0x80)!=0) && (((_reg_acc ^ temp) & 0x80))!=0)?1:0);
			_f_carry = (temp>255?1:0);
			_f_sign = (temp>>7)&1;
			_f_zero = temp&0xFF;
			_reg_acc = (temp&255);
			cycleCount += cycleAdd;
			
			return cycleCount;
		}
		
		private function instrAND(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * AND * - case 1
			// *******

			// AND memory with accumulator.
			_reg_acc = _reg_acc & load(addr);
			_f_sign = (_reg_acc>>7)&1;
			_f_zero = _reg_acc;
			//reg_acc = temp;
			if (addrMode != 11) cycleCount += cycleAdd; // PostIdxInd = 11
			
			return cycleCount;
		}
		
		private function instrASL(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * ASL * - case 2
			// *******
			var temp:int;
			
			// Shift left one bit
			if(addrMode == 4){ // ADDR_ACC = 4

				_f_carry = (_reg_acc>>7)&1;
				_reg_acc = (_reg_acc<<1)&255;
				_f_sign = (_reg_acc>>7)&1;
				_f_zero = _reg_acc;

			}else{

				temp = load(addr);
				_f_carry = (temp>>7)&1;
				temp = (temp<<1)&255;
				_f_sign = (temp>>7)&1;
				_f_zero = temp;
				write(addr, temp);

			}
			return cycleCount;
		}
		
		private function instrBCC(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * BCC * - case 3
			// *******

			// Branch on carry clear
			if(_f_carry == 0){
				cycleCount += ((opaddr&0xFF00)!=(addr&0xFF00)?2:1);
				_reg_pc = addr;
			}
			return cycleCount;
		}
		
		private function instrBCS(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{

			// *******
			// * BCS * - case 4
			// *******

			// Branch on carry set
			if(_f_carry == 1){
				cycleCount += ((opaddr&0xFF00)!=(addr&0xFF00)?2:1);
				_reg_pc = addr;
			}
			return cycleCount;
		}
		
		private function instrBEQ(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * BEQ * - case 5
			// *******

			// Branch on zero
			if(_f_zero == 0){
				cycleCount += ((opaddr&0xFF00)!=(addr&0xFF00)?2:1);
				_reg_pc = addr;
			}
			return cycleCount;
		}
		
		private function instrBIT(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * BIT *
			// *******
			var temp:int;
			temp = load(addr);
			_f_sign = (temp>>7)&1;
			_f_overflow = (temp>>6)&1;
			temp &= _reg_acc;
			_f_zero = temp;
			return cycleCount;
		}
		
		private function instrBMI(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * BMI *
			// *******

			// Branch on negative result
			if(_f_sign == 1){
				cycleCount++;
				_reg_pc = addr;
			}
			return cycleCount;
		}
		
		private function instrBNE(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * BNE *
			// *******

			// Branch on not zero
			if(_f_zero != 0){
				cycleCount += ((opaddr&0xFF00)!=(addr&0xFF00)?2:1);
				_reg_pc = addr;
			}
			return cycleCount;
		}
		
		private function instrBPL(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * BPL *
			// *******

			// Branch on positive result
			if(_f_sign == 0){
				cycleCount += ((opaddr&0xFF00)!=(addr&0xFF00)?2:1);
				_reg_pc = addr;
			}
			return cycleCount;
		}
		
		private function instrBRK(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * BRK *
			// *******

			_reg_pc+=2;
			push((_reg_pc>>8)&255);
			push(_reg_pc&255);
			_f_brk = 1;	

			push(
				(_f_carry)|
				((_f_zero==0?1:0)<<1)|
				(_f_interrupt<<2)|
				(_f_decimal<<3)|
				(_f_brk<<4)|
				(_f_notused<<5)|
				(_f_overflow<<6)|
				(_f_sign<<7)
			);

			_f_interrupt = 1;
			//reg_pc = load(0xFFFE) | (load(0xFFFF) << 8);
			_reg_pc = load16bit(0xFFFE);
			_reg_pc--;
			return cycleCount;
		}
		
		private function instrBVC(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * BVC *
			// *******

			// Branch on overflow clear
			if(_f_overflow == 0){
				cycleCount += ((opaddr&0xFF00)!=(addr&0xFF00)?2:1);
				_reg_pc = addr;
			}
			return cycleCount;
		}
		
		private function instrBVS(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * BVS *
			// *******

			// Branch on overflow set
			if(_f_overflow == 1){
				cycleCount += ((opaddr&0xFF00)!=(addr&0xFF00)?2:1);
				_reg_pc = addr;
			}
			return cycleCount;
		}
		
		private function instrCLC(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * CLC *
			// *******

			// Clear carry flag
			_f_carry = 0;
			return cycleCount;
		}
		
		private function instrCLD(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * CLD *
			// *******

			// Clear decimal flag
			_f_decimal = 0;
			return cycleCount;
		}
		
		private function instrCLI(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * CLI *
			// *******

			// Clear interrupt flag
			_f_interrupt = 0;
			return cycleCount;
		}
		
		private function instrCLV(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * CLV *
			// *******

			// Clear overflow flag
			_f_overflow = 0;
			return cycleCount;
		}
		
		private function instrCMP(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * CMP *
			// *******
			var temp:int;
			// Compare memory and accumulator:
			temp = _reg_acc - load(addr);
			_f_carry = (temp>=0?1:0);
			_f_sign = (temp>>7)&1;
			_f_zero = temp&0xFF;
			cycleCount += cycleAdd;
			return cycleCount;
		}
		
		private function instrCPX(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * CPX *
			// *******
			var temp:int;
			// Compare memory and index X:
			temp = _reg_x - load(addr);
			_f_carry = (temp>=0?1:0);
			_f_sign = (temp>>7)&1;
			_f_zero = temp & 0xFF;
			return cycleCount;
		}
		
		private function instrCPY(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * CPY * - case 19
			// *******
			var temp:int;
			// Compare memory and index Y:
			temp = _reg_y - load(addr);
			_f_carry = (temp>=0?1:0);
			_f_sign = (temp>>7)&1;
			_f_zero = temp&0xFF;
			return cycleCount;
		}
		
		private function instrDEC(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * DEC * - case 20
			// *******
			var temp:int;
			// Decrement memory by one:
			temp = (load(addr)-1)&0xFF;
			_f_sign = (temp>>7)&1;
			_f_zero = temp;
			write(addr, temp);
			return cycleCount;
		}
		
		private function instrDEX(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * DEX *
			// *******

			// Decrement index X by one:
			_reg_x = (_reg_x-1)&0xFF;
			_f_sign = (_reg_x>>7)&1;
			_f_zero = _reg_x;
			return cycleCount;
		}
		
		private function instrDEY(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * DEY *
			// *******

			// Decrement index Y by one:
			_reg_y = (_reg_y-1)&0xFF;
			_f_sign = (_reg_y>>7)&1;
			_f_zero = _reg_y;
			return cycleCount;
		}
		
		private function instrEOR(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * EOR *
			// *******

			// XOR Memory with accumulator, store in accumulator:
			_reg_acc = (load(addr)^_reg_acc)&0xFF;
			_f_sign = (_reg_acc>>7)&1;
			_f_zero = _reg_acc;
			cycleCount+=cycleAdd;
			return cycleCount;
		}
		
		private function instrINC(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * INC *
			// *******
			var temp:int;
			// Increment memory by one:
			temp = (load(addr)+1)&0xFF;
			_f_sign = (temp>>7)&1;
			_f_zero = temp;
			write(addr, temp&0xFF);
			return cycleCount;
		}
		
		private function instrINX(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * INX *
			// *******

			// Increment index X by one:
			_reg_x = (_reg_x+1)&0xFF;
			_f_sign = (_reg_x>>7)&1;
			_f_zero = _reg_x;
			return cycleCount;
		}
		
		private function instrINY(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * INY *
			// *******

			// Increment index Y by one:
			_reg_y++;
			_reg_y &= 0xFF;
			_f_sign = (_reg_y>>7)&1;
			_f_zero = _reg_y;
			return cycleCount;
		}
		
		private function instrJMP(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * JMP *
			// *******

			// Jump to new location:
			_reg_pc = addr-1;
			return cycleCount;
		}
		
		private function instrJSR(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * JSR *
			// *******

			// Jump to new location, saving return address.
			// Push return address on stack:
			push((_reg_pc>>8)&255);
			push(_reg_pc&255);
			_reg_pc = addr-1;
			return cycleCount;
		}
		
		private function instrLDA(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * LDA *
			// *******

			// Load accumulator with memory:
			_reg_acc = load(addr);
			_f_sign = (_reg_acc>>7)&1;
			_f_zero = _reg_acc;
			cycleCount+=cycleAdd;
			return cycleCount;
		}
		
		private function instrLDX(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * LDX *
			// *******

			// Load index X with memory:
			_reg_x = load(addr);
			_f_sign = (_reg_x>>7)&1;
			_f_zero = _reg_x;
			cycleCount+=cycleAdd;
			return cycleCount;
		}
		
		private function instrLDY(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * LDY *
			// *******

			// Load index Y with memory:
			_reg_y = load(addr);
			_f_sign = (_reg_y>>7)&1;
			_f_zero = _reg_y;
			cycleCount+=cycleAdd;
			return cycleCount;
		}
		
		private function instrLSR(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * LSR *
			// *******
			var temp:int;
			
			// Shift right one bit:
			if(addrMode == 4){ // ADDR_ACC

				temp = (_reg_acc & 0xFF);
				_f_carry = temp&1;
				temp >>= 1;
				_reg_acc = temp;

			}else{

				temp = load(addr) & 0xFF;
				_f_carry = temp&1;
				temp >>= 1;
				write(addr, temp);

			}
			_f_sign = 0;
			_f_zero = temp;
			return cycleCount;
		}
		
		private function instrNOP(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * NOP *
			// *******

			// No OPeration.
			return cycleCount;
		}
		
		private function instrORA(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * ORA *
			// *******

			// OR memory with accumulator, store in accumulator.
			var temp:int;
			temp = (load(addr)|_reg_acc)&255;
			_f_sign = (temp>>7)&1;
			_f_zero = temp;
			_reg_acc = temp;
			if(addrMode!=11)cycleCount+=cycleAdd; // PostIdxInd = 11
			return cycleCount;
		}
		
		private function instrPHA(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * PHA *
			// *******

			// Push accumulator on stack
			push(_reg_acc);
			return cycleCount;			
		}
		
		private function instrPHP(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * PHP *
			// *******

			// Push processor status on stack
			// This doesn't belong here: f_brk = 1;
			push(
				(_f_carry)|
				((_f_zero==0?1:0)<<1)|
				(_f_interrupt<<2)|
				(_f_decimal<<3)|
				(1<<4)|  // Break flag is always set when pushed onto the stack
				(_f_notused<<5)|
				(_f_overflow<<6)|
				(_f_sign<<7)
			);
			return cycleCount;
		}
		
		private function instrPLA(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * PLA *
			// *******

			// Pull accumulator from stack
			_reg_acc = pull();
			_f_sign = (_reg_acc>>7)&1;
			_f_zero = _reg_acc;
			return cycleCount;
		}
		
		private function instrPLP(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * PLP *
			// *******

			// Pull processor status from stack
			var temp:int;
			temp = pull();
			_f_carry     = (temp   )&1;
			_f_zero      = (((temp>>1)&1)==1)?0:1;
			_f_interrupt = (temp>>2)&1;
			_f_decimal   = (temp>>3)&1;
			_f_brk       = 0;// (temp >> 4) & 1;
			_f_notused   = (temp>>5)&1;
			_f_overflow  = (temp>>6)&1;
			_f_sign      = (temp>>7)&1;

			_f_notused = 1;
			return cycleCount;
		}
		
		private function instrROL(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			var temp:int;
			var add:uint;
			
			// *******
			// * ROL *
			// *******

			// Rotate one bit left
			if(addrMode == 4){ // ADDR_ACC = 4

				temp = _reg_acc;
				add = _f_carry;
				_f_carry = (temp>>7)&1;
				temp = ((temp<<1)&0xFF)+add;
				_reg_acc = temp;

			}else{

				temp = load(addr);
				add = _f_carry;
				_f_carry = (temp>>7)&1;
				temp = ((temp<<1)&0xFF)+add;    
				write(addr, temp);
			}
			_f_sign = (temp>>7)&1;
			_f_zero = temp;
			return cycleCount;
		}
		
		private function instrROR(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * ROR *
			// *******
			var add:uint;
			var temp:int;
			// Rotate one bit right
			if(addrMode == 4){ // ADDR_ACC = 4

				add = _f_carry<<7;
				_f_carry = _reg_acc&1;
				temp = (_reg_acc>>1)+add;   
				_reg_acc = temp;

			}else{

				temp = load(addr);
				add = _f_carry<<7;
				_f_carry = temp&1;
				temp = (temp>>1)+add;
				write(addr, temp);

			}
			_f_sign = (temp>>7)&1;
			_f_zero = temp;
			return cycleCount;
		}
		
		private function instrRTI(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * RTI *
			// *******

			// Return from interrupt. Pull status and PC from stack.
			var temp:int;
			temp = pull();
			_f_carry     = (temp   )&1;
			_f_zero      = ((temp>>1)&1)==0?1:0;
			_f_interrupt = (temp>>2)&1;
			_f_decimal   = (temp>>3)&1;
			_f_brk       = 0;// (temp >> 4) & 1;
			_f_notused   = (temp>>5)&1;
			_f_overflow  = (temp>>6)&1;
			_f_sign      = (temp>>7)&1;

			_reg_pc = pull();
			_reg_pc += (pull()<<8);
			if(_reg_pc==0xFFFF){
				return 0;
			}
			_reg_pc--;
			_f_notused = 1;
			return cycleCount;
		}
		
		private function instrRTS(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * RTS *
			// *******

			// Return from subroutine. Pull PC from stack.
			
			_reg_pc = pull();
			_reg_pc += (pull()<<8);
			
			if(_reg_pc==0xFFFF){
				return 0; // return from NSF play routine:
			}
			return cycleCount;
		}
		
		private function instrSBC(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * SBC *
			// *******
			var temp:int;
			temp = _reg_acc-load(addr)-(1-_f_carry);
			_f_sign = (temp>>7)&1;
			_f_zero = temp&0xFF;
			_f_overflow = ((((_reg_acc^temp)&0x80)!=0 && ((_reg_acc^load(addr))&0x80)!=0)?1:0);
			_f_carry = (temp<0?0:1);
			_reg_acc = (temp&0xFF);
			if(addrMode!=11)cycleCount+=cycleAdd; // PostIdxInd = 11
			return cycleCount;
		}
		
		private function instrSEC(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * SEC *
			// *******

			// Set carry flag
			_f_carry = 1;
			return cycleCount;
		}
		
		private function instrSED(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * SED *
			// *******

			// Set decimal mode
			_f_decimal = 1;
			return cycleCount;
		}
		
		private function instrSEI(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * SEI *
			// *******

			// Set interrupt disable status
			_f_interrupt = 1;
			return cycleCount;
		}
		
		private function instrSTA(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * STA *
			// *******

			// Store accumulator in memory
			write(addr, _reg_acc);
			return cycleCount;
		}
		
		private function instrSTX(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * STX *
			// *******

			// Store index X in memory
			write(addr, _reg_x);
			return cycleCount;
		}
		
		private function instrSTY(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * STY *
			// *******

			// Store index Y in memory:
			write(addr, _reg_y);
			return cycleCount;
		}
		
		private function instrTAX(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint		
		{
			// *******
			// * TAX *
			// *******

			// Transfer accumulator to index X:
			_reg_x = _reg_acc;
			_f_sign = (_reg_acc>>7)&1;
			_f_zero = _reg_acc;
			return cycleCount;
		}
		
		private function instrTAY(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * TAY *
			// *******

			// Transfer accumulator to index Y:
			_reg_y = _reg_acc;
			_f_sign = (_reg_acc>>7)&1;
			_f_zero = _reg_acc;
			return cycleCount;
		}
		
		private function instrTSX(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * TSX *
			// *******

			// Transfer stack pointer to index X:
			_reg_x = (_reg_sp-0x0100);
			_f_sign = (_reg_sp>>7)&1;
			_f_zero = _reg_x;
			return cycleCount;
		}

		private function instrTXA(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * TXA *
			// *******

			// Transfer index X to accumulator:
			_reg_acc = _reg_x;
			_f_sign = (_reg_x>>7)&1;
			_f_zero = _reg_x;
			return cycleCount;
		}
		
		private function instrTXS(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * TXS *
			// *******

			// Transfer index X to stack pointer:
			_reg_sp = (_reg_x+0x0100);
			stackWrap();
			return cycleCount;
		}
		
		private function instrTYA(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * TYA *
			// *******

			// Transfer index Y to accumulator:
			_reg_acc = _reg_y;
			_f_sign = (_reg_y>>7)&1;
			_f_zero = _reg_y;
			return cycleCount;
		}
		
		private function instrXXX(opaddr:uint, addr:uint, addrMode:uint, cycleCount:uint, cycleAdd:uint):uint
		{
			// *******
			// * ??? *
			// *******

			nes.stop();
			//cpuState.error = true;
			nes.crashMessage = "Game crashed, invalid opcode.";
			return cycleCount;
			
		}

		private function load(addr:uint):uint
		{
			addr &= 0xFFFF;
			var loadHandler:int = loadHandlers[addr];
			
			if (loadHandler == 0)
			{
				if (addr < 0x2000)
				{
					return mem[addr & 0x7ff];
				}
				else
				{
					return mem[addr];
				}
			}
			else
			{
				return _handlerJumpTable[loadHandler](addr);
			}
		}
		
		private function load16bit(addr:uint):uint
		{
			if (addr < 0x1FFF) {
				return mem[addr&0x7FF] 
					| (mem[(addr+1)&0x7FF]<<8);
			}
			else {
				return load(addr) | (load(addr+1) << 8);
			}
		}
		
		private function write(addr:uint, val:uint):void
		{
			var writeHandler:int = writeHandlers[addr];
			
			if (writeHandler == 0)
			{
				if (addr < 0x2000)
				{
					mem[addr & 0x7ff] = val;
				}
				else
				{
					mem[addr] = val;
				}
			}
			else {
				_handlerJumpTable[writeHandler](addr, val);
			}
		}

		public function requestIrq(type:uint):void
		{
			if(_irqRequested){
				if(type == IRQ_NORMAL){
					return;
				}
				////System.out.println("too fast irqs. type="+type);
			}
			_irqRequested = true;
			_irqType = type;
		}

		private function push(value:uint):void
		{
			mem[_reg_sp] = value;
			//nes.mmap.write(_reg_sp, value);
			_reg_sp--;
			_reg_sp = 0x0100 | (_reg_sp&0xFF);
		}

		private function stackWrap():void
		{
			_reg_sp = 0x0100 | (_reg_sp&0xFF);
		}

		private function pull():uint
		{
			_reg_sp++;
			_reg_sp = 0x0100 | (_reg_sp & 0xFF);
			return mem[_reg_sp];
			//return nes.mmap.load(_reg_sp, mem);
		}

		private function pageCross(addr1:uint, addr2:uint):Boolean
		{
			return ((addr1&0xFF00) != (addr2&0xFF00));
		}

		public function haltCycles(cycles:uint):void
		{
			cyclesToHalt += cycles;
		}

		private function doNonMaskableInterrupt(status:uint):void
		{
			// Check whether VBlank Interrupts are enabled
			if ((load(0x2000) & 128) != 0) 
			{ 
				_reg_pc_new++;
				push((_reg_pc_new>>8)&0xFF);
				push(_reg_pc_new&0xFF);
				//F_INTERRUPT_NEW = 1;
				push(status);

				_reg_pc_new = load(0xFFFA) | (load(0xFFFB) << 8);
				_reg_pc_new--;
			}
		}
		
		private function doResetInterrupt():void
		{
			_reg_pc_new = load(0xFFFC) | (load(0xFFFD) << 8);
			_reg_pc_new--;
		}

		private function doIrq(status:uint):void
		{
			_reg_pc_new++;
			push((_reg_pc_new>>8)&0xFF);
			push(_reg_pc_new&0xFF);
			push(status);
			_f_interrupt_new = 1;
			_f_brk_new = 0;

			_reg_pc_new = load(0xFFFE) | (load(0xFFFF) << 8);
			_reg_pc_new--;
		}

		private function getStatus():uint
		{
			return (_f_carry)
					|((_f_zero==0?1:0)<<1)
					|(_f_interrupt<<2)
					|(_f_decimal<<3)
					|(_f_brk<<4)
					|(_f_notused<<5)
					|(_f_overflow<<6)
					|(_f_sign<<7);
		}
		
		private function setStatus(st:uint):void
		{
			_f_carry     = (st   )&1;
			_f_zero      = (((st>>1)&1)==1)?0:1;
			_f_interrupt = (st>>2)&1;
			_f_decimal   = (st>>3)&1;
			_f_brk       = (st>>4)&1;
			_f_notused   = (st>>5)&1;
			_f_overflow  = (st>>6)&1;
			_f_sign      = (st>>7)&1;
		}
	}

}

internal class OpData
{
	private static const INS_ADC:uint = 0;
    private static const INS_AND:uint = 1;
    private static const INS_ASL:uint = 2;
    
    private static const INS_BCC:uint = 3;
    private static const INS_BCS:uint = 4;
    private static const INS_BEQ:uint = 5;
    private static const INS_BIT:uint = 6;
    private static const INS_BMI:uint = 7;
    private static const INS_BNE:uint = 8;
    private static const INS_BPL:uint = 9;
    private static const INS_BRK:uint = 10;
    private static const INS_BVC:uint = 11;
    private static const INS_BVS:uint = 12;
    
    private static const INS_CLC:uint = 13;
    private static const INS_CLD:uint = 14;
    private static const INS_CLI:uint = 15;
    private static const INS_CLV:uint = 16;
    private static const INS_CMP:uint = 17;
    private static const INS_CPX:uint = 18;
    private static const INS_CPY:uint = 19;
    
    private static const INS_DEC:uint = 20;
    private static const INS_DEX:uint = 21;
    private static const INS_DEY:uint = 22;
    
    private static const INS_EOR:uint = 23;
    
    private static const INS_INC:uint = 24;
    private static const INS_INX:uint = 25;
    private static const INS_INY:uint = 26;
    
    private static const INS_JMP:uint = 27;
    private static const INS_JSR:uint = 28;
    
    private static const INS_LDA:uint = 29;
    private static const INS_LDX:uint = 30;
    private static const INS_LDY:uint = 31;
    private static const INS_LSR:uint = 32;
   
    private static const INS_NOP:uint = 33;
    
    private static const INS_ORA:uint = 34;
    
    private static const INS_PHA:uint = 35;
    private static const INS_PHP:uint = 36;
    private static const INS_PLA:uint = 37;
    private static const INS_PLP:uint = 38;
    
    private static const INS_ROL:uint = 39;
    private static const INS_ROR:uint = 40;
    private static const INS_RTI:uint = 41;
    private static const INS_RTS:uint = 42;
    
    private static const INS_SBC:uint = 43;
    private static const INS_SEC:uint = 44;
    private static const INS_SED:uint = 45;
    private static const INS_SEI:uint = 46;
    private static const INS_STA:uint = 47;
    private static const INS_STX:uint = 48;
    private static const INS_STY:uint = 49;
    
    private static const INS_TAX:uint = 50;
    private static const INS_TAY:uint = 51;
    private static const INS_TSX:uint = 52;
    private static const INS_TXA:uint = 53;
    private static const INS_TXS:uint = 54;
    private static const INS_TYA:uint = 55;
    
    private static const INS_DUMMY:uint = 56; // dummy instruction used for 'halting' the processor some cycles
	
	// Addressing Modes
	private static const ADDR_ZP:uint = 			0;
	private static const ADDR_REL:uint = 		1;
	private static const ADDR_IMP:uint = 		2;
	private static const ADDR_ABS:uint = 		3;
	private static const ADDR_ACC:uint = 		4;
	private static const ADDR_IMM:uint = 		5;
	private static const ADDR_ZPX:uint = 		6;
	private static const ADDR_ZPY:uint = 		7;
	private static const ADDR_ABSX:uint =		8;
	private static const ADDR_ABSY:uint = 		9;
	private static const ADDR_PREIDXIND:uint = 	10;
	private static const ADDR_POSTIDXIND:uint = 	11;
	private static const ADDR_INDABS:uint = 		12;
	
	public var opdata:Vector.<uint>;
	public static var instname:Array;
	private var addrDesc:Array;
	
	
	private function setOp(inst:uint, op:uint, addr:uint, size:uint, cycles:uint):void
	{
		opdata[op] =
            ((inst  &0xFF)    )| 
            ((addr  &0xFF)<< 8)| 
            ((size  &0xFF)<<16)| 
            ((cycles&0xFF)<<24);
	}
	
	public function OpData()
	{
		opdata = new Vector.<uint>(256);
		
		// Set all to invalid instruction to detect crashes
		for (var i:uint = 0; i < 256; i++)
		{
			opdata[i] = 0xFF;
		}
		
		// Now fill in all valid opcodes:
    
		// ADC:
		setOp(INS_ADC,0x69,ADDR_IMM,2,2);
		setOp(INS_ADC,0x65,ADDR_ZP,2,3);
		setOp(INS_ADC,0x75,ADDR_ZPX,2,4);
		setOp(INS_ADC,0x6D,ADDR_ABS,3,4);
		setOp(INS_ADC,0x7D,ADDR_ABSX,3,4);
		setOp(INS_ADC,0x79,ADDR_ABSY,3,4);
		setOp(INS_ADC,0x61,ADDR_PREIDXIND,2,6);
		setOp(INS_ADC,0x71,ADDR_POSTIDXIND,2,5);
		
		// AND:
		setOp(INS_AND,0x29,ADDR_IMM,2,2);
		setOp(INS_AND,0x25,ADDR_ZP,2,3);
		setOp(INS_AND,0x35,ADDR_ZPX,2,4);
		setOp(INS_AND,0x2D,ADDR_ABS,3,4);
		setOp(INS_AND,0x3D,ADDR_ABSX,3,4);
		setOp(INS_AND,0x39,ADDR_ABSY,3,4);
		setOp(INS_AND,0x21,ADDR_PREIDXIND,2,6);
		setOp(INS_AND,0x31,ADDR_POSTIDXIND,2,5);
		
		// ASL:
		setOp(INS_ASL,0x0A,ADDR_ACC,1,2);
		setOp(INS_ASL,0x06,ADDR_ZP,2,5);
		setOp(INS_ASL,0x16,ADDR_ZPX,2,6);
		setOp(INS_ASL,0x0E,ADDR_ABS,3,6);
		setOp(INS_ASL,0x1E,ADDR_ABSX,3,7);
		
		// BCC:
		setOp(INS_BCC,0x90,ADDR_REL,2,2);
		
		// BCS:
		setOp(INS_BCS,0xB0,ADDR_REL,2,2);
		
		// BEQ:
		setOp(INS_BEQ,0xF0,ADDR_REL,2,2);
		
		// BIT:
		setOp(INS_BIT,0x24,ADDR_ZP,2,3);
		setOp(INS_BIT,0x2C,ADDR_ABS,3,4);
		
		// BMI:
		setOp(INS_BMI,0x30,ADDR_REL,2,2);
		
		// BNE:
		setOp(INS_BNE,0xD0,ADDR_REL,2,2);
		
		// BPL:
		setOp(INS_BPL,0x10,ADDR_REL,2,2);
		
		// BRK:
		setOp(INS_BRK,0x00,ADDR_IMP,1,7);
		
		// BVC:
		setOp(INS_BVC,0x50,ADDR_REL,2,2);
		
		// BVS:
		setOp(INS_BVS,0x70,ADDR_REL,2,2);
		
		// CLC:
		setOp(INS_CLC,0x18,ADDR_IMP,1,2);
		
		// CLD:
		setOp(INS_CLD,0xD8,ADDR_IMP,1,2);
		
		// CLI:
		setOp(INS_CLI,0x58,ADDR_IMP,1,2);
		
		// CLV:
		setOp(INS_CLV,0xB8,ADDR_IMP,1,2);
		
		// CMP:
		setOp(INS_CMP,0xC9,ADDR_IMM,2,2);
		setOp(INS_CMP,0xC5,ADDR_ZP,2,3);
		setOp(INS_CMP,0xD5,ADDR_ZPX,2,4);
		setOp(INS_CMP,0xCD,ADDR_ABS,3,4);
		setOp(INS_CMP,0xDD,ADDR_ABSX,3,4);
		setOp(INS_CMP,0xD9,ADDR_ABSY,3,4);
		setOp(INS_CMP,0xC1,ADDR_PREIDXIND,2,6);
		setOp(INS_CMP,0xD1,ADDR_POSTIDXIND,2,5);
		
		// CPX:
		setOp(INS_CPX,0xE0,ADDR_IMM,2,2);
		setOp(INS_CPX,0xE4,ADDR_ZP,2,3);
		setOp(INS_CPX,0xEC,ADDR_ABS,3,4);
		
		// CPY:
		setOp(INS_CPY,0xC0,ADDR_IMM,2,2);
		setOp(INS_CPY,0xC4,ADDR_ZP,2,3);
		setOp(INS_CPY,0xCC,ADDR_ABS,3,4);
		
		// DEC:
		setOp(INS_DEC,0xC6,ADDR_ZP,2,5);
		setOp(INS_DEC,0xD6,ADDR_ZPX,2,6);
		setOp(INS_DEC,0xCE,ADDR_ABS,3,6);
		setOp(INS_DEC,0xDE,ADDR_ABSX,3,7);
		
		// DEX:
		setOp(INS_DEX,0xCA,ADDR_IMP,1,2);
		
		// DEY:
		setOp(INS_DEY,0x88,ADDR_IMP,1,2);
		
		// EOR:
		setOp(INS_EOR,0x49,ADDR_IMM,2,2);
		setOp(INS_EOR,0x45,ADDR_ZP,2,3);
		setOp(INS_EOR,0x55,ADDR_ZPX,2,4);
		setOp(INS_EOR,0x4D,ADDR_ABS,3,4);
		setOp(INS_EOR,0x5D,ADDR_ABSX,3,4);
		setOp(INS_EOR,0x59,ADDR_ABSY,3,4);
		setOp(INS_EOR,0x41,ADDR_PREIDXIND,2,6);
		setOp(INS_EOR,0x51,ADDR_POSTIDXIND,2,5);
		
		// INC:
		setOp(INS_INC,0xE6,ADDR_ZP,2,5);
		setOp(INS_INC,0xF6,ADDR_ZPX,2,6);
		setOp(INS_INC,0xEE,ADDR_ABS,3,6);
		setOp(INS_INC,0xFE,ADDR_ABSX,3,7);
		
		// INX:
		setOp(INS_INX,0xE8,ADDR_IMP,1,2);
		
		// INY:
		setOp(INS_INY,0xC8,ADDR_IMP,1,2);
		
		// JMP:
		setOp(INS_JMP,0x4C,ADDR_ABS,3,3);
		setOp(INS_JMP,0x6C,ADDR_INDABS,3,5);
		
		// JSR:
		setOp(INS_JSR,0x20,ADDR_ABS,3,6);
		
		// LDA:
		setOp(INS_LDA,0xA9,ADDR_IMM,2,2);
		setOp(INS_LDA,0xA5,ADDR_ZP,2,3);
		setOp(INS_LDA,0xB5,ADDR_ZPX,2,4);
		setOp(INS_LDA,0xAD,ADDR_ABS,3,4);
		setOp(INS_LDA,0xBD,ADDR_ABSX,3,4);
		setOp(INS_LDA,0xB9,ADDR_ABSY,3,4);
		setOp(INS_LDA,0xA1,ADDR_PREIDXIND,2,6);
		setOp(INS_LDA,0xB1,ADDR_POSTIDXIND,2,5);
		
		
		// LDX:
		setOp(INS_LDX,0xA2,ADDR_IMM,2,2);
		setOp(INS_LDX,0xA6,ADDR_ZP,2,3);
		setOp(INS_LDX,0xB6,ADDR_ZPY,2,4);
		setOp(INS_LDX,0xAE,ADDR_ABS,3,4);
		setOp(INS_LDX,0xBE,ADDR_ABSY,3,4);
		
		// LDY:
		setOp(INS_LDY,0xA0,ADDR_IMM,2,2);
		setOp(INS_LDY,0xA4,ADDR_ZP,2,3);
		setOp(INS_LDY,0xB4,ADDR_ZPX,2,4);
		setOp(INS_LDY,0xAC,ADDR_ABS,3,4);
		setOp(INS_LDY,0xBC,ADDR_ABSX,3,4);
		
		// LSR:
		setOp(INS_LSR,0x4A,ADDR_ACC,1,2);
		setOp(INS_LSR,0x46,ADDR_ZP,2,5);
		setOp(INS_LSR,0x56,ADDR_ZPX,2,6);
		setOp(INS_LSR,0x4E,ADDR_ABS,3,6);
		setOp(INS_LSR,0x5E,ADDR_ABSX,3,7);
		
		// NOP:
		setOp(INS_NOP, 0xEA, ADDR_IMP, 1, 2);
		setOp(INS_NOP, 0x04, ADDR_ZP, 2, 3);
		setOp(INS_NOP, 0x44, ADDR_ZP, 2, 3);
		setOp(INS_NOP, 0x64, ADDR_ZP, 2, 3);
		
		// ORA:
		setOp(INS_ORA,0x09,ADDR_IMM,2,2);
		setOp(INS_ORA,0x05,ADDR_ZP,2,3);
		setOp(INS_ORA,0x15,ADDR_ZPX,2,4);
		setOp(INS_ORA,0x0D,ADDR_ABS,3,4);
		setOp(INS_ORA,0x1D,ADDR_ABSX,3,4);
		setOp(INS_ORA,0x19,ADDR_ABSY,3,4);
		setOp(INS_ORA,0x01,ADDR_PREIDXIND,2,6);
		setOp(INS_ORA,0x11,ADDR_POSTIDXIND,2,5);
		
		// PHA:
		setOp(INS_PHA,0x48,ADDR_IMP,1,3);
		
		// PHP:
		setOp(INS_PHP,0x08,ADDR_IMP,1,3);
		
		// PLA:
		setOp(INS_PLA,0x68,ADDR_IMP,1,4);
		
		// PLP:
		setOp(INS_PLP,0x28,ADDR_IMP,1,4);
		
		// ROL:
		setOp(INS_ROL,0x2A,ADDR_ACC,1,2);
		setOp(INS_ROL,0x26,ADDR_ZP,2,5);
		setOp(INS_ROL,0x36,ADDR_ZPX,2,6);
		setOp(INS_ROL,0x2E,ADDR_ABS,3,6);
		setOp(INS_ROL,0x3E,ADDR_ABSX,3,7);
		
		// ROR:
		setOp(INS_ROR,0x6A,ADDR_ACC,1,2);
		setOp(INS_ROR,0x66,ADDR_ZP,2,5);
		setOp(INS_ROR,0x76,ADDR_ZPX,2,6);
		setOp(INS_ROR,0x6E,ADDR_ABS,3,6);
		setOp(INS_ROR,0x7E,ADDR_ABSX,3,7);
		
		// RTI:
		setOp(INS_RTI,0x40,ADDR_IMP,1,6);
		
		// RTS:
		setOp(INS_RTS,0x60,ADDR_IMP,1,6);
		
		// SBC:
		setOp(INS_SBC,0xE9,ADDR_IMM,2,2);
		setOp(INS_SBC,0xE5,ADDR_ZP,2,3);
		setOp(INS_SBC,0xF5,ADDR_ZPX,2,4);
		setOp(INS_SBC,0xED,ADDR_ABS,3,4);
		setOp(INS_SBC,0xFD,ADDR_ABSX,3,4);
		setOp(INS_SBC,0xF9,ADDR_ABSY,3,4);
		setOp(INS_SBC,0xE1,ADDR_PREIDXIND,2,6);
		setOp(INS_SBC,0xF1,ADDR_POSTIDXIND,2,5);
		
		// SEC:
		setOp(INS_SEC,0x38,ADDR_IMP,1,2);
		
		// SED:
		setOp(INS_SED,0xF8,ADDR_IMP,1,2);
		
		// SEI:
		setOp(INS_SEI,0x78,ADDR_IMP,1,2);
		
		// STA:
		setOp(INS_STA,0x85,ADDR_ZP,2,3);
		setOp(INS_STA,0x95,ADDR_ZPX,2,4);
		setOp(INS_STA,0x8D,ADDR_ABS,3,4);
		setOp(INS_STA,0x9D,ADDR_ABSX,3,5);
		setOp(INS_STA,0x99,ADDR_ABSY,3,5);
		setOp(INS_STA,0x81,ADDR_PREIDXIND,2,6);
		setOp(INS_STA,0x91,ADDR_POSTIDXIND,2,6);
		
		// STX:
		setOp(INS_STX,0x86,ADDR_ZP,2,3);
		setOp(INS_STX,0x96,ADDR_ZPY,2,4);
		setOp(INS_STX,0x8E,ADDR_ABS,3,4);
		
		// STY:
		setOp(INS_STY,0x84,ADDR_ZP,2,3);
		setOp(INS_STY,0x94,ADDR_ZPX,2,4);
		setOp(INS_STY,0x8C,ADDR_ABS,3,4);
		
		// TAX:
		setOp(INS_TAX,0xAA,ADDR_IMP,1,2);
		
		// TAY:
		setOp(INS_TAY,0xA8,ADDR_IMP,1,2);
		
		// TSX:
		setOp(INS_TSX,0xBA,ADDR_IMP,1,2);
		
		// TXA:
		setOp(INS_TXA,0x8A,ADDR_IMP,1,2);
		
		// TXS:
		setOp(INS_TXS,0x9A,ADDR_IMP,1,2);
		
		// TYA:
		setOp(INS_TYA,0x98,ADDR_IMP,1,2);
		
		// This seems unused
		//cycTable = new Array(
		///*0x00*/ 7,6,2,8,3,3,5,5,3,2,2,2,4,4,6,6,
		///*0x10*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		///*0x20*/ 6,6,2,8,3,3,5,5,4,2,2,2,4,4,6,6,
		///*0x30*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		///*0x40*/ 6,6,2,8,3,3,5,5,3,2,2,2,3,4,6,6,
		///*0x50*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		///*0x60*/ 6,6,2,8,3,3,5,5,4,2,2,2,5,4,6,6,
		///*0x70*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		///*0x80*/ 2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,
		///*0x90*/ 2,6,2,6,4,4,4,4,2,5,2,5,5,5,5,5,
		///*0xA0*/ 2,6,2,6,3,3,3,3,2,2,2,2,4,4,4,4,
		///*0xB0*/ 2,5,2,5,4,4,4,4,2,4,2,4,4,4,4,4,
		///*0xC0*/ 2,6,2,8,3,3,5,5,2,2,2,2,4,4,6,6,
		///*0xD0*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7,
		///*0xE0*/ 2,6,3,8,3,3,5,5,2,2,2,2,4,4,6,6,
		///*0xF0*/ 2,5,2,8,4,4,6,6,2,4,2,7,4,4,7,7
		//);
		
		
		instname = new Array(56);
		
		// Instruction Names:
		instname[ 0] = "ADC";
		instname[ 1] = "AND";
		instname[ 2] = "ASL";
		instname[ 3] = "BCC";
		instname[ 4] = "BCS";
		instname[ 5] = "BEQ";
		instname[ 6] = "BIT";
		instname[ 7] = "BMI";
		instname[ 8] = "BNE";
		instname[ 9] = "BPL";
		instname[10] = "BRK";
		instname[11] = "BVC";
		instname[12] = "BVS";
		instname[13] = "CLC";
		instname[14] = "CLD";
		instname[15] = "CLI";
		instname[16] = "CLV";
		instname[17] = "CMP";
		instname[18] = "CPX";
		instname[19] = "CPY";
		instname[20] = "DEC";
		instname[21] = "DEX";
		instname[22] = "DEY";
		instname[23] = "EOR";
		instname[24] = "INC";
		instname[25] = "INX";
		instname[26] = "INY";
		instname[27] = "JMP";
		instname[28] = "JSR";
		instname[29] = "LDA";
		instname[30] = "LDX";
		instname[31] = "LDY";
		instname[32] = "LSR";
		instname[33] = "NOP";
		instname[34] = "ORA";
		instname[35] = "PHA";
		instname[36] = "PHP";
		instname[37] = "PLA";
		instname[38] = "PLP";
		instname[39] = "ROL";
		instname[40] = "ROR";
		instname[41] = "RTI";
		instname[42] = "RTS";
		instname[43] = "SBC";
		instname[44] = "SEC";
		instname[45] = "SED";
		instname[46] = "SEI";
		instname[47] = "STA";
		instname[48] = "STX";
		instname[49] = "STY";
		instname[50] = "TAX";
		instname[51] = "TAY";
		instname[52] = "TSX";
		instname[53] = "TXA";
		instname[54] = "TXS";
		instname[55] = "TYA";
		
		
		addrDesc = new Array(
			"Zero Page           ",
			"Relative            ",
			"Implied             ",
			"Absolute            ",
			"Accumulator         ",
			"Immediate           ",
			"Zero Page,X         ",
			"Zero Page,Y         ",
			"Absolute,X          ",
			"Absolute,Y          ",
			"Preindexed Indirect ",
			"Postindexed Indirect",
			"Indirect Absolute   "
		);
	}
}