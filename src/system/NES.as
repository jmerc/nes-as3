package system 
{
	import flash.utils.*;
	import interfaces.*;
	import tests.CPUState;
	import tests.interfaces.ITest;
	import tests.nestest.Nestest;
	import views.*;
	/**
	 * ...
	 * @author John
	 */
	public class NES 
	{
		// TODO - make these private, pass them to subsystems that need them (javascript really needs access rights)
		public var ui:INESUI;
		public var cpu:CPU;
		public var ppu:PPU;
		public var apu:APU;
		public var mmap:IMapper;
		public var rom:ROM;
		public var input:IInput;
		
		private static const HISTORY_LENGTH:int = 10;
		private var _history:Vector.<CPUState>;
		private var _historyIndex:int = HISTORY_LENGTH;
		
		
		// TODO: Create a NES configuration object
		public var options:Object = {
			ui: new DummyUI(),
			input: new Input(),
			preferredFrameRate: 60,
			fpsTime: 500,  // Time between updating FPS in ms
			showDisplay: true,
			emulateSound: false,
			sampleRate: 44100,
			CPU_FREQ_NTCS: 1789772.5,
			CPU_FREQ_PAL: 1773447.4
		}
		
		private var isRunning:Boolean = false;
		private var fpsFrameCount:int = 0;
		private var romData:ByteArray;
		
		private var frameTime:Number;
		private var frameInterval:uint;
		private var fpsInterval:uint;
		private var lastFPSTime:int;
		
		public function NES(options:Object = null) 
		{
			
			if (options == null) { options = { }; }
			for (var key:* in this.options)
			{
				if (options.hasOwnProperty(key))
				{
					this.options[key] = options[key];
				}
			}
			
			frameTime = 1000 / this.options.preferredFrameRate;
			ui = this.options.ui;
			cpu = new CPU(this);
			ppu = new PPU(this);
			apu = new APU(this);
			mmap = null;  // Set in loadRom()
			input = this.options.input;
			
			// Set up CPU State History
			_history = new Vector.<CPUState>(HISTORY_LENGTH);
			for (var i:int = 0; i < HISTORY_LENGTH; i++)
			{
				_history[i] = new CPUState();
			}
			
			ui.updateStatus("Ready to load a ROM.");
		}
		
		public function reset():void
		{
			if (mmap != null)
			{
				mmap.reset();
			}
			cpu.reset();
			ppu.reset();
			apu.reset();
		}
		
		public function start():void
		{
			if (rom && rom.valid)
			{
				if (!isRunning)
				{
					isRunning = true;
					
					frameInterval = setInterval(frame, frameTime);
					resetFPS();
					printFPS();
					fpsInterval = setInterval(printFPS, options.fpsTime);					
				}
			}
			else
			{
				ui.updateStatus("There is no ROM loaded, or it is invalid.");
			}
		}
		
		private function frame():void
		{
			ppu.startFrame();
			var cycles:int = 0;
			var emulateSound:Boolean = options.emulateSound;
			
			var inFrame:Boolean = true;
			
			while (inFrame && isRunning)
			{
				// Run CPU and APU
				if (cpu.cyclesToHalt == 0)
				{
					(_historyIndex == 0) ? _historyIndex = HISTORY_LENGTH - 1 : _historyIndex--;
					cpu.cpuState = _history[_historyIndex];
					cycles = cpu.emulate();
				}
				else if (cpu.cyclesToHalt > 8)
				{
					cycles = 8;
					cpu.cyclesToHalt -= 8;
				}
				else
				{
					cycles = cpu.cyclesToHalt;
					cpu.cyclesToHalt = 0;
				}
				if (emulateSound && cycles > 0)
				{
					apu.clockFrameCounter(cycles);
				}
				cycles *= 3;  // Convert from CPU to NES clock cyles for PPU useage\
				
				// Run PPU
				// TODO: this is bad if concurrent PPU/CPU emulation is needed
				// TODO: Could potentially quicken things by staying in CPU emulation
				//       until PPU interaction is needed
				for (; cycles > 0; cycles--)
				{
					if (ppu.curX == ppu.spr0HitX &&
						ppu.f_spVisibility == 1 &&
						ppu.scanline - 21 == ppu.spr0HitY)
					{
						// Set Sprite 0 hit flag
						ppu.setStatusFlag(PPU.STATUS_SPRITE0HIT, true);
					}
					
					if (ppu.requestEndFrame)
					{
						ppu.nmiCounter--;
						if (ppu.nmiCounter == 0)
						{
							ppu.requestEndFrame = false;
							ppu.startVBlank();
							inFrame = false;
							break;
						}
					}
					
					ppu.curX++;
					if (ppu.curX == 341)
					{
						ppu.curX = 0;
						ppu.endScanLine();
					}
				} // end for(cycles--)
			}  // end while(inFrame)
			
			fpsFrameCount++;
		}
		
		private function printFPS():void
		{
			var now:int = getTimer()
			var s:String = "Running";
			if (lastFPSTime != 0)
			{
				s += ": " + Number(
						fpsFrameCount / ((now - lastFPSTime) / 1000)
					).toFixed(2) + " FPS";
			}
			ui.updateStatus(s);
			fpsFrameCount = 0;
			lastFPSTime = now;
		}
		
		public function stop():void
		{
			clearInterval(frameInterval);
			clearInterval(fpsInterval);
			isRunning = false;
			// Trace cpu state history
			for (var i:int = 0; i < HISTORY_LENGTH; i++)
			{
				trace(_history[(i + _historyIndex) % HISTORY_LENGTH].toString());
			}
		}
		
		private function reloadRom():void
		{
			if (romData != null)
			{
				loadRom(romData);
			}
		}
		
		public function loadRom(data:ByteArray):Boolean
		{
			if (isRunning)
			{
				stop();
			}
			
			ui.updateStatus("Loading ROM...");
			
			// Load ROM file
			rom = new ROM(this);
			
			rom.load(data);
			
			if (rom.valid)
			{
				reset();
				mmap = rom.createMapper();
				if (!mmap)
				{
					return false;
				}
				mmap.loadROM();
				ppu.setMirroring(rom.getMirroringType());
				romData = data;
				
				ui.updateStatus("Successfully loaded.  Ready to be started.");
			}
			else
			{
				ui.updateStatus("Invalid ROM!");
			}
			return rom.valid;
		}
		
		private function resetFPS():void
		{
			lastFPSTime = 0;
			fpsFrameCount = 0;
		}
		
		private function setFrameRate(rate:int):void
		{
			options.preferredFrameRate = rate;
			frameTime = 1000 / rate;
			apu.setSampleRate(options.sampleRate, false);
		}
		
		public function set crashMessage(value:String):void
		{
			trace("CPU Crash: " + value);
		}
		
		
		public function runTest(testType:String):void
		{
			switch (testType)
			{
				case "NESTEST":
					var test:ITest = new Nestest(this);
					loadRom(test.rom);
					test.startTest();
					break;
			}
		}
		
		
	}

}