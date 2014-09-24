package net.johnmercer.nes.tests.instrtestv4
{
	import flash.events.*;
	import flash.utils.*;
	import net.johnmercer.nes.system.*;
	import net.johnmercer.nes.tests.*;
	import net.johnmercer.nes.tests.interfaces.*;
	import net.johnmercer.nes.views.*;
	
	/**
	 * ...
	 * @author ...
	 */
	public class InstrTestV4 implements ITest
	{
		private const START_ADDR:uint = 0xFFFC;  // Reset vector location
		
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
		
		public function startTest(cpu:CPU, rom:ROM):void
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
			_cpu.mapper = MapperService.getMapper(_emulator, rom);
			
			_cpu.start(START_ADDR);
			
			_emulator.addEventListener(MouseEvent.CLICK, onMouseClick);
		}
		
		private function onMouseClick(e:Event):void
		{
			_cpu.execute();
			_cpuState = _cpu.state;
			
			_debugStr = _cpuState.toString() + " " + CPU.INST_NAME[_cpuState.opcode] + "_" + CPU.ADDR_NAME[CPU.INST_ADDR_MODE[_cpuState.opcode]];
			_emulator.log(_debugStr);
		
		}
	
	}

}