package system 
{
	import flash.display.TriangleCulling;
	import system.PPU.Tile
	/**
	 * ...
	 * @author John
	 */
	public class PPU 
	{
		
		private var nes:NES;
		

		private var _mem:Vector.<uint>;
		private var _objectAttributeMem:Vector.<uint>;
		private var _paletteMem:Vector.<uint>;
		private var _x:int;
		private var _y:int;
		private var _mirroring:int;
		private var _nametable0Start:uint = 0x2000;
		private var _nametable1Start:uint = 0x2400;
		private var _nametable2Start:uint = 0x2800;
		private var _nametable3Start:uint = 0x2C00;
		
		private var _renderingEnabled:Boolean;
		private var _oddFrame:Boolean = false;
		
		// PPU control register (Write-only)
		private var _regController:uint;  	// 0x2000
		private const CTRL_NAMETABLE:uint =			0x03; 	// Base nametable address
															//   (0 = $2000; 1 = $2400; 2 = $2800; 3 = $2C00)
		private const CTRL_VRAM_INC:uint =			0x04; 	// VRAM address increment per CPU read/write of PPUDATA
															//   (0: add 1, going across; 1: add 32, going down)
		private const CTRL_SPRITE:uint =			0x08; 	// Sprite pattern table address for 8x8 sprites
															//   (0: $0000; 1: $1000; ignored in 8x16 mode)
		private const CTRL_BACKGROUND:uint =		0x10;	// Background pattern table address (0: $0000; 1: $1000)
		private const CTRL_SPRITE_SIZE:uint =		0x20;	// Sprite size (0: 8x8 pixels; 1: 8x16 pixels)
		private const CTRL_PPU_MASTER:uint =		0x40;	// PPU master/slave select
															//   (0: read backdrop from EXT pins; 1: output color on EXT pins)
		private const CTRL_VBLANK:uint =			0x80;	// Generate an NMI at the start of the
															//   vertical blanking interval (0: off; 1: on)
		
		private var _regMask:uint;  		// 0x2001		
		private const MASK_GREYSCALE:uint =			0x01;	// Greyscale (0: normal color, 1: produce a greyscale display)
		private const MASK_BG_LEFT:uint = 			0x02;	// 1: Show background in leftmost 8 pixels of screen, 0: Hide
		private const MASK_SPRITES_LEFT:uint =		0x04;	// 1: Show sprites in leftmost 8 pixels of screen, 0: Hide
		private const MASK_SHOW_BG:uint = 			0x08;	// 1: Show background
		private const MASK_SHOW_SPRITES:uint =		0x10;	// 1: Show sprites
		private const MASK_EMPH_RED:uint = 			0x20;	// Emphasize red
		private const MASK_EMPH_GREEN:uint =		0x40;	// Emphasize green
		private const MASK_EMPH_BLUE:uint = 		0x80;	// Emphasize blue

		private var _regStatus:uint;		// 0x2002
		private const STATUS_OVERFLOW:uint =		0x20;
		private const STATUS_SPRITE0:uint =			0x40;
		private const STATUS_VBLANK:uint =			0x80;
		
		// OAM Address/Write/DMA			// 0x2003, 0x2004, 0x4014
		private var _oamAddress:uint;
		
		// VRam Address/Write 				// 0x2006, 0x2007
		private var _bufferedDataReg:uint;
		private var _regAddress:uint;
		private var _addressLatch:Boolean;
		
		public function get memory():Vector.<uint> { return _mem; }
		
		public function PPU(nes:NES) 
		{
			this.nes = nes;
			reset();
		}
		
		public function reset():void
		{
			var i:uint;
			
			// Memory
			_mem = new Vector.<uint>(0x8000);
			_objectAttributeMem = new Vector.<uint>(0x100);
			_paletteMem = new Vector.<uint>(0x20);
			for (i = 0; i < _mem.length; i++) { _mem[i] = 0; }
			for (i = 0; i < _objectAttributeMem.length; i++) { _objectAttributeMem[i] = 0; }
			for (i = 0; i < _paletteMem.length; i++) { _paletteMem[i] = 0; }
			
			_x = 0;
			_y = 0;
			_renderingEnabled = false;
			_oddFrame = false;
			_addressLatch = false;
			_regAddress = 0;
			_bufferedDataReg = 0;
		}
		
		public function incrementCycles(cycles:int):Boolean
		{
			var inFrame:Boolean = true;
			
			// Track X,Y Coordinate
			// TODO: NMI, Sprite0, Even/Odd timing			
			while (cycles > 0)
			{
				_x++;
				
				if (_x > 340)
				{
					_x -= 340;
					_y++;
				}
				if (_y > 261)
				{
					_y -= 261;
 					inFrame = false;
				}
				
				// TODO: Check for Sprite 0
				
				//1,240 - set VBlank
				if (_x == 1 && _y == 240)
					setVBlank();
				
				//1,261 - clear VB	lank, Sprite 0, Overflow
				if (_x == 1 && _y == 261)
				{
					//debug("Clear Status Register");
					_regStatus = 0;
				}
				cycles--;
			}
			
			return inFrame;
		}
		
		// Sets nametable Mirror
		public function setMirroring(mirroring:uint):void
		{
			_mirroring = mirroring;
			switch (_mirroring)
			{
				case ROM.SINGLESCREEN_MIRRORING:  // All name tables at 0x2000
					_nametable0Start = 0x2000;
					_nametable1Start = 0x2000;
					_nametable2Start = 0x2000;
					_nametable3Start = 0x2000;
					debug("setMirroring = Single Screen");
					break;
				case ROM.HORIZONTAL_MIRRORING:  // Used for vertical scrolling
					_nametable0Start = 0x2000;
					_nametable1Start = 0x2000;
					_nametable2Start = 0x2800;
					_nametable3Start = 0x2800;
					debug("setMirroring = Vertical Scrolling");
					break;
				case ROM.VERTICAL_MIRRORING:  // used for horizontal scrolling
					_nametable0Start = 0x2000;
					_nametable1Start = 0x2400;
					_nametable2Start = 0x2000;
					_nametable3Start = 0x2400;
					debug("setMirroring = Horizontal Scrolling");
					break;
				case ROM.FOURSCREEN_MIRRORING:  // used for bidrectional scrolling
					_nametable0Start = 0x2000;
					_nametable1Start = 0x2400;
					_nametable2Start = 0x2800;
					_nametable3Start = 0x2C00;
					debug("setMirroring = Four Screen");
					break;
			}
			
		}
		
		private function calculateMirroredAddr(addr:uint):uint
		{
			// what nametable are we accessing?
			var internalAddress:uint = addr & 0x3FF;
			var nametable:int = (addr >> 10) & 0x3;
			switch (nametable)
			{
				case 0:
					return _nametable0Start + internalAddress;
				case 1:
					return _nametable1Start + internalAddress;
				case 2:
					return _nametable2Start + internalAddress;
				case 3:
					return _nametable3Start + internalAddress;
			}
			debug("Can't calculate mirrored address! " + addr + " " + internalAddress + " " + nametable);
			return addr;
		}
		

		
		
		
		
		
		private function drawFrame():void
		{
			var buffer:Vector.<uint> = new Vector.<uint>(256 * 240);
			if (nes.options.showDisplay) {
				nes.ui.writeFrame(buffer);
			}
		}
		
		public function writeControllerReg(addr:uint, value:uint):void
		{			
			debug("writeControllerReg[" + addr.toString(16) + "] = " + value.toString(16));		
			_regController = value;
		}
		
		public function writeMaskReg(addr:uint, value:uint):void
		{
			debug("writeMaskReg[" + addr.toString(16) + "] = " + value.toString(16));
			// TODO: Add this write to the queue to update rendering
			_regMask = value;
		}
		
		// CPU Register $2002:
		// Read the Status Register.
		public function readStatusRegister(addr:uint):uint
		{	
			//debug("readStatusRegister[" + addr.toString(16) + "] NOT IMPLEMENTED");	
			// TODO: bits 0-4 should match the 'buffered' value of the PPU REGISTER line
			var regStatus:uint = _regStatus;
			
			// Reading STATUS will clear the following:
			_regStatus &= ~STATUS_VBLANK;
			_addressLatch = false;  
			
			return regStatus;
		}
		
		// CPU Register $2003:
		// Write the address of OAM you want to access here. Most games just write $00 here and then use OAMDMA.
		public function writeOamAddrReg(addr:uint, value:uint):void
		{
			debug("writeOamAddrReg[" + addr.toString(16) + "] = " + value.toString(16));
			_oamAddress = value & 0xFF;
		}
		
		// CPU Register $2004 (R):
		// Read from SPR-RAM (Sprite RAM).
		// The address should be set first.
		public function readOamDataReg(addr:uint):uint
		{
			var value:uint = _objectAttributeMem[_oamAddress];
			debug("readOamDataReg[" + _oamAddress.toString(16) + "] = " + value.toString(16));	
			return value;
		}
		
		// CPU Register $2004 (W):
		// Write to SPR-RAM (Sprite RAM).
		// The address should be set first.
		public function writeOamDataReg(addr:uint, value:uint):void
		{			
			debug("writeOamDataReg[" + _oamAddress.toString(16) + "] = " + value.toString(16));
			_objectAttributeMem[_oamAddress] = value;
		}
		
		// CPU Register $2005:
		// Write to scroll registers.
		// The first write is the vertical offset, the second is the
		// horizontal offset:
		public function writeScrollReg(addr:uint, value:uint):void
		{
			debug("writeScrollReg[" + addr.toString(16) + "] = " + value.toString(16) + " NOT IMPLEMENTED");
		}
		
		// CPU Register $2006:
		// Sets the adress used when reading/writing from/to VRAM.
		// The first write sets the high byte, the second the low byte.
		public function writeAddressReg(addr:uint, value:uint):void
		{
			if (_addressLatch)
			{
				_regAddress &= 0xFF00;
				_regAddress |= value;
			}
			else
			{
				_regAddress &= 0x00FF;
				_regAddress |= (value << 8);
			}
			
			// Memory is only 0-3fff, so mirror down to this range
			_regAddress &= 0x3FFF;
			
			// Toggle address latch
			_addressLatch = !_addressLatch;
			
			debug("writeVRAMAddress[" + addr.toString(16) + "] = " + value.toString(16) + " Addr = " + _regAddress.toString(16));
		}
		
		// CPU Register $2007(R):
		// Read from PPU memory. The address should be set first.
		public function readDataReg(addr:uint):uint
		{
			var loadedData:uint;
			
			// If address is in range 0x0000-0x3EFF, return buffered values:
			if (_regAddress < 0x3F00)
			{
				loadedData = _bufferedDataReg;
			}
			else // 0x3F00-0x3FFF reads palette data immediately
			{
				var paletteAddress:uint = (_regAddress - 0x3F00) & 0x1F;  // 20 byte palette memory
				loadedData = _paletteMem[paletteAddress];
				
				debug("readDataReg[" + _regAddress.toString(16) + "=>" + paletteAddress.toString(16) + "] = " + loadedData.toString(16));
			}
			
			// Set up register buffer for next read
			var mirroredAddr:uint = calculateMirroredAddr(_regAddress);
			_bufferedDataReg = _mem[mirroredAddr];
			
			// Auto Increment _regAddress after read
			_regAddress += (_regController & CTRL_VRAM_INC == 0) ? 1 : 32;
			_regAddress &= 0x3FFF;  // Cap to real size of ram	
			
			return loadedData;
		}
		
		// CPU Register $2007(W):
		// Write to PPU memory. The address should be set first.
		public function writeDataReg(addr:uint, value:uint):void
		{
			if (_regAddress < 0x3F00)
			{
				var mirroredAddr:uint = calculateMirroredAddr(_regAddress);
				//debug("writeDataReg[" + _regAddress.toString(16) + "=>" + mirroredAddr.toString(16) + "] = " + value.toString(16));
				_mem[mirroredAddr] = value;
			}
			else
			{
				var paletteAddress:uint = (_regAddress - 0x3F00) & 0x1F;  // 20 byte palette memory
				debug("writeDataReg[" + _regAddress.toString(16) + "=>" + paletteAddress.toString(16) + "] = " + value.toString(16));
				_paletteMem[paletteAddress] = value;
			}
		}
		
		// CPU Register $4014:
		// Write 256 bytes of main memory
		// into Sprite RAM.
		public function writeOAMDMAReg(addr:uint, value:uint):void
		{
			debug("writeOAMDMAReg[" + addr.toString(16) + "] = " + value.toString(16));
			
			var baseAddress:uint = value * 0x100;
			var data:uint;
			for (var i:uint=_oamAddress; i < 256; i++) {
				data = nes.cpu.mem[baseAddress+i];
				_objectAttributeMem[i] = data;
			}
			
			nes.cpu.haltCycles(513);
			
		}
		
		
		public function triggerRendering():void
		{
			debug("triggerRendering NOT IMPLEMENTED");
		}
		
		private function setVBlank():void
		{
			//debug("Set VBlank");
			// Set VBlank flag:
			_regStatus |= STATUS_VBLANK;
			
			if (_regController & CTRL_VBLANK)
				nes.cpu.requestIrq(CPU.IRQ_NMI);
		}
		
		private function debug(msg:String):void
		{
			trace(this + "(" + _x + "," + _y + ") " + msg);
		}
	}
}

