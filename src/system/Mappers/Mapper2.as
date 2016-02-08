package system.Mappers 
{
	import interfaces.IMapper;
	import system.CPU;
	import system.NES;
	/**
	 * ...
	 * @author John
	 */
	public class Mapper2 extends Mapper0
	{
		public function Mapper2(nes:NES)
		{
			super(nes);
		}

		override public function write(address:uint, value:uint):void
		{
			// Writes to addresses other than MMC registers are handled by NoMapper.
			if (address < 0x8000) {
				super.write(address, value);
				return;
			}

			else {
				// This is a ROM bank select command.
				// Swap in the given ROM bank at 0x8000:
				this.loadRomBank(value, 0x8000);
			}
		}

		override public function loadROM():void
		{
			if (!this.nes.rom.valid) {
				trace("UNROM: Invalid ROM! Unable to load.");
				return;
			}

			// Load PRG-ROM:
			this.loadRomBank(0, 0x8000);
			this.loadRomBank(this.nes.rom.romCount - 1, 0xC000);

			// Load CHR-ROM:
			this.loadCHRROM();

			// Do Reset-Interrupt:
			this.nes.cpu.requestIrq(CPU.IRQ_RESET);
		}

		
	}

}