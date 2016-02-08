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
			this.regBuffer = 0;
			this.regBufferCounter = 0;

			// Register 0:
			this.mirroring = 0;
			this.oneScreenMirroring = 0;
			this.prgSwitchingArea = 1;
			this.prgSwitchingSize = 1;
			this.vromSwitchingSize = 0;

			// Register 1:
			this.romSelectionReg0 = 0;

			// Register 2:
			this.romSelectionReg1 = 0;

			// Register 3:
			this.romBankSelect = 0;
		}

		override public function write(address:uint, value:uint):void
		{
			// Writes to addresses other than MMC registers are handled by Mapper0.
			if (address < 0x8000) {
				super.write(address, value);
				return;
			}

			// See what should be done with the written value:
			if ((value & 128) !== 0) {

				// Reset buffering:
				this.regBufferCounter = 0;
				this.regBuffer = 0;
			
				// Reset register:
				if (this.getRegNumber(address) === 0) {
				
					this.prgSwitchingArea = 1;
					this.prgSwitchingSize = 1;
				
				}
			}
			else {
			
				// Continue buffering:
				//regBuffer = (regBuffer & (0xFF-(1<<regBufferCounter))) | ((value & (1<<regBufferCounter))<<regBufferCounter);
				this.regBuffer = (this.regBuffer & (0xFF - (1 << this.regBufferCounter))) | ((value & 1) << this.regBufferCounter);
				this.regBufferCounter++;
				
				if (this.regBufferCounter == 5) {
					// Use the buffered value:
					this.setReg(this.getRegNumber(address), this.regBuffer);
				
					// Reset buffer:
					this.regBuffer = 0;
					this.regBufferCounter = 0;
				}
			}
		}

		private function setReg(reg:uint, value:uint):void
		{
			var tmp:uint;

			switch (reg) {
				case 0:
					// Mirroring:
					tmp = value & 3;
					if (tmp !== this.mirroring) {
						// Set mirroring:
						this.mirroring = tmp;
						if ((this.mirroring & 2) === 0) {
							// SingleScreen mirroring overrides the other setting:
							this.nes.ppu.setMirroring(
								ROM.SINGLESCREEN_MIRRORING);
						}
						// Not overridden by SingleScreen mirroring.
						else if ((this.mirroring & 1) !== 0) {
							this.nes.ppu.setMirroring(
								ROM.HORIZONTAL_MIRRORING
							);
						}
						else {
							this.nes.ppu.setMirroring(ROM.VERTICAL_MIRRORING);
						}
					}
			
					// PRG Switching Area;
					this.prgSwitchingArea = (value >> 2) & 1;
			
					// PRG Switching Size:
					this.prgSwitchingSize = (value >> 3) & 1;
			
					// VROM Switching Size:
					this.vromSwitchingSize = (value >> 4) & 1;
				
					break;
			
				case 1:
					// ROM selection:
					this.romSelectionReg0 = (value >> 4) & 1;
			
					// Check whether the cart has VROM:
					if (this.nes.rom.vromCount > 0) {
				
						// Select VROM bank at 0x0000:
						if (this.vromSwitchingSize === 0) {
				
							// Swap 8kB VROM:
							if (this.romSelectionReg0 === 0) {
								this.load8kVromBank((value & 0xF), 0x0000);
							}
							else {
								this.load8kVromBank(
									Math.floor(this.nes.rom.vromCount / 2) +
										(value & 0xF), 
									0x0000
								);
							}
					
						}
						else {
							// Swap 4kB VROM:
							if (this.romSelectionReg0 === 0) {
								this.loadVromBank((value & 0xF), 0x0000);
							}
							else {
								this.loadVromBank(
									Math.floor(this.nes.rom.vromCount / 2) +
										(value & 0xF),
									0x0000
								);
							}
						}
					}
				
					break;
			
				case 2:
					// ROM selection:
					this.romSelectionReg1 = (value >> 4) & 1;
			
					// Check whether the cart has VROM:
					if (this.nes.rom.vromCount > 0) {
						
						// Select VROM bank at 0x1000:
						if (this.vromSwitchingSize === 1) {
							// Swap 4kB of VROM:
							if (this.romSelectionReg1 === 0) {
								this.loadVromBank((value & 0xF), 0x1000);
							}
							else {
								this.loadVromBank(
									Math.floor(this.nes.rom.vromCount / 2) +
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
			
					if (this.nes.rom.romCount >= 32) {
						// 1024 kB cart
						if (this.vromSwitchingSize === 0) {
							if (this.romSelectionReg0 === 1) {
								baseBank = 16;
							}
						}
						else {
							baseBank = (this.romSelectionReg0 
										| (this.romSelectionReg1 << 1)) << 3;
						}
					}
					else if (this.nes.rom.romCount >= 16) {
						// 512 kB cart
						if (this.romSelectionReg0 === 1) {
							baseBank = 8;
						}
					}
			
					if (this.prgSwitchingSize === 0) {
						// 32kB
						bank = baseBank + (value & 0xF);
						this.load32kRomBank(bank, 0x8000);
					}
					else {
						// 16kB
						bank = baseBank * 2 + (value & 0xF);
						if (this.prgSwitchingArea === 0) {
							this.loadRomBank(bank, 0xC000);
						}
						else {
							this.loadRomBank(bank, 0x8000);
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
			if (!this.nes.rom.valid) {
				trace("MMC1: Invalid ROM! Unable to load.");
				return;
			}

			// Load PRG-ROM:
			this.loadRomBank(0, 0x8000);                         //   First ROM bank..
			this.loadRomBank(this.nes.rom.romCount - 1, 0xC000); // ..and last ROM bank.

			// Load CHR-ROM:
			this.loadCHRROM();

			// Load Battery RAM (if present):
			this.loadBatteryRam();

			// Do Reset-Interrupt:
			this.nes.cpu.requestIrq(CPU.IRQ_RESET);
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