internal class NameTable
{
	private var width:uint;
	private var height:uint;
	private var name:String;
	
	public var tile:Array;
	private var attrib:Array;
	
	public function NameTable(width:uint, height:uint, name:String)
	{
		this.width = width;
		this.height = height;
		this.name = name;	
		
		this.tile = new Array(width*height);
		this.attrib = new Array(width*height);
	}
	
	public function getTileIndex(x:uint, y:uint):uint
	{
		return tile[y*width+x];
	}

	public function getAttrib(x:uint, y:uint):uint
	{
		return attrib[y*width+x];
	}

	public function writeAttrib(index:uint, value:uint):void
	{
		var basex:uint = (index % 8) * 4;
		var basey:uint = Math.floor(index / 8) * 4;
		var add:uint;
		var tx:uint, ty:uint;
		var attindex:uint;
	
		for (var sqy:uint=0;sqy<2;sqy++) {
			for (var sqx:uint=0;sqx<2;sqx++) {
				add = (value>>(2*(sqy*2+sqx)))&3;
				for (var y:uint=0;y<2;y++) {
					for (var x:uint=0;x<2;x++) {
						tx = basex+sqx*2+x;
						ty = basey+sqy*2+y;
						attindex = ty*width+tx;
						attrib[ty*width+tx] = (add<<2)&12;
					}
				}
			}
		}
	}
	
}


