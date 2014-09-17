package net.johnmercer.nes.tests 
{
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
		
		
		public function Nestest(emulator:Emulator) 
		{
			_logArray = new Vector.<CPUState>();
			_emulator = emulator;
			parseLog(_testLog);
		}
		
		public function runTest(cpu:CPU, startAddr:uint):Boolean
		{
			var currentLine:uint = 0;
			var logState:CPUState;
			var cpuState:CPUState;
			var linePassed:Boolean;
			
			cpu.start(startAddr);
			// Step through CPU code until we reach the end of the log
			while (currentLine < _testLines)
			{
				if (currentLine == 6040)
				{
					//_emulator.log("Breakpoint for special line");
				}
				linePassed = true;
				cpu.execute();
				if (cpu.state.error == true)
				{
					_emulator.log("CPU Error at line: " + currentLine);
					return false;
				}
				// Compare state with log file
				cpuState = cpu.state;
				logState = _logArray[currentLine];
				
				if (cpuState.address != logState.address ||
				    cpuState.opcode != logState.opcode ||
					cpuState.param1 != logState.param1 ||
					cpuState.param2 != logState.param2 ||
					cpuState.A != logState.A ||
					cpuState.X != logState.X ||
					cpuState.Y != logState.Y ||
					cpuState.P != logState.P ||
					cpuState.SP != logState.SP /* ||
					cpuState.CYC != logState.CYC ||
					cpuState.SL != logState.SL */ )
				{
					linePassed = false;
				}
				
				if (linePassed == false)
				{
					_emulator.log("Difference detected in CPU State at line " + currentLine + ":");
					_emulator.log("CPU: " + cpuState.toString());
					_emulator.log("LOG: " + logState.toString());
					return false;
				}
				currentLine++;
			}
			return true;
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
				
				// Output each line read as parsed
				/*
				
				_emulator.log(outStr);
				*/
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