package net.johnmercer.nes.tests.instrtestv5
{
	import flash.events.*;
	import flash.utils.*;
	import net.johnmercer.nes.system.*;
	import net.johnmercer.nes.system.Mappers.*;
	import net.johnmercer.nes.tests.*;
	import net.johnmercer.nes.tests.interfaces.*;
	import net.johnmercer.nes.views.*;
	
	/**
	 * ...
	 * @author ...
	 */
	public class InstrTestV5 implements ITest
	{
		private const START_ADDR:uint = 0xFFFC;  // Reset vector location
		
		//[Embed(source="all_instrs.nes",mimeType="application/octet-stream")]
		[Embed(source="official_only.nes",mimeType="application/octet-stream")]		
		//[Embed(source="rom_singles\\01-basics.nes",mimeType="application/octet-stream")]		
		private static var TestRom:Class;
		private var _testRom:ByteArray = new TestRom() as ByteArray;
		
		private var _emulator:Emulator;
		private var _cpu:CPU;
		private var _mapper:IMapper;
		private var _currentLine:uint = 0;
		private var _logState:CPUState;
		private var _cpuState:CPUState;
		private var _debugStr:String = "";
		private var _testPaused:Boolean = false;
		private var _testStarted:Boolean = false;
		
		public function InstrTestV5(emulator:Emulator)
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
			_mapper = MapperService.getMapper(_emulator, rom);
			_cpu.mapper = _mapper;
			
			_cpu.start(START_ADDR);
			
			_emulator.addEventListener(MouseEvent.CLICK, onMouseClick);
			_emulator.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		private function onMouseClick(e:Event):void
		{
			if (_testPaused == false)
			{
				_testPaused = true;
				stopTest("Paused (" + _mapper.readPrgRamUnsignedByte(0x6000) + "): " + getTestResult());
			}
			else
			{
				_testPaused = false;				
				_emulator.addEventListener(Event.ENTER_FRAME, onEnterFrame);				
			}
		
		}
		
		private function onEnterFrame(e:Event):void
		{
			runTest(25);
		}
		
		
		private function runTest(time:uint):void
		{
			var endTime:uint = getTimer() + time;
			var testResult:uint;
			while (getTimer() < endTime)
			{
				_cpu.execute();
				_cpuState = _cpu.state;
				
				_debugStr = _cpuState.toString() + " " + CPU.INST_NAME[_cpuState.opcode] + "_" + CPU.ADDR_NAME[CPU.INST_ADDR_MODE[_cpuState.opcode]];
				
				// Output debug string
				_emulator.log(_debugStr);
				
				// Test status is stored in $6000
				testResult = _mapper.readPrgRamUnsignedByte(0x6000);
				if (testResult == 0x80 && _testStarted == false)
				{
					_testStarted = true;
				}
				else if (testResult != 0x80 && _testStarted == true)
				{				
					stopTest("End of test (" + testResult + "):\n" + getTestResult());
					return;
				}
				
				if (_cpu.state.error == true)
				{
					stopTest("CPU Error at line: " + _currentLine);
					return;
				}
			}
		}
		
		private function getTestResult():String
		{
			var testResult:String = "";
			// Grab result string from 6004 to '\0x00'
			var char:uint = 0xFF;
			var ptr:uint = 0x6004;
			while (char != 0x00)
			{
				char = _mapper.readPrgRamUnsignedByte(ptr++);
				testResult += String.fromCharCode(char);
			}
			return testResult;
		}
		
		public function stopTest(message:String):void
		{
			_emulator.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			_emulator.log(message);
		}
		
	}

}