internal class PaletteTable
{
	private var curTable:Vector.<uint>;
	private var emphTable:Vector.<Vector.<uint>>;
	private var currentEmph:int;
	
	public function PaletteTable()
	{
		curTable = new Vector.<uint>(64);
	
		emphTable = new Vector.<Vector.<uint>>(8);
		currentEmph = -1;
	}

	private function reset():void
	{
		setEmphasis(0);
	}

	public function loadNTSCPalette():void
	{
		curTable = Vector.<uint>([
					0x525252, 0x0000B4, 0x0000A0, 0x3D00B1, 
					0x690074, 0x5B0000, 0x5F0000, 0x401800, 
					0x102F00, 0x084A08, 0x006700, 0x004212, 
					0x00286D, 0x000000, 0x000000, 0x000000, 
					0xE7D5C4, 0x0040FF, 0x220EDC, 0x6B47FF, 
					0x9F00D7, 0xD70A68, 0xBC1900, 0xB15400, 
					0x5B6A00, 0x038C00, 0x00AB00, 0x00882C, 
					0x0072A4, 0x000000, 0x000000, 0x000000, 
					0xF8F8F8, 0x3CABFF, 0x8179FF, 0xC55BFF, 
					0xF248FF, 0xFF49DF, 0xFF6D47, 0xF7B400, 
					0xFFE000, 0x75E300, 0x2BF403, 0x2EB87B, 
					0x18E2E5, 0x787878, 0x000000, 0x000000, 
					0xFFFFFF, 0xBEF2FF, 0xB8B8F8, 0xD8B8F8, 
					0xFFB6FF, 0xFFC3FF, 0xFFD1C7, 0xFFDA9A, 
					0xF8ED88, 0xDDFF83, 0xB8F8B8, 0xACF8F5, 
					0xB0FFFF, 0xF8D8F8, 0x000000, 0x000000
					]);
		makeTables();
		setEmphasis(0);
	}
	
