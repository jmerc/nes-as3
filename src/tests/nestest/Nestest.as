package tests.nestest 
{
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	import interfaces.INESUI;
	import system.NES;
	import tests.CPUState;
	import views.Emulator;
	import tests.interfaces.ITest;
	/**
	 * ...
	 * @author ...
	 */
	public class Nestest implements ITest
	{
		private const START_ADDR:uint = 0xC000;
		
		[Embed(source = "nestest.log", mimeType = "application/octet-stream")]
		private static var TestLog:Class;		
		private var _testLog:ByteArray = new TestLog() as ByteArray;
		
		[Embed(source = "nestest.nes", mimeType = "application/octet-stream")]
		private static var TestRom:Class;
		private var _testRom:ByteArray = new TestRom() as ByteArray;
		
		private var _logArray:Vector.<CPUState>;
		private var _testLines:uint = 0;
		private var _currentLine:uint = 0;
		private var _logState:CPUState;
		private var _cpuState:CPUState;
		private var _debugStr:String = "";
		private var _nes:NES;
		
		public function Nestest(nes:NES) 
		{
			_logArray = new Vector.<CPUState>();
			_nes = nes;
			parseLog(_testLog);
		}
		
		public function get rom():ByteArray 
		{
			return _testRom;	
		}
		
		public function startTest():void
		{
			_currentLine = 0;
			_debugStr = "";
			
			_nes.cpu.setAddress(0xC000);
			
			DisplayObject(_nes.ui).addEventListener(Event.ENTER_FRAME, onEnterFrame);
		}

		private function onEnterFrame(e:Event):void
		{
			runTest(25);
		}
		
		private var enableDebug:Boolean = false;
			
		private function runTest(time:uint):void
		{
			var endTime:uint = getTimer() + time;
			var linePassed:Boolean;
			while (_currentLine < _testLines && getTimer() < endTime)
			{
				linePassed = true;
				var cycles:uint = _nes.cpu.emulate();
				_cpuState = _nes.cpu.cpuState;
				
				if (_cpuState.error == true)
				{
					stopTest("CPU Error at line: " + _currentLine);
					return;
				}
				// Compare state with log file
				_logState = _logArray[_currentLine];
				
				if (enableDebug)
				{
					trace(_currentLine + ": " + _cpuState.toString());
				}
				
				if (_cpuState.address != _logState.address ||
				    _cpuState.opcode != _logState.opcode ||
					_cpuState.param1 != _logState.param1 ||
					_cpuState.param2 != _logState.param2 ||
					_cpuState.A != _logState.A ||
					_cpuState.X != _logState.X ||
					_cpuState.Y != _logState.Y ||
					_cpuState.P != _logState.P ||
					_cpuState.SP != _logState.SP /* ||
					_cpuState.CYC != _logState.CYC ||
					_cpuState.SL != _logState.SL */)
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
		
		
		public function stopTest(message:String):void
		{
			DisplayObject(_nes.ui).removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			trace(message);
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
			trace("Parsed nestest log, " + _testLines + " lines in " + (getTimer() - startTime) + "ms.");
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