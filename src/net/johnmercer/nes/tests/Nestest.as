package net.johnmercer.nes.tests 
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import net.johnmercer.nes.system.CPU;
	import net.johnmercer.nes.views.Emulator;
	/**
	 * ...
	 * @author ...
	 */
	public class Nestest 
	{
		[Embed(source = "nestest.log", mimeType = "application/octet-stream")]
		public static var TestLog:Class;
		
		private var _testLog:ByteArray = new TestLog() as ByteArray;
		private var _logArray:Vector.<CPUState>;
		private var _emulator:Emulator;
		private var _testLines:uint = 0;
		private var _newFrame:Boolean = false;
		private var _cpu:CPU;
		private var _currentLine:uint = 0;
		private var _logState:CPUState;
		private var _cpuState:CPUState;
		private var _debugStr:String = "";
		
		public function Nestest(emulator:Emulator) 
		{
			_logArray = new Vector.<CPUState>();
			_emulator = emulator;
			parseLog(_testLog);
		}
		
		private function onEnterFrame(e:Event):void
		{
			_emulator.log(_debugStr, false);
			runTest(15);
		}
		
		private function runTest(time:uint):void
		{
			var endTime:uint = getTimer() + time;
			var linePassed:Boolean;
			while (_currentLine < _testLines && getTimer() < endTime)
			{
				linePassed = true;
				_cpu.execute();
				_cpuState = _cpu.state;
				
				_debugStr += "\n" + _cpuState.toString();
				
				if (_cpu.state.error == true)
				{
					stopTest("CPU Error at line: " + _currentLine);
					return;
				}
				// Compare state with log file
				_logState = _logArray[_currentLine];
				
				// Output debug string
				
				if (_cpuState.address != _logState.address ||
				    _cpuState.opcode != _logState.opcode ||
					_cpuState.param1 != _logState.param1 ||
					_cpuState.param2 != _logState.param2 ||
					_cpuState.A != _logState.A ||
					_cpuState.X != _logState.X ||
					_cpuState.Y != _logState.Y ||
					_cpuState.P != _logState.P ||
					_cpuState.SP != _logState.SP /* ||
					cpuState.CYC != logState.CYC ||
					cpuState.SL != logState.SL */ )
				{
					linePassed = false;
				}
				
				if (linePassed == false)
				{
					stopTest("Difference detected in CPU State at line " + _currentLine + ":\n" +
					         "CPU: " + _cpuState.toString() + "\n" +
					         "LOG: " + _logState.toString());
					return;
				}
				_currentLine++;
			}
			if (_currentLine >= _testLines)
			{
				stopTest("Nestest Passed!");
			}
		}
		
		public function startTest(cpu:CPU, startAddr:uint):void
		{
			_cpu = cpu;
			_currentLine = 0;
			_debugStr = "";
			
			_cpu.start(startAddr);
			
			_emulator.addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}
		
		public function stopTest(message:String):void
		{
			_emulator.removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			_emulator.log(_debugStr, true);
			_emulator.log("\n" + message, true);
		}
		
		private function parseLog(logArray:ByteArray):void
		{
			var EOF:Boolean = false;
			var line:String;
			var state:CPUState;
			var position:uint = 0;
			var startTime:uint = getTimer();
			while (EOF == false)
			{
				// Check for EOF
				if (logArray.position + 85 > logArray.length)
				{
					EOF = true;
					break;
				}
				// Read the parameters up to SL
				line = logArray.readUTFBytes(85);
				state = parseLine(line);
				// Find the end of the line and read in SL
				var SL:String = "";
				var val:String;
				
				while (logArray.position < logArray.length)
				{
					val = logArray.readUTFBytes(1);
					// TODO: Verify with different line endings, UTFBytes may fix this?
					if (val == "\n")
					{
						break;
					}
					SL += val;
				}
				
				if (SL == "")
				{
					EOF = true;
					break;
				}
				state.SL = parseInt(SL, 10);
				_testLines = _logArray.push(state);
			}
			_emulator.log("Parsed nestest log, " + _testLines + " lines in " + (getTimer() - startTime) + "ms.");
		}
		
		private function parseLine(line:String):CPUState
		{
			var state:CPUState = new CPUState();
			var param:String;
			
			state.address = parseInt(line.slice(0, 4), 16);
			state.opcode = parseInt(line.slice(6, 8), 16);
			
			param = line.slice(9, 11);
			if (param == "  ")
			{
				state.param1 = int.MAX_VALUE;
			}
			else
			{
				state.param1 = parseInt(param, 16);
			}
			
			param = line.slice(12, 14);
			if (param == "  ")
			{
				state.param2 = int.MAX_VALUE;
			}
			else
			{
				state.param2 = parseInt(param, 16);
			}
			
			state.A = parseInt(line.slice(50, 52), 16);
			state.X = parseInt(line.slice(55, 57), 16);
			state.Y = parseInt(line.slice(60, 62), 16);
			state.P = parseInt(line.slice(65, 67), 16);
			state.SP = parseInt(line.slice(71, 73), 16);
			state.CYC = parseInt(line.slice(78, 81), 10);
			state.SL = 0;
			
			return state;
		}
	}

}