	private function loadPALPalette():void
	{
		curTable = Vector.<uint>([
					0x525252, 0xB40000, 0xA00000, 0xB1003D, 
					0x740069, 0x00005B, 0x00005F, 0x001840, 
					0x002F10, 0x084A08, 0x006700, 0x124200, 
					0x6D2800, 0x000000, 0x000000, 0x000000, 
					0xC4D5E7, 0xFF4000, 0xDC0E22, 0xFF476B, 
					0xD7009F, 0x680AD7, 0x0019BC, 0x0054B1, 
					0x006A5B, 0x008C03, 0x00AB00, 0x2C8800, 
					0xA47200, 0x000000, 0x000000, 0x000000, 
					0xF8F8F8, 0xFFAB3C, 0xFF7981, 0xFF5BC5, 
					0xFF48F2, 0xDF49FF, 0x476DFF, 0x00B4F7, 
					0x00E0FF, 0x00E375, 0x03F42B, 0x78B82E, 
					0xE5E218, 0x787878, 0x000000, 0x000000, 
					0xFFFFFF, 0xFFF2BE, 0xF8B8B8, 0xF8B8D8, 
					0xFFB6FF, 0xFFC3FF, 0xC7D1FF, 0x9ADAFF, 
					0x88EDF8, 0x83FFDD, 0xB8F8B8, 0xF5F8AC, 
					0xFFFFB0, 0xF8D8F8, 0x000000, 0x000000
					]);
		makeTables();
		setEmphasis(0);
	}
	
