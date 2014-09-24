// TODO: Implement Mirroring and CHR

/**
 * CPU $6000-$7FFF: Family Basic only: PRG RAM, mirrored as necessary to fill entire 8 KiB window, write protectable with an external switch
 * CPU $8000-$BFFF: First 16 KB of ROM.
 * CPU $C000-$FFFF: Last 16 KB of ROM (NROM-256) or mirror of $8000-$BFFF (NROM-128).
**/

package net.johnmercer.nes.system.Mappers 
{
	import flash.utils.*;
	import net.johnmercer.nes.system.*;
	import net.johnmercer.nes.views.*;
	
	public class Mapper0 implements IMapper
	{
		private var _emulator:Emulator;
		
		private var _prgRom:ByteArray;
		private var _prgRomAddr:uint = 0x8000;  // Virtual start position of rom
		private var _prgRomAddrMask:uint = 0xFFFF;
		private var _prgRomOffset:int = 0;
		
		private var _prgRam:ByteArray;
		private var _prgRamAddr:uint = 0x6000;
		private var _prgRamAddrMask:uint = 0xFFFF;
		private var _prgRamOffset:int = 0;

		
		public function Mapper0(emulator:Emulator)
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
			// Ram is aligned 0x6000 to 0x7FFF in the byte array,
			// Exact addressing
			_prgRam.length = 0x10000;
			_prgRamAddr = 0x6000;
			_prgRamOffset = 0;
			
			// Rom is aligned 0x8000 to 0xFFFF.  If Rom is 16 KB,
			// 0xC000 to 0xFFFF is a copy of 0x8000 to 0xBFFF.
			_prgRom.length = 0x10000;
			_prgRomAddr = 0x8000;
			_prgRomOffset = 0;
			
			rom.prgRom.position = 0;
			rom.prgRom.readBytes(_prgRom, 0x8000, rom.prgRom.length);
			
			// Duplicate rom contents to 0xC000-0xFFFF if only 16KB
			if (rom.prgRom.length <= 0x4000)
			{
				rom.prgRom.position = 0;
				rom.prgRom.readBytes(_prgRom, 0xC000, rom.prgRom.length);
			}
			
			_emulator.log("Mapper 0 configured");
		}
		
		// PRG ROM Access
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
		
		public function readPrgRomUnsignedByte(addr:uint):uint
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
		
		public function readPrgRomUnsignedWord(addr:uint):uint
		{
			if (addr != _prgRomAddr)
			{
				_prgRomAddr = addr;
				_prgRom.position = _prgRomAddr;
			}
			_prgRomAddr += 2;
			return _prgRom.readUnsignedShort();
		}
		
		public function writePrgRomByte(addr:uint, value:uint):void
		{
			// no writeable area for the rom on this mapper
			return;
		}
				
		// PRG RAM Access
		public function readPrgRamByte(addr:uint):int
		{
			if (addr != _prgRamAddr)
			{
				_prgRamAddr = addr;
				_prgRam.position = _prgRamAddr;
			}
			_prgRamAddr++;
			return _prgRam.readByte();			
		}
		
		public function readPrgRamUnsignedByte(addr:uint):uint
		{
			if (addr != _prgRamAddr)
			{
				_prgRamAddr = addr;
				_prgRam.position = _prgRamAddr;
			}
			_prgRamAddr++;
			return _prgRam.readUnsignedByte();			
		}
		
		public function readPrgRamWord(addr:uint):int
		{
			if (addr != _prgRamAddr)
			{
				_prgRamAddr = addr;
				_prgRam.position = _prgRamAddr;
			}
			_prgRamAddr += 2;
			return _prgRam.readShort();
		}
		
		public function readPrgRamUnsignedWord(addr:uint):uint
		{
			if (addr != _prgRamAddr)
			{
				_prgRamAddr = addr;
				_prgRam.position = _prgRamAddr;
			}
			_prgRamAddr += 2;
			return _prgRam.readUnsignedShort();
		}
	
		public function writePrgRamByte(addr:uint, value:uint):void
		{
			if (addr != _prgRamAddr)
			{
				_prgRamAddr = addr;
				_prgRam.position = _prgRamAddr;
			}
			_prgRam.writeUnsignedInt(value);
			_prgRamAddr++;
		}
	}

}