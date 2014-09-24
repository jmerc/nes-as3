// TODO: Check word reads across boundary (address 0xBFFF)
// Implement CHR Mapping
// Implement WRAM
// Implement Mirroring

package net.johnmercer.nes.system.Mappers 
{
	import flash.utils.*;
	import net.johnmercer.nes.system.*;
	import net.johnmercer.nes.views.*;
	
	public class Mapper1 implements IMapper
	{
		private var _emulator:Emulator;
		
		private var _prgRom:ByteArray;
		private var _prgRomAddr:uint = 0x8000;  // Virtual start position of rom
		private var _prgRomAddrMask:uint = 0x7FFF;
		private var _prgRomOffsetL:uint = 0x0000;
		private var _prgRomOffsetH:uint = 0x0000;
		
		private var _prgRam:ByteArray;
		private var _prgRamAddr:uint = 0x6000;
		private var _prgRamAddrMask:uint = 0xFFFF;
		private var _prgRamOffset:int = 0;
		
		private var _mmcTempValue:uint = 0;
		private var _mmcTempCnt:uint = 0;
		
		private var _mmcConfigReg:uint = 0;
		private var _mmcReg0:uint = 0;
		private var _mmcReg1:uint = 0;
		private var _mmcReg2:uint = 0;
		
		
		public function Mapper1(emulator:Emulator)
		{
			_emulator = emulator;
			
			_prgRom = new ByteArray();
			_prgRom.endian = Endian.LITTLE_ENDIAN;
			
			_prgRam = new ByteArray();
			_prgRam.length = 0x10000;
			_prgRam.endian = Endian.LITTLE_ENDIAN;
		}
		
		/**
		 * Mapper 1: prgRom is maped:
		 *	 PRG Setup:
		 *	 --------------------------
		 *	 There is 1 PRG reg and 3 PRG modes.
		 *	 
		 *					$8000   $A000   $C000   $E000
		 *				  +-------------------------------+
		 *	 P=0:         |            <$E000>            |
		 *				  +-------------------------------+
		 *	 P=1, S=0:    |     { 0 }     |     $E000     |
		 *				  +---------------+---------------+
		 *	 P=1, S=1:    |     $E000     |     {$0F}     |
		 *				  +---------------+---------------+
		 * @param	rom
		 */
		public function loadRom(rom:ROM):void
		{
			_mmcConfigReg = 0x0C;
			_mmcReg0 = 0;
			_mmcReg1 = 0;
			_mmcReg2 = 0x10;  // Todo: find out what wram is and implement it
			
			_prgRom = rom.prgRom;
			_prgRom.position = 0;
			_prgRomAddr = 0;
			_prgRomAddrMask = 0x7FFF;
			setupPrgRomOffsets();
			_emulator.log("Mapper 1 configured");
		}
		
		private function setupPrgRomOffsets():void
		{
			var prgSize:uint = 0;
			var prgSlot:uint = 0;
			var prgReg:uint;
			
			if (_mmcConfigReg & 0x8)			
				prgSize = 1;
			if (_mmcConfigReg & 0x4)
				prgSlot = 1;
			prgReg = _mmcReg2 & 0xF;
			
			if (prgSize == 0)  // 32K mode
			{
				_prgRomOffsetL = prgReg * 0x4000;
				_prgRomOffsetH = _prgRomOffsetL + 0x4000;
			}
			else
			{
				if (prgSlot == 0)  // 0x8000 fixed to page $00
				{
					_prgRomOffsetL = 0;
					_prgRomOffsetH = prgReg * 0x4000;
				}
				else  // 0xC000 fixed to page $0F
				{
					_prgRomOffsetL = prgReg * 0x4000;
					_prgRomOffsetH = 0x3C000;
				}
			}
		}
		
		// PRG ROM Access
		public function readPrgRomByte(addr:uint):int
		{
			addr &= 0x7FFF;
			if (addr & 0x4000)  // 0xC000 Block
			{
				addr &= 0x3FFF;
				addr += _prgRomOffsetH;
			}
			else
			{
				addr += _prgRomOffsetL;
			}
			
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
			addr &= 0x7FFF;
			if (addr & 0x4000)  // 0xC000 Block
			{
				addr &= 0x3FFF;
				addr += _prgRomOffsetH;
			}
			else
			{
				addr += _prgRomOffsetL;
			}
			
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
			addr &= 0x7FFF;
			if (addr & 0x4000)  // 0xC000 Block
			{
				addr &= 0x3FFF;
				addr += _prgRomOffsetH;
			}
			else
			{
				addr += _prgRomOffsetL;
			}
			
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
			addr &= 0x7FFF;
			if (addr & 0x4000)  // 0xC000 Block
			{
				addr &= 0x3FFF;
				addr += _prgRomOffsetH;
			}
			else
			{
				addr += _prgRomOffsetL;
			}
			
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
			if (value & 0x80)
			{
				_mmcTempCnt = 0;
				_mmcTempValue = 0;
				// enable bits 2, 3 of register $8000
				_mmcConfigReg |= 0xC;				
			}
			else
			{
				// write temp value to address on every 5th write
				_mmcTempValue = (_mmcTempValue << 1) | (value & 0x01);
				if (_mmcTempCnt < 4)
				{
					_mmcTempCnt++;
				}
				else
				{
					// Handle write to register
					switch(addr & 0x6000)
					{
						case 0x0000:
							_mmcConfigReg = _mmcTempValue;
							break;
						case 0x2000:
							_mmcReg0 = _mmcTempValue;
							break;
						case 0x4000:
							_mmcReg1 = _mmcTempValue;
							break;
						case 0x6000:
							_mmcReg2 = _mmcTempValue;
							break;
						default:
							break;
					}
					// Clear MMC temp register
					_mmcTempCnt = 0;
					_mmcTempValue = 0;
					// Act on write to register
					setupPrgRomOffsets();
				}
			}
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