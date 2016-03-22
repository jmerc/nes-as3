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
		private static const STATUS_VRAMWRITE:uint = 4;
		private static const STATUS_SLSPRITECOUNT:uint = 5;
		public static const STATUS_SPRITE0HIT:uint = 6;
		private static const STATUS_VBLANK:uint = 7;
		
		private var nes:NES;
		public var vramMem:Vector.<uint>;
		private var spriteMem:Vector.<uint>;
		private var vramAddress:uint;
		private var vramTmpAddress:uint;
		private var vramBufferedReadValue:uint;
		private var firstWrite:Boolean;
		private var sramAddress:uint;
		private var currentMirroring:int;
		public var requestEndFrame:Boolean;
		private var nmiOk:Boolean;
		private var dummyCycleToggle:Boolean;
		private var validTileData:Boolean;
		public var nmiCounter:uint;
		private var scanlineAlreadyRendered:Boolean;
		
		private var f_nmiOnVBlank:uint;
		private var f_spriteSize:uint;
		private var f_bgPatternTable:uint;
		private var f_spPatternTable:uint;
		private var f_addrInc:uint;
		private var f_nTblAddress:uint;
		private var f_color:uint;
		public var f_spVisibility:uint;
		private var f_bgVisibility:uint;
		private var f_spClipping:uint;
		private var f_bgClipping:uint;
		private var f_dispType:uint;
		
		private var cntFV:uint;
		private var cntV:uint;
		private var cntH:uint;
		private var cntVT:uint;
		private var cntHT:uint;
		
		private var regFV:uint;
		private var regV:uint;
		private var regH:uint;
		private var regVT:uint;
		private var regHT:uint;
		private var regFH:uint;
		private var regS:uint;
		
		private var curNt:uint;
		private var attrib:Vector.<uint>;
		public var buffer:Vector.<uint>;
		private var bgBuffer:Vector.<uint>;
		private var pixRendered:Vector.<uint>;
		
		private var scantile:Vector.<Tile>;
		public var scanline:int;
		private var lastRenderedScanline:int;
		public var curX:uint;
		private var sprX:Vector.<int>;
		private var sprY:Vector.<int>;
		private var sprTile:Vector.<uint>;
		private var sprCol:Vector.<uint>;
		private var vertFlip:Vector.<Boolean>;
		private var horiFlip:Vector.<Boolean>;
		private var bgPriority:Vector.<Boolean>;
		public var spr0HitX:int;
		public var spr0HitY:int;
		private var hitSpr0:Boolean;
		private var sprPalette:Vector.<uint>;
		private var imgPalette:Vector.<uint>;
		public var ptTile:Vector.<Tile>;
		private var ntable1:Vector.<uint>;
		private var nameTable:Vector.<NameTable>;
		private var vramMirrorTable:Vector.<uint>;
		private var palTable:PaletteTable;
		
		private var showSpr0Hit:Boolean = false;
		private var clipToTvSize:Boolean = true;
		
		public function PPU(nes:NES) 
		{
			this.nes = nes;
			reset();
		}
		
		public function reset():void
		{
			var i:uint;
			
			// Memory
			vramMem = new Vector.<uint>(0x8000);
			spriteMem = new Vector.<uint>(0x100);
			for (i = 0; i < vramMem.length; i++)
			{
				vramMem[i] = 0;
			}
			for (i = 0; i < spriteMem.length; i++)
			{
				spriteMem[i] = 0;
			}
			
			// VRAM I/O
			vramAddress = 0;
			vramTmpAddress = 0;
			vramBufferedReadValue = 0;
			firstWrite = true;  // VRAM/Scroll Hi/Lo latch
			
			// SPR-RAM I/O
			sramAddress = 0;  // 8-bit only
			
			currentMirroring = -1;
			requestEndFrame = false;
			nmiOk = false;
			dummyCycleToggle = false;
			validTileData = false;
			nmiCounter = 0;
			scanlineAlreadyRendered = false;
			
			// Control Flags Regsiter 1:
			f_nmiOnVBlank = 0;
			f_spriteSize = 0;
			f_bgPatternTable = 0;
			f_spPatternTable = 0;
			f_addrInc = 0;
			f_nTblAddress = 0;
			
			// Control Flags Register 2
			f_color = 0;
			f_spVisibility = 0;
			f_bgVisibility = 0;
			f_spClipping = 0;
			f_bgClipping = 0;
			f_dispType = 0;
			
			// Counters
			cntFV = 0;
			cntV = 0;
			cntH = 0;
			cntVT = 0;
			cntHT = 0;
			
			// Registers
			regFV = 0;
			regV = 0;
			regH = 0;
			regVT = 0;
			regHT = 0;
			regFH = 0;
			regS = 0;
			
			// These are temporary variables used in rendering and sound procedures.
			// Their states outside of those procedures can be ignored.
			// TODO: the use of this is a bit weird, investigate
			curNt = 0;
			
			// Varibles used when rendering
			attrib = new Vector.<uint>(32);
			buffer = new Vector.<uint>(256 * 240);
			bgBuffer = new Vector.<uint>(256 * 240);
			pixRendered = new Vector.<uint>(256 * 240);
			
			scantile = new Vector.<Tile>(32);
			
			// Initial misc vars
			scanline = 0;
			lastRenderedScanline = -1;
			curX = 0;
			
			// Sprite Data
			sprX = new Vector.<int>(64);  // X Coordinate
			sprY = new Vector.<int>(64);  // Y Coordinate
			sprTile = new Vector.<uint>(64);  // Tile Index (into pattern table)
			sprCol = new Vector.<uint>(64);  // Upper Two its of color
			vertFlip = new Vector.<Boolean>(64);  // Vertical Flip
			horiFlip = new Vector.<Boolean>(64);  // Horizontal Flip
			bgPriority = new Vector.<Boolean>(64);  // Background Priority
			spr0HitX = 0;  // Sprite #0 hit x coordinate
			spr0HitY = 0;  // Sprite #0 hit y coordinate
			hitSpr0 = false;
			
			// Palette Data
			sprPalette = new Vector.<uint>(16);
			imgPalette = new Vector.<uint>(16);
			
			// Create pattern table tile buffers
			ptTile = new Vector.<Tile>(512);
			for (i = 0; i < 512; i++)
			{
				ptTile[i] = new Tile();
			}
			
			// Create nametable buffers
			// Name Table data:
			ntable1 = new Vector.<uint>(4);
			currentMirroring = -1;
			nameTable = new Vector.<NameTable>(4);
			for (i = 0; i < 4; i++)
			{
				nameTable[i] = new NameTable(32, 32, "Nt" + i);
			}
			
			// Initialize mirror lookup table
			vramMirrorTable = new Vector.<uint>(0x8000);
			for (i = 0; i < 0x8000; i++)
			{
				vramMirrorTable[i] = i;
			}
			palTable = new PaletteTable();
			palTable.loadNTSCPalette();
			
			updateControlReg1(0x2000, 0);
			updateControlReg2(0x2001, 0);			
		}
		
		// Sets nametable Mirror
		public function setMirroring(mirroring:uint):void
		{
			if (mirroring == currentMirroring) { return; }
			
			currentMirroring = mirroring;
			triggerRendering();
			
			// Remove Mirroring:
			if (vramMirrorTable == null)
			{
				vramMirrorTable = new Vector.<uint>(0x8000);
			}
			for (var i:uint = 0; i < 0x8000; i++)
			{
				vramMirrorTable[i] = i;
			}
			
			// Palette Mirroring
			defineMirrorRegion(0x3f20,0x3f00,0x20);
			defineMirrorRegion(0x3f40,0x3f00,0x20);
			defineMirrorRegion(0x3f80,0x3f00,0x20);
			defineMirrorRegion(0x3fc0,0x3f00,0x20);
			
			// Additional mirroring:
			defineMirrorRegion(0x3000,0x2000,0xf00);
			defineMirrorRegion(0x4000,0x0000,0x4000);
		
			if (mirroring == ROM.HORIZONTAL_MIRRORING) 
			{
				// Horizontal mirroring.
				ntable1[0] = 0;
				ntable1[1] = 0;
				ntable1[2] = 1;
				ntable1[3] = 1;
				
				defineMirrorRegion(0x2400,0x2000,0x400);
				defineMirrorRegion(0x2c00,0x2800,0x400);
				
			}
			else if (mirroring == ROM.VERTICAL_MIRRORING) 
			{
				// Vertical mirroring.
				ntable1[0] = 0;
				ntable1[1] = 1;
				ntable1[2] = 0;
				ntable1[3] = 1;
				
				defineMirrorRegion(0x2800,0x2000,0x400);
				defineMirrorRegion(0x2c00,0x2400,0x400);
			}
			else if (mirroring == ROM.SINGLESCREEN_MIRRORING) 
			{
				// Single Screen mirroring
				ntable1[0] = 0;
				ntable1[1] = 0;
				ntable1[2] = 0;
				ntable1[3] = 0;
				
				defineMirrorRegion(0x2400,0x2000,0x400);
				defineMirrorRegion(0x2800,0x2000,0x400);
				defineMirrorRegion(0x2c00,0x2000,0x400);
			}
			else if (mirroring == ROM.SINGLESCREEN_MIRRORING2) 
			{
				ntable1[0] = 1;
				ntable1[1] = 1;
				ntable1[2] = 1;
				ntable1[3] = 1;
				
				defineMirrorRegion(0x2400,0x2400,0x400);
				defineMirrorRegion(0x2800,0x2400,0x400);
				defineMirrorRegion(0x2c00,0x2400,0x400);
			}
			else 
			{
				// Assume Four-screen mirroring.
				ntable1[0] = 0;
				ntable1[1] = 1;
				ntable1[2] = 2;
				ntable1[3] = 3;
			}   
			
		}
		
		
		// Define a mirrored area in the address lookup table.
		// Assumes the regions don't overlap.
		// The 'to' region is the region that is physically in memory.
		private function defineMirrorRegion(fromStart:uint, toStart:uint, size:uint):void
		{
			for (var i:uint = 0; i < size; i++)
			{
				vramMirrorTable[fromStart+i] = toStart+i;
			}
		}
		
		public function startVBlank():void
		{	
			// Do NMI:
			nes.cpu.requestIrq(CPU.IRQ_NMI);
			
			// Make sure everything is rendered:
			if (lastRenderedScanline < 239) {
				renderFramePartially(
					lastRenderedScanline+1,240-lastRenderedScanline
				);
			}
			
			// End frame:
			endFrame();
			
			// Reset scanline counter:
			lastRenderedScanline = -1;
		}
		
		public function endScanLine():void
		{
			switch (scanline) {
				case 19:
					// Dummy scanline.
					// May be variable length:
					if (dummyCycleToggle) {

						// Remove dead cycle at end of scanline,
						// for next scanline:
						curX = 1;
						dummyCycleToggle = !dummyCycleToggle;

					}
					break;
					
				case 20:
					// Clear VBlank flag:
					setStatusFlag(STATUS_VBLANK,false);

					// Clear Sprite #0 hit flag:
					setStatusFlag(STATUS_SPRITE0HIT,false);
					hitSpr0 = false;
					spr0HitX = -1;
					spr0HitY = -1;

					if (f_bgVisibility == 1 || f_spVisibility==1) {

						// Update counters:
						cntFV = regFV;
						cntV = regV;
						cntH = regH;
						cntVT = regVT;
						cntHT = regHT;

						if (f_bgVisibility==1) {
							// Render dummy scanline:
							renderBgScanline(false, 0);
						}   

					}

					if (f_bgVisibility==1 && f_spVisibility==1) {

						// Check sprite 0 hit for first scanline:
						checkSprite0(0);

					}

					if (f_bgVisibility==1 || f_spVisibility==1) {
						// Clock mapper IRQ Counter:
						nes.mmap.clockIrqCounter();
					}
					break;
					
				case 261:
					// Dead scanline, no rendering.
					// Set VINT:
					setStatusFlag(STATUS_VBLANK,true);
					requestEndFrame = true;
					nmiCounter = 9;
				
					// Wrap around:
					scanline = -1; // will be incremented to 0
					
					break;
					
				default:
					if (scanline >= 21 && scanline <= 260) {

						// Render normally:
						if (f_bgVisibility == 1) {

							if (!scanlineAlreadyRendered) {
								// update scroll:
								cntHT = regHT;
								cntH = regH;
								renderBgScanline(true,scanline+1-21);
							}
							scanlineAlreadyRendered=false;

							// Check for sprite 0 (next scanline):
							if (!hitSpr0 && f_spVisibility == 1) {
								if (sprX[0] >= -7 &&
										sprX[0] < 256 &&
										sprY[0] + 1 <= (scanline - 20) &&
										(sprY[0] + 1 + (
											f_spriteSize === 0 ? 8 : 16
										)) >= (scanline - 20)) {
									if (checkSprite0(scanline - 20)) {
										hitSpr0 = true;
									}
								}
							}

						}

						if (f_bgVisibility==1 || f_spVisibility==1) {
							// Clock mapper IRQ Counter:
							nes.mmap.clockIrqCounter();
						}
					}
			}
			
			scanline++;
			regsToAddress();
			cntsToAddress();
			
		}
		
		private var _prevBgColor:int = -1;
		private var _bgArr:Vector.<uint>;
		
		private function getBgArr(bgColor:uint):Vector.<uint>
		{
			if (_prevBgColor == bgColor) { return _bgArr; }
			
			_bgArr = new Vector.<uint>(256 * 240);
			
			for (var i:uint=0; i<256*240; i++) {
				_bgArr[i] = bgColor;
			}
			_prevBgColor = bgColor;
			return _bgArr;
		}
		
		public function startFrame():void
		{
			// Set background color:
			var bgColor:uint=0;
			
			if (f_dispType === 0) {
				// Color display.
				// f_color determines color emphasis.
				// Use first entry of image palette as BG color.
				bgColor = imgPalette[0];
			}
			else {
				// Monochrome display.
				// f_color determines the bg color.
				switch (f_color) {
					case 0:
						// Black
						bgColor = 0x00000;
						break;
					case 1:
						// Green
						bgColor = 0x00FF00;
						break;
					case 2:
						// Blue
						bgColor = 0x0000FF;
						break;
					case 3:
						// Invalid. Use black.
						bgColor = 0x000000;
						break;
					case 4:
						// Red
						bgColor = 0xFF0000;
						break;
					default:
						// Invalid. Use black.
						bgColor = 0x0;
				}
			}
			
			var i:uint;
			buffer = getBgArr(bgColor).concat();
			/*
			for (i=0; i<256*240; i++) {
				buffer[i] = bgColor;
			}
			*/
			
			for (i=0; i<pixRendered.length; i++) {
				pixRendered[i]=65;
			}
		}
		
		private function endFrame():void
		{
			var i:uint, x:uint, y:uint;
			
			// Draw spr#0 hit coordinates:
			if (showSpr0Hit) {
				// Spr 0 position:
				if (sprX[0] >= 0 && sprX[0] < 256 &&
						sprY[0] >= 0 && sprY[0] < 240) {
					for (i=0; i<256; i++) {  
						buffer[(sprY[0]<<8)+i] = 0x5555FF;
					}
					for (i=0; i<240; i++) {
						buffer[(i<<8)+sprX[0]] = 0x5555FF;
					}
				}
				// Hit position:
				if (spr0HitX >= 0 && spr0HitX < 256 &&
						spr0HitY >= 0 && spr0HitY < 240) {
					for (i=0; i<256; i++) {
						buffer[(spr0HitY<<8)+i] = 0x55FF55;
					}
					for (i=0; i<240; i++) {
						buffer[(i<<8)+spr0HitX] = 0x55FF55;
					}
				}
			}
			
			// This is a bit lazy..
			// if either the sprites or the background should be clipped,
			// both are clipped after rendering is finished.
			if (clipToTvSize || f_bgClipping === 0 || f_spClipping === 0) {
				// Clip left 8-pixels column:
				for (y=0;y<240;y++) {
					for (x=0;x<8;x++) {
						buffer[(y<<8)+x] = 0;
					}
				}
			}
			
			if (clipToTvSize) {
				// Clip right 8-pixels column too:
				for (y=0; y<240; y++) {
					for (x=0; x<8; x++) {
						buffer[(y<<8)+255-x] = 0;
					}
				}
			}
			
			// Clip top and bottom 8 pixels:
			if (clipToTvSize) {
				for (y=0; y<8; y++) {
					for (x=0; x<256; x++) {
						buffer[(y<<8)+x] = 0;
						buffer[((239-y)<<8)+x] = 0;
					}
				}
			}
			
			if (nes.options.showDisplay) {
				nes.ui.writeFrame(buffer);
			}
		}
		
		public function updateControlReg1(addr:uint, value:uint):void
		{	
			nes.cpu.mem[0x2000] = value;
			
			triggerRendering();
			
			f_nmiOnVBlank =    (value>>7)&1;
			f_spriteSize =     (value>>5)&1;
			f_bgPatternTable = (value>>4)&1;
			f_spPatternTable = (value>>3)&1;
			f_addrInc =        (value>>2)&1;
			f_nTblAddress =     value&3;
			
			regV = (value>>1)&1;
			regH = value&1;
			regS = (value>>4)&1;
			
		}
		
		public function updateControlReg2(address:uint, value:uint):void
		{
			nes.cpu.mem[0x2001] = value;
			
			triggerRendering();
			
			f_color =       (value>>5)&7;
			f_spVisibility = (value>>4)&1;
			f_bgVisibility = (value>>3)&1;
			f_spClipping =   (value>>2)&1;
			f_bgClipping =   (value>>1)&1;
			f_dispType =      value&1;
			
			if (f_dispType === 0) {
				palTable.setEmphasis(f_color);
			}
			updatePalettes();
		}
		
		public function setStatusFlag(flag:uint, value:Boolean):void
		{
			var n:uint = 1<<flag;
			nes.cpu.mem[0x2002] = 
				((nes.cpu.mem[0x2002] & (255-n)) | (value?n:0));
		}
		
		// CPU Register $2002:
		// Read the Status Register.
		public function readStatusRegister(addr:uint):uint
		{	
			var tmp:uint = nes.cpu.mem[0x2002];
			
			// Reset scroll & VRAM Address toggle:
			firstWrite = true;
			
			// Clear VBlank flag:
			setStatusFlag(STATUS_VBLANK,false);
			
			// Fetch status data:
			return tmp;
			
		}
		
		// CPU Register $2003:
		// Write the SPR-RAM address that is used for sramWrite (Register 0x2004 in CPU memory map)
		public function writeSRAMAddress(addr:uint, value:uint):void
		{
			sramAddress = value;
		}
		
		// CPU Register $2004 (R):
		// Read from SPR-RAM (Sprite RAM).
		// The address should be set first.
		public function sramLoad(addr:uint):uint
		{
			/*short tmp = sprMem.load(sramAddress);
			sramAddress++; // Increment address
			sramAddress%=0x100;
			return tmp;*/
			return spriteMem[sramAddress];
		}
		
		// CPU Register $2004 (W):
		// Write to SPR-RAM (Sprite RAM).
		// The address should be set first.
		public function sramWrite(addr:uint, value:uint):void
		{
			spriteMem[sramAddress] = value;
			spriteRamWriteUpdate(sramAddress,value);
			sramAddress++; // Increment address
			sramAddress %= 0x100;
		}
		
		// CPU Register $2005:
		// Write to scroll registers.
		// The first write is the vertical offset, the second is the
		// horizontal offset:
		public function scrollWrite(addr:uint, value:uint):void
		{
			triggerRendering();
			
			if (firstWrite) {
				// First write, horizontal scroll:
				regHT = (value>>3)&31;
				regFH = value&7;
				
			}else {
				
				// Second write, vertical scroll:
				regFV = value&7;
				regVT = (value>>3)&31;
				
			}
			firstWrite = !firstWrite;
			
		}
		
		// CPU Register $2006:
		// Sets the adress used when reading/writing from/to VRAM.
		// The first write sets the high byte, the second the low byte.
		public function writeVRAMAddress(addr:uint, value:uint):void
		{
			
			if (firstWrite) {
				
				regFV = (value>>4)&3;
				regV = (value>>3)&1;
				regH = (value>>2)&1;
				regVT = (regVT&7) | ((value&3)<<3);
				
			}else {
				triggerRendering();
				
				regVT = (regVT&24) | ((value>>5)&7);
				regHT = value&31;
				
				cntFV = regFV;
				cntV = regV;
				cntH = regH;
				cntVT = regVT;
				cntHT = regHT;
				
				checkSprite0(scanline-20);
				
			}
			
			firstWrite = !firstWrite;
			
			// Invoke mapper latch:
			cntsToAddress();
			if (vramAddress < 0x2000) {
				nes.mmap.latchAccess(vramAddress);
			}   
		}
		
		// CPU Register $2007(R):
		// Read from PPU memory. The address should be set first.
		public function vramLoad(addr:uint):uint
		{
			var tmp:uint;
			
			cntsToAddress();
			regsToAddress();
			
			// If address is in range 0x0000-0x3EFF, return buffered values:
			if (vramAddress <= 0x3EFF) {
				tmp = vramBufferedReadValue;
			
				// Update buffered value:
				if (vramAddress < 0x2000) {
					vramBufferedReadValue = vramMem[vramAddress];
				}
				else {
					vramBufferedReadValue = mirroredLoad(
						vramAddress
					);
				}
				
				// Mapper latch access:
				if (vramAddress < 0x2000) {
					nes.mmap.latchAccess(vramAddress);
				}
				
				// Increment by either 1 or 32, depending on d2 of Control Register 1:
				vramAddress += (f_addrInc == 1 ? 32 : 1);
				
				cntsFromAddress();
				regsFromAddress();
				
				return tmp; // Return the previous buffered value.
			}
				
			// No buffering in this mem range. Read normally.
			tmp = mirroredLoad(vramAddress);
			
			// Increment by either 1 or 32, depending on d2 of Control Register 1:
			vramAddress += (f_addrInc == 1 ? 32 : 1); 
			
			cntsFromAddress();
			regsFromAddress();
			
			return tmp;
		}
		
		// CPU Register $2007(W):
		// Write to PPU memory. The address should be set first.
		public function vramWrite(addr:uint, value:uint):void
		{
			triggerRendering();
			cntsToAddress();
			regsToAddress();
			
			if (vramAddress >= 0x2000) {
				// Mirroring is used.
				mirroredWrite(vramAddress,value);
			}else {
				
				// Write normally.
				writeMem(vramAddress,value);
				
				// Invoke mapper latch:
				nes.mmap.latchAccess(vramAddress);
				
			}
			
			// Increment by either 1 or 32, depending on d2 of Control Register 1:
			vramAddress += (f_addrInc==1?32:1);
			regsFromAddress();
			cntsFromAddress();
			
		}
		
		// CPU Register $4014:
		// Write 256 bytes of main memory
		// into Sprite RAM.
		public function sramDMA(addr:uint, value:uint):void
		{
			var baseAddress:uint = value * 0x100;
			var data:uint;
			for (var i:uint=sramAddress; i < 256; i++) {
				data = nes.cpu.mem[baseAddress+i];
				spriteMem[i] = data;
				spriteRamWriteUpdate(i, data);
			}
			
			nes.cpu.haltCycles(513);
			
		}
		
		// Updates the scroll registers from a new VRAM address.
		private function regsFromAddress():void
		{
			
			var address:uint = (vramTmpAddress>>8)&0xFF;
			regFV = (address>>4)&7;
			regV = (address>>3)&1;
			regH = (address>>2)&1;
			regVT = (regVT&7) | ((address&3)<<3);
			
			address = vramTmpAddress&0xFF;
			regVT = (regVT&24) | ((address>>5)&7);
			regHT = address&31;
		}
		
		// Updates the scroll registers from a new VRAM address.
		private function cntsFromAddress():void
		{
			var address:uint = (vramAddress>>8)&0xFF;
			cntFV = (address>>4)&3;
			cntV = (address>>3)&1;
			cntH = (address>>2)&1;
			cntVT = (cntVT&7) | ((address&3)<<3);        
			
			address = vramAddress&0xFF;
			cntVT = (cntVT&24) | ((address>>5)&7);
			cntHT = address&31;
			
		}
		
		private function regsToAddress():void
		{
			var b1:uint  = (regFV&7)<<4;
			b1 |= (regV&1)<<3;
			b1 |= (regH&1)<<2;
			b1 |= (regVT>>3)&3;
			
			var b2:uint  = (regVT&7)<<5;
			b2 |= regHT&31;
			
			vramTmpAddress = ((b1<<8) | b2)&0x7FFF;
		}
		
		private function cntsToAddress():void
		{
			var b1:uint  = (cntFV&7)<<4;
			b1 |= (cntV&1)<<3;
			b1 |= (cntH&1)<<2;
			b1 |= (cntVT>>3)&3;
			
			var b2:uint  = (cntVT&7)<<5;
			b2 |= cntHT&31;
			
			vramAddress = ((b1<<8) | b2)&0x7FFF;
		}
		
		private function incTileCounter(count:uint):void
		{
			for (var i:uint=count; i!==0; i--) {
				cntHT++;
				if (cntHT == 32) {
					cntHT = 0;
					cntVT++;
					if (cntVT >= 30) {
						cntH++;
						if(cntH == 2) {
							cntH = 0;
							cntV++;
							if (cntV == 2) {
								cntV = 0;
								cntFV++;
								cntFV &= 0x7;
							}
						}
					}
				}
			}
		}
		
		// Reads from memory, taking into account
		// mirroring/mapping of address ranges.
		private function mirroredLoad(address:uint):uint
		{
			return vramMem[vramMirrorTable[address]];
		}
		
		// Writes to memory, taking into account
		// mirroring/mapping of address ranges.
		private function mirroredWrite(address:uint, value:uint):void
		{
			if (address>=0x3f00 && address<0x3f20) {
				// Palette write mirroring.
				if (address==0x3F00 || address==0x3F10) {
					writeMem(0x3F00,value);
					writeMem(0x3F10,value);
					
				}else if (address==0x3F04 || address==0x3F14) {
					
					writeMem(0x3F04,value);
					writeMem(0x3F14,value);
					
				}else if (address==0x3F08 || address==0x3F18) {
					
					writeMem(0x3F08,value);
					writeMem(0x3F18,value);
					
				}else if (address==0x3F0C || address==0x3F1C) {
					
					writeMem(0x3F0C,value);
					writeMem(0x3F1C,value);
					
				}else {
					writeMem(address,value);
				}
				
			}else {
				
				// Use lookup table for mirrored address:
				if (address<vramMirrorTable.length) {
					writeMem(vramMirrorTable[address],value);
				}else {
					// FIXME
					trace("Invalid VRAM address: "+address.toString(16));
				}
				
			}
		}
		
		public function triggerRendering():void
		{
			if (scanline >= 21 && scanline <= 260) {
				// Render sprites, and combine:
				renderFramePartially(
					lastRenderedScanline+1,
					scanline-21-lastRenderedScanline
				);
				
				// Set last rendered scanline:
				lastRenderedScanline = scanline-21;
			}
		}
		
		private function renderFramePartially(startScan:uint, scanCount:uint):void
		{
			if (f_spVisibility == 1) {
				renderSpritesPartially(startScan,scanCount,true);
			}
			
			if(f_bgVisibility == 1) {
				var si:uint = startScan<<8;
				var ei:uint = (startScan+scanCount)<<8;
				if (ei > 0xF000) {
					ei = 0xF000;
				}
				
				for (var destIndex:uint=si; destIndex<ei; destIndex++) {
					if (pixRendered[destIndex] > 0xFF) {
						buffer[destIndex] = bgBuffer[destIndex];
					}
				}
			}
			
			if (f_spVisibility == 1) {
				renderSpritesPartially(startScan, scanCount, false);
			}
			
			validTileData = false;
		}
		
		private function renderBgScanline(useBgBuffer:Boolean, scan:int):void
		{
			var baseTile:uint = (regS === 0 ? 0 : 256);
			var destIndex:int = (scan<<8)-regFH;

			curNt = ntable1[cntV+cntV+cntH];
			
			cntHT = regHT;
			cntH = regH;
			curNt = ntable1[cntV+cntV+cntH];
			
			if (scan<240 && (scan-cntFV)>=0){
				
				var tscanoffset:uint = cntFV<<3;
				var targetBuffer:Vector.<uint> = useBgBuffer ? bgBuffer : buffer;

				var t:Tile, tpix:Vector.<uint>, att:uint, col:uint;

				for (var tile:uint=0;tile<32;tile++) {
					
					if (scan>=0) {
					
						// Fetch tile & attrib data:
						if (validTileData) {
							// Get data from array:
							t = scantile[tile];
							tpix = t.pix;
							att = attrib[tile];
						}else {
							// Fetch data:
							t = ptTile[baseTile+nameTable[curNt].getTileIndex(cntHT,cntVT)];
							tpix = t.pix;
							att = nameTable[curNt].getAttrib(cntHT,cntVT);
							scantile[tile] = t;
							attrib[tile] = att;
						}
						
						// Render tile scanline:
						var sx:int = 0;
						var x:int = (tile<<3)-regFH;

						if (x>-8) {
							if (x<0) {
								destIndex-=x;
								sx = -x;
							}
							if (t.opaque[cntFV]) {
								for (;sx<8;sx++) {
									targetBuffer[destIndex] = imgPalette[
										tpix[tscanoffset+sx]+att
									];
									pixRendered[destIndex] |= 256;
									destIndex++;
								}
							}else {
								for (;sx<8;sx++) {
									col = tpix[tscanoffset+sx];
									if(col !== 0) {
										targetBuffer[destIndex] = imgPalette[
											col+att
										];
										pixRendered[destIndex] |= 256;
									}
									destIndex++;
								}
							}
						}
						
					}
						
					// Increase Horizontal Tile Counter:
					if (++cntHT==32) {
						cntHT=0;
						cntH++;
						cntH%=2;
						curNt = ntable1[(cntV<<1)+cntH];    
					}
					
					
				}
				
				// Tile data for one row should now have been fetched,
				// so the data in the array is valid.
				validTileData = true;
				
			}
			
			// update vertical scroll:
			cntFV++;
			if (cntFV==8) {
				cntFV = 0;
				cntVT++;
				if (cntVT==30) {
					cntVT = 0;
					cntV++;
					cntV%=2;
					curNt = ntable1[(cntV<<1)+cntH];
				}else if (cntVT==32) {
					cntVT = 0;
				}
				
				// Invalidate fetched data:
				validTileData = false;
				
			}
		}
		
		private function renderSpritesPartially(startscan:uint, scancount:uint, bgPri:Boolean):void
		{
			if (f_spVisibility === 1) {
				
				for (var i:uint=0;i<64;i++) {
					if (bgPriority[i]==bgPri && sprX[i]>=0 && 
							sprX[i]<256 && sprY[i]+8>=startscan && 
							sprY[i]<startscan+scancount) {
						// Show sprite.
						if (f_spriteSize === 0) {
							// 8x8 sprites
							
							srcy1 = 0;
							srcy2 = 8;
							
							if (sprY[i]<startscan) {
								srcy1 = startscan - sprY[i]-1;
							}
							
							if (sprY[i]+8 > startscan+scancount) {
								srcy2 = startscan+scancount-sprY[i]+1;
							}
							
							if (f_spPatternTable===0) {
								ptTile[sprTile[i]].render(buffer, 
									0, srcy1, 8, srcy2, sprX[i], 
									sprY[i]+1, sprCol[i], sprPalette, 
									horiFlip[i], vertFlip[i], i, 
									pixRendered
								);
							}else {
								ptTile[sprTile[i]+256].render(buffer, 0, srcy1, 8, srcy2, sprX[i], sprY[i]+1, sprCol[i], sprPalette, horiFlip[i], vertFlip[i], i, pixRendered);
							}
						}else {
							// 8x16 sprites
							var top:uint = sprTile[i];
							if ((top&1)!==0) {
								top = sprTile[i]-1+256;
							}
							
							var srcy1:uint = 0;
							var srcy2:uint = 8;
							
							if (sprY[i]<startscan) {
								srcy1 = startscan - sprY[i]-1;
							}
							
							if (sprY[i]+8 > startscan+scancount) {
								srcy2 = startscan+scancount-sprY[i];
							}
							
							ptTile[top+(vertFlip[i]?1:0)].render(
								buffer,
								0,
								srcy1,
								8,
								srcy2,
								sprX[i],
								sprY[i]+1,
								sprCol[i],
								sprPalette,
								horiFlip[i],
								vertFlip[i],
								i,
								pixRendered
							);
							
							srcy1 = 0;
							srcy2 = 8;
							
							if (sprY[i]+8<startscan) {
								srcy1 = startscan - (sprY[i]+8+1);
							}
							
							if (sprY[i]+16 > startscan+scancount) {
								srcy2 = startscan+scancount-(sprY[i]+8);
							}
							
							ptTile[top+(vertFlip[i]?0:1)].render(
								buffer,
								0,
								srcy1,
								8,
								srcy2,
								sprX[i],
								sprY[i]+1+8,
								sprCol[i],
								sprPalette,
								horiFlip[i],
								vertFlip[i],
								i,
								pixRendered
							);
							
						}
					}
				}
			}
		}
		
		private function checkSprite0(scan:int):Boolean
		{	
			spr0HitX = -1;
			spr0HitY = -1;
			
			var toffset:int;
			var tIndexAdd:uint= (f_spPatternTable === 0?0:256);
			var x:int, y:int, t:Tile, i:int;
			var bufferIndex:int;
			var col:uint;
			var bgPri:Boolean;
			
			x = sprX[0];
			y = sprY[0]+1;
			
			if (f_spriteSize === 0) {
				// 8x8 sprites.

				// Check range:
				if (y <= scan && y + 8 > scan && x >= -7 && x < 256) {
					
					// Sprite is in range.
					// Draw scanline:
					t = ptTile[sprTile[0] + tIndexAdd];
					col = sprCol[0];
					bgPri = bgPriority[0];
					
					if (vertFlip[0]) {
						toffset = 7 - (scan -y);
					}
					else {
						toffset = scan - y;
					}
					toffset *= 8;
					
					bufferIndex = scan * 256 + x;
					if (horiFlip[0]) {
						for (i = 7; i >= 0; i--) {
							if (x >= 0 && x < 256) {
								if (bufferIndex>=0 && bufferIndex<61440 && 
										pixRendered[bufferIndex] !==0 ) {
									if (t.pix[toffset+i] !== 0) {
										spr0HitX = bufferIndex % 256;
										spr0HitY = scan;
										return true;
									}
								}
							}
							x++;
							bufferIndex++;
						}
					}
					else {
						for (i = 0; i < 8; i++) {
							if (x >= 0 && x < 256) {
								if (bufferIndex >= 0 && bufferIndex < 61440 && 
										pixRendered[bufferIndex] !==0 ) {
									if (t.pix[toffset+i] !== 0) {
										spr0HitX = bufferIndex % 256;
										spr0HitY = scan;
										return true;
									}
								}
							}
							x++;
							bufferIndex++;  
						}   
					}
				}
			}
			else {
				// 8x16 sprites:
			
				// Check range:
				if (y <= scan && y + 16 > scan && x >= -7 && x < 256) {
					// Sprite is in range.
					// Draw scanline:
					
					if (vertFlip[0]) {
						toffset = 15-(scan-y);
					}else {
						toffset = scan-y;
					}
					
					if (toffset<8) {
						// first half of sprite.
						t = ptTile[sprTile[0]+(vertFlip[0]?1:0)+((sprTile[0]&1)!==0?255:0)];
					}else {
						// second half of sprite.
						t = ptTile[sprTile[0]+(vertFlip[0]?0:1)+((sprTile[0]&1)!==0?255:0)];
						if (vertFlip[0]) {
							toffset = 15-toffset;
						}
						else {
							toffset -= 8;
						}
					}
					toffset*=8;
					col = sprCol[0];
					bgPri = bgPriority[0];
					
					bufferIndex = scan*256+x;
					if (horiFlip[0]) {
						for (i=7;i>=0;i--) {
							if (x>=0 && x<256) {
								if (bufferIndex>=0 && bufferIndex<61440 && pixRendered[bufferIndex]!==0) {
									if (t.pix[toffset+i] !== 0) {
										spr0HitX = bufferIndex%256;
										spr0HitY = scan;
										return true;
									}
								}
							}
							x++;
							bufferIndex++;
						}
						
					}
					else {
						
						for (i=0;i<8;i++) {
							if (x>=0 && x<256) {
								if (bufferIndex>=0 && bufferIndex<61440 && pixRendered[bufferIndex]!==0) {
									if (t.pix[toffset+i] !== 0) {
										spr0HitX = bufferIndex%256;
										spr0HitY = scan;
										return true;
									}
								}
							}
							x++;
							bufferIndex++;
						}
						
					}
					
				}
				
			}
			
			return false;
		}
		
		// This will write to PPU memory, and
		// update internally buffered data
		// appropriately.
		private function writeMem(address:uint, value:uint):void
		{
			vramMem[address] = value;
			
			// Update internally buffered data:
			if (address < 0x2000) {
				vramMem[address] = value;
				patternWrite(address,value);
			}
			else if (address >=0x2000 && address <0x23c0) {    
				nameTableWrite(ntable1[0], address - 0x2000, value);
			}
			else if (address >=0x23c0 && address <0x2400) {    
				attribTableWrite(ntable1[0],address-0x23c0,value);
			}
			else if (address >=0x2400 && address <0x27c0) {    
				nameTableWrite(ntable1[1],address-0x2400,value);
			}
			else if (address >=0x27c0 && address <0x2800) {    
				attribTableWrite(ntable1[1],address-0x27c0,value);
			}
			else if (address >=0x2800 && address <0x2bc0) {    
				nameTableWrite(ntable1[2],address-0x2800,value);
			}
			else if (address >=0x2bc0 && address <0x2c00) {    
				attribTableWrite(ntable1[2],address-0x2bc0,value);
			}
			else if (address >=0x2c00 && address <0x2fc0) {    
				nameTableWrite(ntable1[3],address-0x2c00,value);
			}
			else if (address >=0x2fc0 && address <0x3000) {
				attribTableWrite(ntable1[3],address-0x2fc0,value);
			}
			else if (address >=0x3f00 && address <0x3f20) {
				updatePalettes();
			}
		}
		
		// Reads data from $3f00 to $f20 
		// into the two buffered palettes.
		private function updatePalettes():void
		{
			var i:uint;
			
			for (i = 0; i < 16; i++) {
				if (f_dispType === 0) {
					imgPalette[i] = palTable.getEntry(
						vramMem[0x3f00 + i] & 63
					);
				}
				else {
					imgPalette[i] = palTable.getEntry(
						vramMem[0x3f00 + i] & 32
					);
				}
			}
			for (i = 0; i < 16; i++) {
				if (f_dispType === 0) {
					sprPalette[i] = palTable.getEntry(
						vramMem[0x3f10 + i] & 63
					);
				}
				else {
					sprPalette[i] = palTable.getEntry(
						vramMem[0x3f10 + i] & 32
					);
				}
			}
		}
		
		// Updates the internal pattern
		// table buffers with this new byte.
		// In vNES, there is a version of this with 4 arguments which isn't used.
		private function patternWrite(address:uint, value:uint):void
		{
			var tileIndex:uint = Math.floor(address / 16);
			var leftOver:uint = address%16;
			if (leftOver<8) {
				ptTile[tileIndex].setScanline(
					leftOver,
					value,
					vramMem[address+8]
				);
			}
			else {
				ptTile[tileIndex].setScanline(
					leftOver-8,
					vramMem[address-8],
					value
				);
			}
		}

		// Updates the internal name table buffers
		// with this new byte.
		private function nameTableWrite(index:uint, address:uint, value:uint):void
		{
			nameTable[index].tile[address] = value;
			
			// Update Sprite #0 hit:
			//updateSpr0Hit();
			checkSprite0(scanline-20);
		}
		
		// Updates the internal pattern
		// table buffers with this new attribute
		// table byte.
		private function attribTableWrite(index:uint, address:uint, value:uint):void
		{
			nameTable[index].writeAttrib(address,value);
		}
		
		// Updates the internally buffered sprite
		// data with this new byte of info.
		private function spriteRamWriteUpdate(address:uint, value:uint):void
		{
			var tIndex:uint = Math.floor(address / 4);
			
			if (tIndex === 0) {
				//updateSpr0Hit();
				checkSprite0(scanline - 20);
			}
			
			if (address % 4 === 0) {
				// Y coordinate
				sprY[tIndex] = value;
			}
			else if (address % 4 == 1) {
				// Tile index
				sprTile[tIndex] = value;
			}
			else if (address % 4 == 2) {
				// Attributes
				vertFlip[tIndex] = ((value & 0x80) !== 0);
				horiFlip[tIndex] = ((value & 0x40) !==0 );
				bgPriority[tIndex] = ((value & 0x20) !== 0);
				sprCol[tIndex] = (value & 3) << 2;
				
			}
			else if (address % 4 == 3) {
				// X coordinate
				sprX[tIndex] = value;
			}
		}
		
		private function doNMI():void
		{
			// Set VBlank flag:
			setStatusFlag(STATUS_VBLANK,true);
			//nes.getCpu().doNonMaskableInterrupt();
			nes.cpu.requestIrq(CPU.IRQ_NMI);
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
		curTable = Vector.<uint>([0x525252, 0x0000B4, 0x0000A0, 0x3D00B1, 
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
		curTable = Vector.<uint>([0x525252, 0xB40000, 0xA00000, 0xB1003D, 
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

