package system.Mappers 
{
	import interfaces.IMapper;
	import system.CPU;
	import system.NES;
	import system.ROM;
	/**
	 * ...
	 * @author John
	 */
	public class Mapper4 extends Mapper0
	{
		private static const CMD_SEL_2_1K_VROM_0000:uint = 0;
		private static const CMD_SEL_2_1K_VROM_0800:uint = 1;
		private static const CMD_SEL_1K_VROM_1000:uint = 2;
		private static const CMD_SEL_1K_VROM_1400:uint = 3;
		private static const CMD_SEL_1K_VROM_1800:uint = 4;
		private static const CMD_SEL_1K_VROM_1C00:uint = 5;
		private static const CMD_SEL_ROM_PAGE1:uint = 6;
		private static const CMD_SEL_ROM_PAGE2:uint = 7;
		
		private var command:uint;
		private var prgAddressSelect:uint;
		private var chrAddressSelect:uint;
		private var pageNumber:uint;
		private var irqCounter:uint;
		private var irqLatchValue:uint;
		private var irqEnable:uint;
		private var prgAddressChanged:Boolean;

		public function Mapper4(nes:NES)
		{
			super(nes);
			
			this.command = 0;
			this.prgAddressSelect = 0;
			this.chrAddressSelect = 0;
			this.pageNumber = 0;
			this.irqCounter = 0;
			this.irqLatchValue = 0;
			this.irqEnable = 0;
			this.prgAddressChanged = false;
		}
		
		override protected function registerWriteHandlers():void
		{
			super.registerWriteHandlers();
			
			var mmcRegWritehandler:int = _nes.cpu.registerHandler(mmcRegWrite);
			for (var addr:int = 0x8000; addr < 0x10000; addr++)
			{
				_nes.cpu.writeHandlers[addr] = mmcRegWritehandler;
			}
		}
		
		
	
		private function mmcRegWrite(address:uint, value:uint):void
		{
			switch (address) {
				case 0x8000:
					// Command/Address Select register
					this.command = value & 7;
					var tmp:uint = (value >> 6) & 1;
					if (tmp != this.prgAddressSelect) {
						this.prgAddressChanged = true;
					}
					this.prgAddressSelect = tmp;
					this.chrAddressSelect = (value >> 7) & 1;
					break;
			
				case 0x8001:
					// Page number for command
					this.executeCommand(this.command, value);
					break;
			
				case 0xA000:        
					// Mirroring select
					if ((value & 1) !== 0) {
						this._nes.ppu.setMirroring(
							ROM.HORIZONTAL_MIRRORING
						);
					}
					else {
						this._nes.ppu.setMirroring(ROM.VERTICAL_MIRRORING);
					}
					break;
				
				case 0xA001:
					// SaveRAM Toggle
					// TODO
					//nes.getRom().setSaveState((value&1)!=0);
					break;
			
				case 0xC000:
					// IRQ Counter register
					this.irqCounter = value;
					//nes.ppu.mapperIrqCounter = 0;
					break;
			
				case 0xC001:
					// IRQ Latch register
					this.irqLatchValue = value;
					break;
			
				case 0xE000:
					// IRQ Control Reg 0 (disable)
					//irqCounter = irqLatchValue;
					this.irqEnable = 0;
					break;
			
				case 0xE001:        
					// IRQ Control Reg 1 (enable)
					this.irqEnable = 1;
					break;
			
				default:
					// Not a MMC3 register.
					// The game has probably crashed,
					// since it tries to write to ROM..
					// IGNORE.
			}
		}

		private function executeCommand(cmd:uint, arg:uint):void
		{
			switch (cmd) {
				case CMD_SEL_2_1K_VROM_0000:
					// Select 2 1KB VROM pages at 0x0000:
					if (this.chrAddressSelect === 0) {
						this.load1kVromBank(arg, 0x0000);
						this.load1kVromBank(arg + 1, 0x0400);
					}
					else {
						this.load1kVromBank(arg, 0x1000);
						this.load1kVromBank(arg + 1, 0x1400);
					}
					break;
				
				case CMD_SEL_2_1K_VROM_0800:           
					// Select 2 1KB VROM pages at 0x0800:
					if (this.chrAddressSelect === 0) {
						this.load1kVromBank(arg, 0x0800);
						this.load1kVromBank(arg + 1, 0x0C00);
					}
					else {
						this.load1kVromBank(arg, 0x1800);
						this.load1kVromBank(arg + 1, 0x1C00);
					}
					break;
			
				case CMD_SEL_1K_VROM_1000:         
					// Select 1K VROM Page at 0x1000:
					if (this.chrAddressSelect === 0) {
						this.load1kVromBank(arg, 0x1000);
					}
					else {
						this.load1kVromBank(arg, 0x0000);
					}
					break;
			
				case CMD_SEL_1K_VROM_1400:         
					// Select 1K VROM Page at 0x1400:
					if (this.chrAddressSelect === 0) {
						this.load1kVromBank(arg, 0x1400);
					}
					else {
						this.load1kVromBank(arg, 0x0400);
					}
					break;
			
				case CMD_SEL_1K_VROM_1800:
					// Select 1K VROM Page at 0x1800:
					if (this.chrAddressSelect === 0) {
						this.load1kVromBank(arg, 0x1800);
					}
					else {
						this.load1kVromBank(arg, 0x0800);
					}
					break;
			
				case CMD_SEL_1K_VROM_1C00:
					// Select 1K VROM Page at 0x1C00:
					if (this.chrAddressSelect === 0) {
						this.load1kVromBank(arg, 0x1C00);
					}else {
						this.load1kVromBank(arg, 0x0C00);
					}
					break;
			
				case CMD_SEL_ROM_PAGE1:
					if (this.prgAddressChanged) {
						// Load the two hardwired banks:
						if (this.prgAddressSelect === 0) { 
							this.load8kRomBank(
								((this._nes.rom.romCount - 1) * 2),
								0xC000
							);
						}
						else {
							this.load8kRomBank(
								((this._nes.rom.romCount - 1) * 2),
								0x8000
							);
						}
						this.prgAddressChanged = false;
					}
			
					// Select first switchable ROM page:
					if (this.prgAddressSelect === 0) {
						this.load8kRomBank(arg, 0x8000);
					}
					else {
						this.load8kRomBank(arg, 0xC000);
					}
					break;
				
				case CMD_SEL_ROM_PAGE2:
					// Select second switchable ROM page:
					this.load8kRomBank(arg, 0xA000);
			
					// hardwire appropriate bank:
					if (this.prgAddressChanged) {
						// Load the two hardwired banks:
						if (this.prgAddressSelect === 0) { 
							this.load8kRomBank(
								((this._nes.rom.romCount - 1) * 2),
								0xC000
							);
						}
						else {              
							this.load8kRomBank(
								((this._nes.rom.romCount - 1) * 2),
								0x8000
							);
						}
						this.prgAddressChanged = false;
					}
			}
		}

		override public function loadROM():void
		{
			if (!this._nes.rom.valid) {
				trace("MMC3: Invalid ROM! Unable to load.");
				return;
			}

			// Load hardwired PRG banks (0xC000 and 0xE000):
			this.load8kRomBank(((this._nes.rom.romCount - 1) * 2), 0xC000);
			this.load8kRomBank(((this._nes.rom.romCount - 1) * 2) + 1, 0xE000);

			// Load swappable PRG banks (0x8000 and 0xA000):
			this.load8kRomBank(0, 0x8000);
			this.load8kRomBank(1, 0xA000);

			// Load CHR-ROM:
			this.loadCHRROM();

			// Load Battery RAM (if present):
			this.loadBatteryRam();

			// Do Reset-Interrupt:
			this._nes.cpu.requestIrq(CPU.IRQ_RESET);
		}

		override public function clockIrqCounter():void
		{
			if (this.irqEnable == 1) {
				this.irqCounter--;
				if (this.irqCounter < 0) {
					// Trigger IRQ:
					this._nes.cpu.requestIrq(CPU.IRQ_NORMAL);
					this.irqCounter = this.irqLatchValue;
				}
			}
		};
	}

}