	private function makeTables():void
	{
		var r:uint, g:uint, b:uint, col:uint, i:uint, rFactor:uint, gFactor:uint, bFactor:uint;
		
		// Calculate a table for each possible emphasis setting:
		for (var emph:uint = 0; emph < 8; emph++) {
			
			// Determine color component factors:
			rFactor = 1.0;
			gFactor = 1.0;
			bFactor = 1.0;
			
			if ((emph & 1) !== 0) {
				rFactor = 0.75;
				bFactor = 0.75;
			}
			if ((emph & 2) !== 0) {
				rFactor = 0.75;
				gFactor = 0.75;
			}
			if ((emph & 4) !== 0) {
				gFactor = 0.75;
				bFactor = 0.75;
			}
			
			emphTable[emph] = new Vector.<uint>(64);
			
			// Calculate table:
			for (i = 0; i < 64; i++) {
				col = curTable[i];
				r = Math.floor(getRed(col) * rFactor);
				g = Math.floor(getGreen(col) * gFactor);
				b = Math.floor(getBlue(col) * bFactor);
				emphTable[emph][i] = getRgb(r, g, b);
			}
		}
	}
	
	public function setEmphasis(emph:uint):void
	{
		if (emph != currentEmph) {
			currentEmph = emph;
			for (var i:uint = 0; i < 64; i++) {
				curTable[i] = emphTable[emph][i];
			}
		}
	}
	
	public function getEntry(yiq:uint):uint
	{
		return curTable[yiq];
	}
	
	private function getRed(rgb:uint):uint
	{
		return (rgb>>16)&0xFF;
	}
	
