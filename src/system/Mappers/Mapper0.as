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
		protected var _nes:NES;
		
		private var _joy1StrobeState:uint = 0;
		private var _joy2StrobeState:uint = 0;
		private var _joypadLastWrite:uint = 0;
		
		private var mousePressed:Boolean = false;
		private var mouseX:uint = 0;
		private var mouseY:uint = 0;
		
		public function Mapper0(nes:NES) 
		{
			_nes = nes;
			reset();
		}
		
		public function reset():void
		{
			_joy1StrobeState = 0;
			_joy2StrobeState = 0;
			_joypadLastWrite = 0;
			
			mousePressed = false;
			mouseX = 0;
			mouseY = 0;
			
			_nes.cpu.resetHandlers();
			registerWriteHandlers();
			registerLoadHandlers();
		}

		protected function registerWriteHandlers():void
		{
			var addr:uint;
			
			// PPU Register Writes (2000-3fff, bitmask 0x2007)
			var updateControlReg1Handler:int = 	_nes.cpu.registerHandler(_nes.ppu.writeControllerReg);
			var updateControlReg2Handler:int = 	_nes.cpu.registerHandler(_nes.ppu.writeMaskReg);
			var sramAddrHandler:int = 			_nes.cpu.registerHandler(_nes.ppu.writeOamAddrReg);
			var sramWriteHandler:int = 			_nes.cpu.registerHandler(_nes.ppu.writeOamDataReg);
			var scrollWriteHandler:int = 		_nes.cpu.registerHandler(_nes.ppu.writeScrollReg);
			var vramAddrHandler:int = 			_nes.cpu.registerHandler(_nes.ppu.writeAddressReg);
			var vramWriteHandler:int = 			_nes.cpu.registerHandler(_nes.ppu.writeDataReg);
			
			for (addr = 0x2000; addr < 0x4000; addr+= 8)
			{
				_nes.cpu.assignWriteHandler(addr + 0, updateControlReg1Handler);
				_nes.cpu.assignWriteHandler(addr + 1, updateControlReg2Handler);
				// no write on addr + 2 (todo: put an intercept here to avoid writing to memory?)
				_nes.cpu.assignWriteHandler(addr + 3, sramAddrHandler);
				_nes.cpu.assignWriteHandler(addr + 4 , sramWriteHandler);
				_nes.cpu.assignWriteHandler(addr + 5, scrollWriteHandler);
				_nes.cpu.assignWriteHandler(addr + 6, vramAddrHandler);
				_nes.cpu.assignWriteHandler(addr + 7, vramWriteHandler);
			}
			
			// Direct register writes (4000-4017)
			var apuWriteHandler:int = _nes.cpu.registerHandler(_nes.apu.writeReg);
			for (addr = 0x4000; addr <= 0x4013; addr++)
			{
				_nes.cpu.assignWriteHandler(addr, apuWriteHandler);
			}
			_nes.cpu.assignWriteHandler(0x4014, _nes.cpu.registerHandler(_nes.ppu.writeOAMDMAReg));
			_nes.cpu.assignWriteHandler(0x4015, apuWriteHandler);
			_nes.cpu.assignWriteHandler(0x4016, _nes.cpu.registerHandler(joyWrite));
			_nes.cpu.assignWriteHandler(0x4017, apuWriteHandler);  // TODO: Break out apu write handlers
		}
		
		private function joyWrite(address:uint, value:uint):void
		{
			// Joystick 1 + Strobe
			if ((value&1) === 0 && (_joypadLastWrite&1) === 1) {
				_joy1StrobeState = 0;
				_joy2StrobeState = 0;
			}
			_joypadLastWrite = value;
		}		
		
		
		
		protected function registerLoadHandlers():void
		{
			var addr:uint;
			
			var readZeroHandler:int = _nes.cpu.registerHandler(readZero);
			var readStatusHandler:int = _nes.cpu.registerHandler(_nes.ppu.readStatusRegister);
			var sramLoadHandler:int = _nes.cpu.registerHandler(_nes.ppu.readOamDataReg);
			var vramLoadHandler:int = _nes.cpu.registerHandler(_nes.ppu.readDataReg);
			
			// PPU Register Loads (0x2000-0x3FFF, bitmask 0x2007)
			for (addr = 0x2000; addr < 0x4000; addr += 8)
			{
				// addr+0, addr+1 are stored in local cpu memory (not on actual NES)
				_nes.cpu.assignLoadhandler(addr + 2, readStatusHandler);
				_nes.cpu.assignLoadhandler(addr + 3, readZeroHandler);
				_nes.cpu.assignLoadhandler(addr + 4, sramLoadHandler);
				_nes.cpu.assignLoadhandler(addr + 5, readZeroHandler);
				_nes.cpu.assignLoadhandler(addr + 6, readZeroHandler);
				_nes.cpu.assignLoadhandler(addr + 7, vramLoadHandler);				
			}
				
			// APU/Misc Registers (0x4000-0x4017)
			for (addr = 0x4000; addr <= 0x4014; addr++)
    		{
				_nes.cpu.assignLoadhandler(addr, readZeroHandler);
			}
			_nes.cpu.assignLoadhandler(0x4015, _nes.cpu.registerHandler(_nes.apu.readReg));
			_nes.cpu.assignLoadhandler(0x4016, _nes.cpu.registerHandler(joy1Read));
			_nes.cpu.assignLoadhandler(0x4017, _nes.cpu.registerHandler(joy2Read));
		}
		
		private function readZero(address:uint):uint
		{
			return 0;
		}
				
		private function joy1Read(addr:uint):uint
		{
			var ret:uint;
		
			switch (_joy1StrobeState) {
				case 0:
				case 1:
				case 2:
				case 3:
				case 4:
				case 5:
				case 6:
				case 7:
					ret = _nes.input.state1[_joy1StrobeState];
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
		
			_joy1StrobeState++;
			if (_joy1StrobeState == 24) {
				_joy1StrobeState = 0;
			}
		
			return ret;
		}

		private function joy2Read(addr:uint):uint
		{
			var ret:uint;
		
			switch (_joy2StrobeState) {
				case 0:
				case 1:
				case 2:
				case 3:
				case 4:
				case 5:
				case 6:
				case 7:
					ret = _nes.input.state2[_joy2StrobeState];
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

			_joy2StrobeState++;
			if (_joy2StrobeState == 24) {
				_joy2StrobeState = 0;
			}
		
			return ret;
		}

		public function loadROM():void
		{
			if (!_nes.rom.valid || _nes.rom.romCount < 1) {
				//trace("NoMapper: Invalid ROM! Unable to load.");
				return;
			}
		
			// Load ROM into memory:
			loadPRGROM();
		
			// Load CHR-ROM:
			loadCHRROM();
		
			// Load Battery RAM (if present):
			loadBatteryRam();
		
			// Reset IRQ:
			_nes.cpu.requestIrq(CPU.IRQ_RESET);
		}

		private function loadPRGROM():void
		{
			if (_nes.rom.romCount > 1) {
				// Load the two first banks into memory.
				loadRomBank(0, 0x8000);
				loadRomBank(1, 0xC000);
			}
			else {
				// Load the one bank into both memory locations:
				loadRomBank(0, 0x8000);
				loadRomBank(0, 0xC000);
			}
		}

		protected function loadCHRROM():void
		{
			////System.out.println("Loading CHR ROM..");
			if (_nes.rom.vromCount > 0) {
				if (_nes.rom.vromCount == 1) {
					loadVromBank(0,0x0000);
					loadVromBank(0,0x1000);
				}
				else {
					loadVromBank(0,0x0000);
					loadVromBank(1,0x1000);
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
			trace(this + "loadRomBank: " + bank + " - " + address.toString(16));
			// Loads a ROM bank into the specified address.
			bank %= _nes.rom.romCount;
			
			ArrayUtils.copyArrayElements(_nes.rom.rom[bank], 0, _nes.cpu.mem, address, 16384);
		}

		protected function loadVromBank(bank:uint, address:uint):void
		{
			trace(this + "loadVromBank: " + bank + " - " + address.toString(16));
			if (_nes.rom.vromCount === 0) {
				return;
			}
			_nes.ppu.triggerRendering();
		
			ArrayUtils.copyArrayElements(_nes.rom.vrom[bank % _nes.rom.vromCount], 
				0, _nes.ppu.memory, address, 0x1000);
		}

		protected function load32kRomBank(bank:uint, address:uint):void
		{
			trace(this + "load32kRomBank: " + bank + " - " + address.toString(16));
			loadRomBank((bank*2) % _nes.rom.romCount, address);
			loadRomBank((bank*2+1) % _nes.rom.romCount, address+16384);
		}


		protected function load8kVromBank(bank4kStart:uint, address:uint):void
		{
			trace(this + "load8kVromBank: " + bank4kStart + " - " + address.toString(16));
			if (_nes.rom.vromCount === 0) {
				return;
			}
			_nes.ppu.triggerRendering();

			loadVromBank((bank4kStart) % _nes.rom.vromCount, address);
			loadVromBank((bank4kStart + 1) % _nes.rom.vromCount,
					address + 4096);
		}
		
		protected function load1kVromBank(bank1k:uint, address:uint):void
		{
			trace(this + "load1kVromBank: " + bank1k + " - " + address.toString(16));
			if (_nes.rom.vromCount === 0) {
				return;
			}
			_nes.ppu.triggerRendering();
		
			var bank4k:uint = Math.floor(bank1k / 4) % _nes.rom.vromCount;
			var bankoffset:uint = (bank1k % 4) * 1024;
			ArrayUtils.copyArrayElements(_nes.rom.vrom[bank4k], 0, 
				_nes.ppu.memory, bankoffset, 1024);
		}

		private function load2kVromBank(bank2k:uint, address:uint):void
		{
			trace(this + "load2kVromBank: " + bank2k + " - " + address.toString(16));
			if (_nes.rom.vromCount === 0) {
				return;
			}
			_nes.ppu.triggerRendering();
		
			var bank4k:uint = Math.floor(bank2k / 2) % _nes.rom.vromCount;
			var bankoffset:uint = (bank2k % 2) * 2048;
			ArrayUtils.copyArrayElements(_nes.rom.vrom[bank4k], bankoffset,
				_nes.ppu.memory, address, 2048);
		}
		
		protected function load8kRomBank(bank8k:uint, address:uint):void
		{
			trace(this + "load8kRomBank: " + bank8k + " - " + address.toString(16));
			var bank16k:uint = Math.floor(bank8k / 2) % _nes.rom.romCount;
			var offset:uint = (bank8k % 2) * 8192;
		
			//this.nes.cpu.mem.write(address,this.nes.rom.rom[bank16k],offset,8192);
			ArrayUtils.copyArrayElements(_nes.rom.rom[bank16k], offset, 
					  _nes.cpu.mem, address, 8192);
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