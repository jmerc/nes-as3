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
		private var _prgRomAddr:uint = 0x8000;
		
		private var _mapperID:uint = 0;
		private var _addrMask:uint = 0xFFFF;
		
		public function Mapper(emulator:Emulator) 
		{
			_emulator = emulator;
			_prgRom = new ByteArray();
			_prgRom.length = 0x10000;
			_prgRom.endian = Endian.LITTLE_ENDIAN;
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
		
		private function setupMapper0(rom:ROM):void
		{
			rom.prgRom.position = 0;
			rom.prgRom.readBytes(_prgRom, 0x8000, rom.prgRom.length);
			
			if (rom.prgRom.length == 16384)
			{
				_addrMask = 0xBFFF;
			}
			_prgRom.position = 0x8000;
			_prgRomAddr = 0x8000;
			_emulator.log(Debug.dumpByteArray(_prgRom, _prgRomAddr, 16));
		}
		
		public function readByte(addr:uint):int
		{
			addr &= _addrMask;
			if (addr != _prgRomAddr)
			{
				_prgRomAddr = addr;
				_prgRom.position = _prgRomAddr;
			}
			_prgRomAddr++;
			return _prgRom.readByte();			
		}
		
		public function readUnsignedByte(addr:uint):int
		{
			addr &= _addrMask;
			if (addr != _prgRomAddr)
			{
				_prgRomAddr = addr;
				_prgRom.position = _prgRomAddr;
			}
			_prgRomAddr++;
			return _prgRom.readUnsignedByte();			
		}
		public function readWord(addr:uint):int
		{
			addr &= _addrMask;
			if (addr != _prgRomAddr)
			{
				_prgRomAddr = addr;
				_prgRom.position = _prgRomAddr;
			}
			_prgRomAddr += 2;
			return _prgRom.readShort();
		}
		
		public function readUnsignedWord(addr:uint):int
		{
			addr &= _addrMask;
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