package system.Mappers 
{
	import system.*;
	/**
	 * ...
	 * @author John
	 */
	public class Mapper1 extends Mapper0
	{
		// 5-big buffer
		private var regBuffer:uint;
		private var regBufferCounter:uint;
		
		// Register 0
		private var mirroring:uint;
		private var oneScreenMirroring:uint;
		private var prgSwitchingArea:uint;
		private var prgSwitchingSize:uint;
		private var vromSwitchingSize:uint;
		
		// Register 1
		private var romSelectionReg0:uint;
		
		// Register 2
		private var romSelectionReg1:uint;
		
		// Register 3
		private var romBankSelect:uint = 0;
		
		
		public function Mapper1(nes:NES)
		{
			super(nes);
		}

		override public function reset():void
		{
			super.reset();
				
			// 5-bit buffer:
			regBuffer = 0;
			regBufferCounter = 0;

			// Register 0:
			mirroring = 0;
			oneScreenMirroring = 0;
			prgSwitchingArea = 1;
			prgSwitchingSize = 1;
			vromSwitchingSize = 0;

			// Register 1:
			romSelectionReg0 = 0;

			// Register 2:
			romSelectionReg1 = 0;

			// Register 3:
			romBankSelect = 0;
		}
		
		override protected function registerWriteHandlers():void
		{
			super.registerWriteHandlers();
			
			var mmcRegWriteHandler:int = _nes.cpu.registerHandler(mmcRegWrite);
			for (var addr:uint = 0x8000; addr < 0x10000; addr++)
			{
				_nes.cpu.assignWriteHandler(addr, mmcRegWriteHandler);
			}
		}

		private function mmcRegWrite(address:uint, value:uint):void
		{
			// See what should be done with the written value:
			if ((value & 128) !== 0) {

				// Reset buffering:
				regBufferCounter = 0;
				regBuffer = 0;
			
				// Reset register:
				if (getRegNumber(address) === 0) {
				
					prgSwitchingArea = 1;
					prgSwitchingSize = 1;
				
				}
			}
			else {
			
				// Continue buffering:
				//regBuffer = (regBuffer & (0xFF-(1<<regBufferCounter))) | ((value & (1<<regBufferCounter))<<regBufferCounter);
				regBuffer = (regBuffer & (0xFF - (1 << regBufferCounter))) | ((value & 1) << regBufferCounter);
				regBufferCounter++;
				
				if (regBufferCounter == 5) {
					// Use the buffered value:
					setReg(getRegNumber(address), regBuffer);
				
					// Reset buffer:
					regBuffer = 0;
					regBufferCounter = 0;
				}
			}
		}

		
		private function setReg(reg:uint, value:uint):void
		{
			var tmp:int;

			switch (reg) {
				case 0:
					// Mirroring:
					tmp = value & 3;
					// Set mirroring:
					mirroring = tmp;
					if ((mirroring & 2) === 0) {
						// SingleScreen mirroring overrides the other setting:
						_nes.ppu.setMirroring(
							ROM.SINGLESCREEN_MIRRORING);
					}
					// Not overridden by SingleScreen mirroring.
					else if ((mirroring & 1) !== 0) {
						_nes.ppu.setMirroring(
							ROM.HORIZONTAL_MIRRORING
						);
					}
					else {
						_nes.ppu.setMirroring(ROM.VERTICAL_MIRRORING);
					}
			
					// PRG Switching Area;
					prgSwitchingArea = (value >> 2) & 1;
			
					// PRG Switching Size:
					prgSwitchingSize = (value >> 3) & 1;
			
					// VROM Switching Size:
					vromSwitchingSize = (value >> 4) & 1;
				
					break;
			
				case 1:
					// ROM selection:
					romSelectionReg0 = (value >> 4) & 1;
			
					// Check whether the cart has VROM:
					if (_nes.rom.vromCount > 0) {
				
						// Select VROM bank at 0x0000:
						if (vromSwitchingSize === 0) {
				
							// Swap 8kB VROM:
							if (romSelectionReg0 === 0) {
								load8kVromBank((value & 0xF), 0x0000);
							}
							else {
								load8kVromBank(
									Math.floor(_nes.rom.vromCount / 2) +
										(value & 0xF), 
									0x0000
								);
							}
					
						}
						else {
							// Swap 4kB VROM:
							if (romSelectionReg0 === 0) {
								loadVromBank((value & 0xF), 0x0000);
							}
							else {
								loadVromBank(
									Math.floor(_nes.rom.vromCount / 2) +
										(value & 0xF),
									0x0000
								);
							}
						}
					}
				
					break;
			
				case 2:
					// ROM selection:
					romSelectionReg1 = (value >> 4) & 1;
			
					// Check whether the cart has VROM:
					if (_nes.rom.vromCount > 0) {
						
						// Select VROM bank at 0x1000:
						if (vromSwitchingSize === 1) {
							// Swap 4kB of VROM:
							if (romSelectionReg1 === 0) {
								loadVromBank((value & 0xF), 0x1000);
							}
							else {
								loadVromBank(
									Math.floor(_nes.rom.vromCount / 2) +
										(value & 0xF),
									0x1000
								);
							}
						}
					}
					break;
			
				default:
					// Select ROM bank:
					// -------------------------
					tmp = value & 0xF;
					var bank:uint;
					var baseBank:uint = 0;
			
					if (_nes.rom.romCount >= 32) {
						// 1024 kB cart
						if (vromSwitchingSize === 0) {
							if (romSelectionReg0 === 1) {
								baseBank = 16;
							}
						}
						else {
							baseBank = (romSelectionReg0 
										| (romSelectionReg1 << 1)) << 3;
						}
					}
					else if (_nes.rom.romCount >= 16) {
						// 512 kB cart
						if (romSelectionReg0 === 1) {
							baseBank = 8;
						}
					}
			
					if (prgSwitchingSize === 0) {
						// 32kB
						bank = baseBank + (value & 0xF);
						load32kRomBank(bank, 0x8000);
					}
					else {
						// 16kB
						bank = baseBank * 2 + (value & 0xF);
						if (prgSwitchingArea === 0) {
							loadRomBank(bank, 0xC000);
						}
						else {
							loadRomBank(bank, 0x8000);
						}
					}  
			}
		}

		// Returns the register number from the address written to:
		private function getRegNumber(address:uint):uint
		{
			if (address >= 0x8000 && address <= 0x9FFF) {
				return 0;
			}
			else if (address >= 0xA000 && address <= 0xBFFF) {
				return 1;
			}
			else if (address >= 0xC000 && address <= 0xDFFF) {
				return 2;
			}
			else {
				return 3;
			}
		}

		override public function loadROM():void
		{
			if (!_nes.rom.valid) {
				return;
			}

			// Load PRG-ROM:
			loadRomBank(0, 0x8000);                         //   First ROM bank..
			loadRomBank(_nes.rom.romCount - 1, 0xC000); // ..and last ROM bank.

			// Load CHR-ROM:
			loadCHRROM();

			// Load Battery RAM (if present):
			loadBatteryRam();

			// Do Reset-Interrupt:
			_nes.cpu.requestIrq(CPU.IRQ_RESET);
		}
		
		private function switchLowHighPrgRom(oldSetting:uint):void
		{
			// not yet.
		}

		private function switch16to32():void
		{
			// not yet.
		}

		private function swithc32to16():void
		{
			// not yet.
		}

	}

}