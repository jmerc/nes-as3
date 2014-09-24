package net.johnmercer.nes.system 
{
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import net.johnmercer.nes.utils.Debug;
	import net.johnmercer.nes.views.Emulator;
	/**
	 * ...
	 * @author John Owen Mercer
	 */
	public class Mapper 
	{
		private var _emulator:Emulator;
		private var _prgRom:ByteArray;
		private var _prgRam:ByteArray;
		private var _prgRomAddr:uint = 0x8000;
		
		private var _mapperID:uint = 0;
		private var _addrMask:uint = 0xFFFF;
		
		public function Mapper(emulator:Emulator) 
		{
			_emulator = emulator;
			_prgRom = new ByteArray();
			_prgRom.length = 0x10000;
			_prgRom.endian = Endian.LITTLE_ENDIAN;
			
			_prgRam = new ByteArray();
			_prgRam.length = 0x10000;
			_prgRam.endian = Endian.LITTLE_ENDIAN;
		}
		
		public function loadRom(rom:ROM):void
		{
			_mapperID = rom.mapper;
			switch(_mapperID)
			{
				case 0:
					setupMapper0(rom);
					break;
				default:
					_emulator.log("ROM has unknown Mapper: " + _mapperID);
					break;
			}
		}
		
		/**
		 * CPU $6000-$7FFF: Family Basic only: PRG RAM, mirrored as necessary to fill entire 8 KiB window, write protectable with an external switch
		 * CPU $8000-$BFFF: First 16 KB of ROM.
		 * CPU $C000-$FFFF: Last 16 KB of ROM (NROM-256) or mirror of $8000-$BFFF (NROM-128).
		 * @param	rom
		 */
		private function setupMapper0(rom:ROM):void
		{
			rom.prgRom.position = 0;
			rom.prgRom.readBytes(_prgRom, 0x8000, rom.prgRom.length);
			
			rom.prgRom.position = 0;
			rom.prgRom.readBytes(_prgRom, 0x8000, rom.prgRom.length);

			_prgRom.position = 0x8000;
			_prgRomAddr = 0x8000;
			_emulator.log(Debug.dumpByteArray(_prgRom, _prgRomAddr, 16));
		}
		
		// PRG Rom Access
		public function readPrgRomByte(addr:uint):int
		{
			if (addr != _prgRomAddr)
			{
				_prgRomAddr = addr;
				_prgRom.position = _prgRomAddr;
			}
			_prgRomAddr++;
			return _prgRom.readByte();			
		}
		
		public function readPrgRomUnsignedByte(addr:uint):int
		{
			if (addr != _prgRomAddr)
			{
				_prgRomAddr = addr;
				_prgRom.position = _prgRomAddr;
			}
			_prgRomAddr++;
			return _prgRom.readUnsignedByte();			
		}
		
		public function readPrgRomWord(addr:uint):int
		{
			if (addr != _prgRomAddr)
			{
				_prgRomAddr = addr;
				_prgRom.position = _prgRomAddr;
			}
			_prgRomAddr += 2;
			return _prgRom.readShort();
		}
		
		public function readPrgRomUnsignedWord(addr:uint):int
		{
			if (addr != _prgRomAddr)
			{
				_prgRomAddr = addr;
				_prgRom.position = _prgRomAddr;
			}
			_prgRomAddr += 2;
			return _prgRom.readUnsignedShort();
		}
		
	}

}