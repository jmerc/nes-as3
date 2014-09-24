package net.johnmercer.nes.tests.instrtestv4
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import net.johnmercer.nes.system.CPU;
	import net.johnmercer.nes.system.Mapper;
	import net.johnmercer.nes.system.ROM;
	import net.johnmercer.nes.tests.CPUState;
	import net.johnmercer.nes.views.Emulator;
	import net.johnmercer.nes.tests.interfaces.ITest;
	
	/**
	 * ...
	 * @author ...
	 */
	public class InstrTestV4 implements ITest
	{
		private const START_ADDR:uint = 0x0000;
		
		[Embed(source="all_instrs.nes",mimeType="application/octet-stream")]
		private static var TestRom:Class;
		private var _testRom:ByteArray = new TestRom() as ByteArray;
		
		private var _emulator:Emulator;
		private var _cpu:CPU;
		private var _currentLine:uint = 0;
		private var _logState:CPUState;
		private var _cpuState:CPUState;
		private var _debugStr:String = "";
		
		public function InstrTestV4(emulator:Emulator)
		{
			_emulator = emulator;
		}
		
		public function startTest(cpu:CPU, rom:ROM, mapper:Mapper):void
		{
			_cpu = cpu;
			_currentLine = 0;
			_debugStr = "";
			
			// Load ROM
			rom.loadByteArray(_testRom);
			if (rom.validFile == false)
			{
				return;
			}
			mapper.loadRom(rom);
			
			_cpu.start(START_ADDR);
			
			_emulator.enableMouseStep();
		}
	
	}

}