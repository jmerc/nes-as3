package system.Mappers 
{
	import interfaces.*;
	import system.*;
	import system.PPU.Tile;
	import utils.*;
	/**
	 * ...
	 * @author John
	 */
	public class Mapper0 implements IMapper
	{
		protected var nes:NES;
		
		private var joy1StrobeState:uint = 0;
		private var joy2StrobeState:uint = 0;
		private var joypadLastWrite:uint = 0;
		
		private var mousePressed:Boolean = false;
		private var mouseX:uint = 0;
		private var mouseY:uint = 0;
		
		public function Mapper0(nes:NES) 
		{
			this.nes = nes;
		}
		
		public function reset():void
		{
			joy1StrobeState = 0;
			joy2StrobeState = 0;
			joypadLastWrite = 0;
			
			mousePressed = false;
			mouseX = 0;
			mouseY = 0;
		}

		public function write(address:uint, value:uint):void
		{
			if (address < 0x2000) {
				// Mirroring of RAM:
				this.nes.cpu.mem[address & 0x7FF] = value;
			
			}
			else if (address > 0x4017) {
				this.nes.cpu.mem[address] = value;
				if (address >= 0x6000 && address < 0x8000) {
					// Write to SaveRAM. Store in file:
					// TODO: not yet
					//if(this.nes.rom!=null)
					//    this.nes.rom.writeBatteryRam(address,value);
				}
			}
			else if (address > 0x2007 && address < 0x4000) {
				this.regWrite(0x2000 + (address & 0x7), value);
			}
			else {
				this.regWrite(address, value);
			}
		}
		
		private function writelow(address:uint, value:uint):void
		{
			if (address < 0x2000) {
				// Mirroring of RAM:
				this.nes.cpu.mem[address & 0x7FF] = value;
			}
			else if (address > 0x4017) {
				this.nes.cpu.mem[address] = value;
			}
			else if (address > 0x2007 && address < 0x4000) {
				this.regWrite(0x2000 + (address & 0x7), value);
			}
			else {
				this.regWrite(address, value);
			}
		}

		public function load(address:uint, cpumem:Vector.<uint>):uint
		{
			// Wrap around:
			address &= 0xFFFF;
		
			// Check address range:
			if (address > 0x4017) {
				// ROM:
				return cpumem[address];
			}
			else if (address >= 0x2000) {
				// I/O Ports.
				return regLoad(address);
			}
			else {
				// RAM (mirrored)
				return cpumem[address & 0x7FF];
			}
		}

		private function regLoad(address:uint):uint
		{
			switch (address >> 12) { // use fourth nibble (0xF000)
				case 0:
					break;
				
				case 1:
					break;
				
				case 2:
					// Fall through to case 3
				case 3:
					// PPU Registers
					switch (address & 0x7) {
						case 0x0:
							// 0x2000:
							// PPU Control Register 1.
							// (the value is stored both
							// in main memory and in the
							// PPU as flags):
							// (not in the real NES)
							return this.nes.cpu.mem[0x2000];
						
						case 0x1:
							// 0x2001:
							// PPU Control Register 2.
							// (the value is stored both
							// in main memory and in the
							// PPU as flags):
							// (not in the real NES)
							return this.nes.cpu.mem[0x2001];
						
						case 0x2:
							// 0x2002:
							// PPU Status Register.
							// The value is stored in
							// main memory in addition
							// to as flags in the PPU.
							// (not in the real NES)
							return this.nes.ppu.readStatusRegister();
						
						case 0x3:
							return 0;
						
						case 0x4:
							// 0x2004:
							// Sprite Memory read.
							return this.nes.ppu.sramLoad();
						case 0x5:
							return 0;
						
						case 0x6:
							return 0;
						
						case 0x7:
							// 0x2007:
							// VRAM read:
							return this.nes.ppu.vramLoad();
					}
					break;
				case 4:
					// Sound+Joypad registers
					switch (address - 0x4015) {
						case 0:
							// 0x4015:
							// Sound channel enable, DMC Status
							return this.nes.apu.readReg(address);
						
						case 1:
							// 0x4016:
							// Joystick 1 + Strobe
							return this.joy1Read();
						
						case 2:
							// 0x4017:
							// Joystick 2 + Strobe
							if (this.mousePressed) {
							
								// Check for white pixel nearby:
								var sx:uint = Math.max(0, this.mouseX - 4);
								var ex:uint = Math.min(256, this.mouseX + 4);
								var sy:uint = Math.max(0, this.mouseY - 4);
								var ey:uint = Math.min(240, this.mouseY + 4);
								var w:uint = 0;
							
								for (var y:uint=sy; y<ey; y++) {
									for (var x:uint=sx; x<ex; x++) {
								   
										if (this.nes.ppu.buffer[(y<<8)+x] == 0xFFFFFF) {
											w |= 0x1<<3;
											trace("Clicked on white!");
											break;
										}
									}
								}
							
								w |= (this.mousePressed?(0x1<<4):0);
								return (this.joy2Read()|w) & 0xFFFF;
							}
							else {
								return this.joy2Read();
							}
						
					}
					break;
			}
			return 0;
		}

		private function regWrite(address:uint, value:uint):void
		{
			switch (address) {
				case 0x2000:
					// PPU Control register 1
					this.nes.cpu.mem[address] = value;
					this.nes.ppu.updateControlReg1(value);
					break;
				
				case 0x2001:
					// PPU Control register 2
					this.nes.cpu.mem[address] = value;
					this.nes.ppu.updateControlReg2(value);
					break;
				
				case 0x2003:
					// Set Sprite RAM address:
					this.nes.ppu.writeSRAMAddress(value);
					break;
				
				case 0x2004:
					// Write to Sprite RAM:
					this.nes.ppu.sramWrite(value);
					break;
				
				case 0x2005:
					// Screen Scroll offsets:
					this.nes.ppu.scrollWrite(value);
					break;
				
				case 0x2006:
					// Set VRAM address:
					this.nes.ppu.writeVRAMAddress(value);
					break;
				
				case 0x2007:
					// Write to VRAM:
					this.nes.ppu.vramWrite(value);
					break;
				
				case 0x4014:
					// Sprite Memory DMA Access
					this.nes.ppu.sramDMA(value);
					break;
				
				case 0x4015:
					// Sound Channel Switch, DMC Status
					this.nes.apu.writeReg(address, value);
					break;
				
				case 0x4016:
					// Joystick 1 + Strobe
					if ((value&1) === 0 && (this.joypadLastWrite&1) === 1) {
						this.joy1StrobeState = 0;
						this.joy2StrobeState = 0;
					}
					this.joypadLastWrite = value;
					break;
				
				case 0x4017:
					// Sound channel frame sequencer:
					this.nes.apu.writeReg(address, value);
					break;
				
				default:
					// Sound registers
					////System.out.println("write to sound reg");
					if (address >= 0x4000 && address <= 0x4017) {
						this.nes.apu.writeReg(address,value);
					}
					
			}
		}

		private function joy1Read():uint
		{
			var ret:uint;
		
			switch (this.joy1StrobeState) {
				case 0:
				case 1:
				case 2:
				case 3:
				case 4:
				case 5:
				case 6:
				case 7:
					ret = this.nes.input.state1[this.joy1StrobeState];
					break;
				case 8:
				case 9:
				case 10:
				case 11:
				case 12:
				case 13:
				case 14:
				case 15:
				case 16:
				case 17:
				case 18:
					ret = 0;
					break;
				case 19:
					ret = 1;
					break;
				default:
					ret = 0;
			}
		
			this.joy1StrobeState++;
			if (this.joy1StrobeState == 24) {
				this.joy1StrobeState = 0;
			}
		
			return ret;
		}

		private function joy2Read():uint
		{
			var ret:uint;
		
			switch (this.joy2StrobeState) {
				case 0:
				case 1:
				case 2:
				case 3:
				case 4:
				case 5:
				case 6:
				case 7:
					ret = this.nes.input.state2[this.joy2StrobeState];
					break;
				case 8:
				case 9:
				case 10:
				case 11:
				case 12:
				case 13:
				case 14:
				case 15:
				case 16:
				case 17:
				case 18:
					ret = 0;
					break;
				case 19:
					ret = 1;
					break;
				default:
					ret = 0;
			}

			this.joy2StrobeState++;
			if (this.joy2StrobeState == 24) {
				this.joy2StrobeState = 0;
			}
		
			return ret;
		}

		public function loadROM():void
		{
			if (!this.nes.rom.valid || this.nes.rom.romCount < 1) {
				trace("NoMapper: Invalid ROM! Unable to load.");
				return;
			}
		
			// Load ROM into memory:
			this.loadPRGROM();
		
			// Load CHR-ROM:
			this.loadCHRROM();
		
			// Load Battery RAM (if present):
			this.loadBatteryRam();
		
			// Reset IRQ:
			//nes.getCpu().doResetInterrupt();
			this.nes.cpu.requestIrq(CPU.IRQ_RESET);
		}

		private function loadPRGROM():void
		{
			if (this.nes.rom.romCount > 1) {
				// Load the two first banks into memory.
				this.loadRomBank(0, 0x8000);
				this.loadRomBank(1, 0xC000);
			}
			else {
				// Load the one bank into both memory locations:
				this.loadRomBank(0, 0x8000);
				this.loadRomBank(0, 0xC000);
			}
		}

		protected function loadCHRROM():void
		{
			////System.out.println("Loading CHR ROM..");
			if (this.nes.rom.vromCount > 0) {
				if (this.nes.rom.vromCount == 1) {
					this.loadVromBank(0,0x0000);
					this.loadVromBank(0,0x1000);
				}
				else {
					this.loadVromBank(0,0x0000);
					this.loadVromBank(1,0x1000);
				}
			}
			else {
				//System.out.println("There aren't any CHR-ROM banks..");
			}
		}

		protected function loadBatteryRam():void
		{
			/*
			if (this.nes.rom.batteryRam) {
				var ram = this.nes.rom.batteryRam;
				if (ram !== null && ram.length == 0x2000) {
					ArrayUtils.copyArrayElements(ram, 0, nes.cpu.mem, 0x6000, 0x2000);
				}
			}
			*/
		}

		protected function loadRomBank(bank:uint, address:uint):void
		{
			// Loads a ROM bank into the specified address.
			bank %= this.nes.rom.romCount;
			//var data = this.nes.rom.rom[bank];
			//cpuMem.write(address,data,data.length);
			ArrayUtils.copyArrayElements(nes.rom.rom[bank], 0, nes.cpu.mem, address, 16384);
		}

		protected function loadVromBank(bank:uint, address:uint):void
		{
			if (this.nes.rom.vromCount === 0) {
				return;
			}
			this.nes.ppu.triggerRendering();
		
			ArrayUtils.copyArrayElements(this.nes.rom.vrom[bank % this.nes.rom.vromCount], 
				0, this.nes.ppu.vramMem, address, 4096);
		
			var vromTile:Vector.<Tile> = this.nes.rom.vromTile[bank % this.nes.rom.vromCount];
			ArrayUtils.copyArrayElements(vromTile, 0, this.nes.ppu.ptTile,address >> 4, 256);
		}

		protected function load32kRomBank(bank:uint, address:uint):void
		{
			this.loadRomBank((bank*2) % this.nes.rom.romCount, address);
			this.loadRomBank((bank*2+1) % this.nes.rom.romCount, address+16384);
		}

		protected function load8kVromBank(bank4kStart:uint, address:uint):void
		{
			if (this.nes.rom.vromCount === 0) {
				return;
			}
			this.nes.ppu.triggerRendering();

			this.loadVromBank((bank4kStart) % this.nes.rom.vromCount, address);
			this.loadVromBank((bank4kStart + 1) % this.nes.rom.vromCount,
					address + 4096);
		}

		protected function load1kVromBank(bank1k:uint, address:uint):void
		{
			if (this.nes.rom.vromCount === 0) {
				return;
			}
			this.nes.ppu.triggerRendering();
		
			var bank4k:uint = Math.floor(bank1k / 4) % this.nes.rom.vromCount;
			var bankoffset:uint = (bank1k % 4) * 1024;
			ArrayUtils.copyArrayElements(this.nes.rom.vrom[bank4k], 0, 
				this.nes.ppu.vramMem, bankoffset, 1024);
		
			// Update tiles:
			var vromTile:Array = this.nes.rom.vromTile[bank4k];
			var baseIndex:uint = address >> 4;
			for (var i:uint = 0; i < 64; i++) {
				this.nes.ppu.ptTile[baseIndex+i] = vromTile[((bank1k%4) << 6) + i];
			}
		}

		private function load2kVromBank(bank2k:uint, address:uint):void
		{
			if (this.nes.rom.vromCount === 0) {
				return;
			}
			this.nes.ppu.triggerRendering();
		
			var bank4k:uint = Math.floor(bank2k / 2) % this.nes.rom.vromCount;
			var bankoffset:uint = (bank2k % 2) * 2048;
			ArrayUtils.copyArrayElements(this.nes.rom.vrom[bank4k], bankoffset,
				this.nes.ppu.vramMem, address, 2048);
		
			// Update tiles:
			var vromTile:Array = this.nes.rom.vromTile[bank4k];
			var baseIndex:uint = address >> 4;
			for (var i:uint = 0; i < 128; i++) {
				this.nes.ppu.ptTile[baseIndex+i] = vromTile[((bank2k%2) << 7) + i];
			}
		}

		protected function load8kRomBank(bank8k:uint, address:uint):void
		{
			var bank16k:uint = Math.floor(bank8k / 2) % this.nes.rom.romCount;
			var offset:uint = (bank8k % 2) * 8192;
		
			//this.nes.cpu.mem.write(address,this.nes.rom.rom[bank16k],offset,8192);
			ArrayUtils.copyArrayElements(this.nes.rom.rom[bank16k], offset, 
					  this.nes.cpu.mem, address, 8192);
		}

		public function clockIrqCounter():void
		{
			// Does nothing. This is used by the MMC3 mapper.
		}

		public function latchAccess(address:uint):void
		{
			// Does nothing. This is used by MMC2.
		}
	}

}