	private function getGreen(rgb:uint):uint
	{
		return (rgb>>8)&0xFF;
	}
	
	private function getBlue(rgb:uint):uint
	{
		return rgb&0xFF;
	}
	
	private function getRgb(r:uint, g:uint, b:uint):uint
	{
		return ((r<<16)|(g<<8)|(b));
	}
	
	private function loadDefaultPalette():void
	{
		curTable[ 0] = getRgb(117,117,117);
		curTable[ 1] = getRgb( 39, 27,143);
		curTable[ 2] = getRgb(  0,  0,171);
		curTable[ 3] = getRgb( 71,  0,159);
		curTable[ 4] = getRgb(143,  0,119);
		curTable[ 5] = getRgb(171,  0, 19);
		curTable[ 6] = getRgb(167,  0,  0);
		curTable[ 7] = getRgb(127, 11,  0);
		curTable[ 8] = getRgb( 67, 47,  0);
		curTable[ 9] = getRgb(  0, 71,  0);
		curTable[10] = getRgb(  0, 81,  0);
		curTable[11] = getRgb(  0, 63, 23);
		curTable[12] = getRgb( 27, 63, 95);
		curTable[13] = getRgb(  0,  0,  0);
		curTable[14] = getRgb(  0,  0,  0);
		curTable[15] = getRgb(  0,  0,  0);
		curTable[16] = getRgb(188,188,188);
		curTable[17] = getRgb(  0,115,239);
		curTable[18] = getRgb( 35, 59,239);
		curTable[19] = getRgb(131,  0,243);
		curTable[20] = getRgb(191,  0,191);
		curTable[21] = getRgb(231,  0, 91);
		curTable[22] = getRgb(219, 43,  0);
		curTable[23] = getRgb(203, 79, 15);
		curTable[24] = getRgb(139,115,  0);
		curTable[25] = getRgb(  0,151,  0);
		curTable[26] = getRgb(  0,171,  0);
		curTable[27] = getRgb(  0,147, 59);
		curTable[28] = getRgb(  0,131,139);
		curTable[29] = getRgb(  0,  0,  0);
		curTable[30] = getRgb(  0,  0,  0);
		curTable[31] = getRgb(  0,  0,  0);
		curTable[32] = getRgb(255,255,255);
		curTable[33] = getRgb( 63,191,255);
		curTable[34] = getRgb( 95,151,255);
		curTable[35] = getRgb(167,139,253);
		curTable[36] = getRgb(247,123,255);
		curTable[37] = getRgb(255,119,183);
		curTable[38] = getRgb(255,119, 99);
		curTable[39] = getRgb(255,155, 59);
		curTable[40] = getRgb(243,191, 63);
		curTable[41] = getRgb(131,211, 19);
		curTable[42] = getRgb( 79,223, 75);
		curTable[43] = getRgb( 88,248,152);
		curTable[44] = getRgb(  0,235,219);
		curTable[45] = getRgb(  0,  0,  0);
		curTable[46] = getRgb(  0,  0,  0);
		curTable[47] = getRgb(  0,  0,  0);
		curTable[48] = getRgb(255,255,255);
		curTable[49] = getRgb(171,231,255);
		curTable[50] = getRgb(199,215,255);
		curTable[51] = getRgb(215,203,255);
		curTable[52] = getRgb(255,199,255);
		curTable[53] = getRgb(255,199,219);
		curTable[54] = getRgb(255,191,179);
		curTable[55] = getRgb(255,219,171);
		curTable[56] = getRgb(255,231,163);
		curTable[57] = getRgb(227,255,163);
		curTable[58] = getRgb(171,243,191);
		curTable[59] = getRgb(179,255,207);
		curTable[60] = getRgb(159,255,243);
		curTable[61] = getRgb(  0,  0,  0);
		curTable[62] = getRgb(  0,  0,  0);
		curTable[63] = getRgb(  0,  0,  0);
		
		makeTables();
		setEmphasis(0);
	}
}

