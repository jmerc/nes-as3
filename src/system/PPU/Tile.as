package system.PPU 
{
	/**
	 * ...
	 * @author ...
	 */
	public class Tile 
	{
		public var pix:Array;
		private var fbIndex:uint;
		private var tIndex:uint;
		private var x:uint;
		private var y:uint;
		private var w:uint;
		private var h:uint;
		private var incX:uint;
		private var incY:uint;
		private var palIndex:uint;
		private var tpri:uint;
		private var c:uint;
		private var initialized:Boolean;
		public var opaque:Array;
		
		public function Tile()
		{
			// Tile data:
			pix = new Array(64);
			
			fbIndex = 0;
			tIndex = 0;
			x = 0;
			y = 0;
			w = 0;
			h = 0;
			incX = 0;
			incY = 0;
			palIndex = 0;
			tpri = 0;
			c = 0;
			initialized = false;
			opaque = new Array(8);
		}
		
		private function setBuffer(scanline:uint):void
		{
			for (y=0;y<8;y++) {
				setScanline(y,scanline[y],scanline[y+8]);
			}
		}
		
		public function setScanline(sline:uint, b1:uint, b2:uint):void
		{
			initialized = true;
			tIndex = sline<<3;
			for (x = 0; x < 8; x++) {
				pix[tIndex + x] = ((b1 >> (7 - x)) & 1) +
						(((b2 >> (7 - x)) & 1) << 1);
				if(pix[tIndex+x] === 0) {
					opaque[sline] = false;
				}
			}
		}
		
		public function render(buffer:Vector.<uint>, srcx1:uint, srcy1:uint, srcx2:uint, srcy2:uint, dx:uint, dy:uint, 
								palAdd:uint, palette:Vector.<uint>, flipHorizontal:Boolean, flipVertical:Boolean, pri:uint, priTable:Vector.<uint>):void
								
		{

			if (dx<-7 || dx>=256 || dy<-7 || dy>=240) {
				return;
			}

			w=srcx2-srcx1;
			h=srcy2-srcy1;
		
			if (dx<0) {
				srcx1-=dx;
			}
			if (dx+srcx2>=256) {
				srcx2=256-dx;
			}
		
			if (dy<0) {
				srcy1-=dy;
			}
			if (dy+srcy2>=240) {
				srcy2=240-dy;
			}
		
			if (!flipHorizontal && !flipVertical) {
			
				fbIndex = (dy<<8)+dx;
				tIndex = 0;
				for (y=0;y<8;y++) {
					for (x=0;x<8;x++) {
						if (x>=srcx1 && x<srcx2 && y>=srcy1 && y<srcy2) {
							palIndex = pix[tIndex];
							tpri = priTable[fbIndex];
							if (palIndex!==0 && pri<=(tpri&0xFF)) {
								//console.log("Rendering upright tile to buffer");
								buffer[fbIndex] = palette[palIndex+palAdd];
								tpri = (tpri&0xF00)|pri;
								priTable[fbIndex] =tpri;
							}
						}
						fbIndex++;
						tIndex++;
					}
					fbIndex-=8;
					fbIndex+=256;
				}
			
			}else if (flipHorizontal && !flipVertical) {
			
				fbIndex = (dy<<8)+dx;
				tIndex = 7;
				for (y=0;y<8;y++) {
					for (x=0;x<8;x++) {
						if (x>=srcx1 && x<srcx2 && y>=srcy1 && y<srcy2) {
							palIndex = pix[tIndex];
							tpri = priTable[fbIndex];
							if (palIndex!==0 && pri<=(tpri&0xFF)) {
								buffer[fbIndex] = palette[palIndex+palAdd];
								tpri = (tpri&0xF00)|pri;
								priTable[fbIndex] =tpri;
							}
						}
						fbIndex++;
						tIndex--;
					}
					fbIndex-=8;
					fbIndex+=256;
					tIndex+=16;
				}
			
			}
			else if(flipVertical && !flipHorizontal) {
			
				fbIndex = (dy<<8)+dx;
				tIndex = 56;
				for (y=0;y<8;y++) {
					for (x=0;x<8;x++) {
						if (x>=srcx1 && x<srcx2 && y>=srcy1 && y<srcy2) {
							palIndex = pix[tIndex];
							tpri = priTable[fbIndex];
							if (palIndex!==0 && pri<=(tpri&0xFF)) {
								buffer[fbIndex] = palette[palIndex+palAdd];
								tpri = (tpri&0xF00)|pri;
								priTable[fbIndex] =tpri;
							}
						}
						fbIndex++;
						tIndex++;
					}
					fbIndex-=8;
					fbIndex+=256;
					tIndex-=16;
				}
			
			}
			else {
				fbIndex = (dy<<8)+dx;
				tIndex = 63;
				for (y=0;y<8;y++) {
					for (x=0;x<8;x++) {
						if (x>=srcx1 && x<srcx2 && y>=srcy1 && y<srcy2) {
							palIndex = pix[tIndex];
							tpri = priTable[fbIndex];
							if (palIndex!==0 && pri<=(tpri&0xFF)) {
								buffer[fbIndex] = palette[palIndex+palAdd];
								tpri = (tpri&0xF00)|pri;
								priTable[fbIndex] =tpri;
							}
						}
						fbIndex++;
						tIndex--;
					}
					fbIndex-=8;
					fbIndex+=256;
				}
			
			}
		
		}
		
		private function isTransparent(x:uint, y:uint):Boolean
		{
			return (pix[(y << 3) + x] === 0);
		}

		
	}

}