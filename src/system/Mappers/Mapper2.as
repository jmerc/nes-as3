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
			
		override protected function registerWriteHandlers():void
		{
			super.registerWriteHandlers();
			
			var mmcRegWriteHandler:int = _nes.cpu.registerHandler(mmcRegWrite);
			for (var addr:uint = 0x8000; addr < 0x10000; addr++)
			{
				_nes.cpu.writeHandlers[addr] = mmcRegWriteHandler;
			}
		}

		private function mmcRegWrite(address:uint, value:uint):void
		{
			// This is a ROM bank select command.
			// Swap in the given ROM bank at 0x8000:
			this.loadRomBank(value, 0x8000);
		}
		
		override public function loadROM():void
		{
			if (!this._nes.rom.valid) {
				trace("UNROM: Invalid ROM! Unable to load.");
				return;
			}

			// Load PRG-ROM:
			this.loadRomBank(0, 0x8000);
			this.loadRomBank(this._nes.rom.romCount - 1, 0xC000);

			// Load CHR-ROM:
			this.loadCHRROM();

			// Do Reset-Interrupt:
			this._nes.cpu.requestIrq(CPU.IRQ_RESET);
		}

		
	}

}