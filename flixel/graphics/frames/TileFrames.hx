package flixel.graphics.frames;

import flash.display.BitmapData;
import flash.geom.Point;
import flash.geom.Rectangle;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FrameCollectionType;
import flixel.system.layer.TileSheetExt;
import flixel.math.FlxPoint;
import flixel.graphics.FlxGraphic;
import flixel.util.FlxBitmapDataUtil;

// TODO: use FlxPoint and FlxRect as method arguments
// in this and other frames related classes.

/**
 * Spritesheet frame collection. It is used for tilemaps and animated sprites. 
 */
class TileFrames extends FlxFramesCollection
{
	public static var POINT1:Point = new Point();
	public static var POINT2:Point = new Point();
	
	public static var RECT:Rectangle = new Rectangle();
	
	/**
	 * Atlas frame from which this frame collection had been generated.
	 * Could be null if this collection generated from rectangle.
	 */
	private var atlasFrame:FlxFrame;
	/**
	 * image region of image from which this frame collection had been generated.
	 */
	private var region:Rectangle;
	/**
	 * The size of frame in this spritesheet.
	 */
	private var frameSize:Point;
	/**
	 * offsets between frames in this spritesheet.
	 */
	private var frameSpacing:Point;
	
	public var numRows:Int = 0;
	
	public var numCols:Int = 0;
	
	private function new(parent:FlxGraphic) 
	{
		super(parent, FrameCollectionType.TILES);
	}
	
	/**
	 * Gets source bitmapdata, generates new bitmapdata with spaces between frames (if there is no such bitmapdata in the cache already) 
	 * and creates TileFrames collection.
	 * 
	 * @param	source			the source of graphic for frame collection (can be String, BitmapData or FlxGraphic).
	 * @param	frameSize		the size of tiles in spritesheet
	 * @param	frameSpacing	desired offsets between frames in spritesheet
	 * 							(this method takes spritesheet bitmap without offsets between frames and adds them).
	 * @param	region			Region of image to generate spritesheet from. Default value is null, which means that
	 * 							whole image will be used for spritesheet generation
	 * @return	Newly created spritesheet
	 */
	// TODO: make it accept only FlxGraphic, String, or BitmapData
	public static function fromBitmapWithSpacings(source:Dynamic, frameSize:Point, frameSpacing:Point, region:Rectangle = null):TileFrames
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(source, false);
		if (graphic == null) return null;
		
		var key:String = FlxG.bitmap.getKeyWithSpacings(graphic.key, frameSize, frameSpacing, region);
		var result:FlxGraphic = FlxG.bitmap.get(key);
		if (result == null)
		{
			var bitmap:BitmapData = FlxBitmapDataUtil.addSpacing(graphic.bitmap, frameSize, frameSpacing, region);
			result = FlxG.bitmap.add(bitmap, false, key);
		}
		
		return TileFrames.fromRectangle(result, frameSize, null, frameSpacing);
	}
	
	/**
	 * Generates spritesheet frame collection from provided frame. Can be usefull for spritesheets packed into atlases.
	 * It can generate spritesheets from rotated and cropped frames also, which is important for devices with small amount of memory.
	 * 
	 * @param	frame			frame, containg spritesheet image
	 * @param	frameSize		the size of tiles in spritesheet
	 * @param	frameSpacing	offsets between frames in spritesheet. Default value is null, which means no offsets between tiles
	 * @return	Newly created spritesheet frame collection.
	 */
	// TODO: rework frame generation algorithm (make it more compact).
	public static function fromFrame(frame:FlxFrame, frameSize:Point, frameSpacing:Point = null):TileFrames
	{
		var graphic:FlxGraphic = frame.parent;
		// find TileFrames object, if there is one already
		var tileFrames:TileFrames = TileFrames.findFrame(graphic, frameSize, null, frame, frameSpacing);
		if (tileFrames != null)
		{
			return tileFrames;
		}
		
		// or create it, if there is no such object
		frameSpacing = (frameSpacing != null) ? frameSpacing : new Point();
		
		tileFrames = new TileFrames(graphic);
		tileFrames.atlasFrame = frame;
		tileFrames.region = frame.frame;
		tileFrames.frameSize = frameSize;
		tileFrames.frameSpacing = frameSpacing;
		
		var bitmapWidth:Int = Std.int(frame.sourceSize.x);
		var bitmapHeight:Int = Std.int(frame.sourceSize.y);
		
		var xSpacing:Int = Std.int(frameSpacing.x);
		var ySpacing:Int = Std.int(frameSpacing.y);
		
		var frameWidth:Int = Std.int(frameSize.x);
		var frameHeight:Int = Std.int(frameSize.y);
		
		var spacedWidth:Int = frameWidth + xSpacing;
		var spacedHeight:Int = frameHeight + ySpacing;
		
		var clippedRect:Rectangle = new Rectangle(frame.offset.x, frame.offset.y, frame.frame.width, frame.frame.height);
		
		var helperRect:Rectangle = new Rectangle(0, 0, frameWidth, frameHeight);
		var tileRect:Rectangle;
		var frameOffset:FlxPoint;
		
		var rotated:Bool = (frame.type == FrameType.ROTATED);
		var angle:Float = 0;
		
		var numRows:Int = (frameHeight == 0) ? 1 : Std.int((bitmapHeight + ySpacing) / spacedHeight);
		var numCols:Int = (frameWidth == 0) ? 1 : Std.int((bitmapWidth + xSpacing) / spacedWidth);
		
		var startX:Int = 0;
		var startY:Int = 0;
		var dX:Int = spacedWidth;
		var dY:Int = spacedHeight;
		
		if (rotated)
		{
			var rotatedFrame:FlxRotatedFrame = cast frame;
			angle = rotatedFrame.angle;
			
			if (angle == -90)
			{
				startX = bitmapHeight - spacedHeight;
				startY = 0;
				dX = -spacedHeight;
				dY = spacedWidth;
				
				clippedRect.x = frame.sourceSize.y - frame.offset.y - frame.frame.width;
				clippedRect.y = frame.offset.x;
			}
			else if (angle == 90)
			{
				startX = 0;
				startY = bitmapWidth - spacedWidth;
				dX = spacedHeight;
				dY = -spacedWidth;
				clippedRect.x = frame.offset.y;
				clippedRect.y = frame.sourceSize.x - frame.offset.x - frame.frame.height;
			}
			
			helperRect.width = frameHeight;
			helperRect.height = frameWidth;
		}
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))	
			{
				helperRect.x = startX + dX * ((angle == 0) ? i : j);
				helperRect.y = startY + dY * ((angle == 0) ? j : i);
				tileRect = clippedRect.intersection(helperRect);
				
				if (tileRect.width == 0 || tileRect.height == 0)
				{
					tileRect.setTo(0, 0, frameWidth, frameHeight);
					tileFrames.addEmptyFrame(tileRect);
				}
				else
				{
					if (angle == 0)
					{
						frameOffset = FlxPoint.get(tileRect.x - helperRect.x, tileRect.y - helperRect.y);
					}
					else if (angle == -90)
					{
						frameOffset = FlxPoint.get(tileRect.y - helperRect.y, tileRect.x - helperRect.x);
					}
					else // angle == 90
					{
						frameOffset = FlxPoint.get(helperRect.bottom - tileRect.bottom, tileRect.x - helperRect.x);
					}
					tileRect.x += frame.frame.x - clippedRect.x;
					tileRect.y += frame.frame.y - clippedRect.y;
					tileFrames.addAtlasFrame(tileRect, FlxPoint.get(frameWidth, frameHeight), frameOffset, null, angle);
				}
			}
		}
		
		tileFrames.numCols = numCols;
		tileFrames.numRows = numRows;
		return tileFrames;
	}
	
	/**
	 * Generates spritesheet frame collection from provided region of image.
	 * 
	 * @param	graphic			source graphic for spritesheet.
	 * @param	frameSize		the size of tiles in spritesheet.
	 * @param	region			region of image to use for spritesheet generation. Default value is null,
	 * 							which means that the whole image will be used for it.
	 * @param	frameSpacing	offsets between frames in spritesheet. Default value is null, which means no offsets between tiles
	 * @return	Newly created spritesheet frame collection.
	 */
	public static function fromGraphic(graphic:FlxGraphic, frameSize:Point, region:Rectangle = null, frameSpacing:Point = null):TileFrames
	{
		// find TileFrames object, if there is one already
		var tileFrames:TileFrames = TileFrames.findFrame(graphic, frameSize, region, null, frameSpacing);
		if (tileFrames != null)
		{
			return tileFrames;
		}
		
		// or create it, if there is no such object
		if (region == null)
		{
			region = graphic.bitmap.rect;
		}
		else
		{
			if (region.width == 0)
			{
				region.width = graphic.width - region.x;
			}
			
			if (region.height == 0)
			{
				region.height = graphic.height - region.y;
			}
		}
		
		frameSpacing = (frameSpacing != null) ? frameSpacing : new Point();
		
		tileFrames = new TileFrames(graphic);
		tileFrames.region = region;
		tileFrames.atlasFrame = null;
		tileFrames.frameSize = frameSize;
		tileFrames.frameSpacing = frameSpacing;
		
		var bitmapWidth:Int = Std.int(region.width);
		var bitmapHeight:Int = Std.int(region.height);
		
		var startX:Int = Std.int(region.x);
		var startY:Int = Std.int(region.y);
		
		var xSpacing:Int = Std.int(frameSpacing.x);
		var ySpacing:Int = Std.int(frameSpacing.y);
		
		var width:Int = Std.int(frameSize.x);
		var height:Int = Std.int(frameSize.y);
		
		var spacedWidth:Int = width + xSpacing;
		var spacedHeight:Int = height + ySpacing;
		
		var numRows:Int = (height == 0) ? 1 : Std.int((bitmapHeight + ySpacing) / spacedHeight);
		var numCols:Int = (width == 0) ? 1 : Std.int((bitmapWidth + xSpacing) / spacedWidth);
		
		var tileRect:Rectangle;
		
		for (j in 0...(numRows))
		{
			for (i in 0...(numCols))
			{
				tileRect = new Rectangle(startX + i * spacedWidth, startY + j * spacedHeight, width, height);
				tileFrames.addSpriteSheetFrame(tileRect);
			}
		}
		
		tileFrames.numCols = numCols;
		tileFrames.numRows = numRows;
		return tileFrames;
	}
	
	/**
	 * Generates spritesheet frame collection from provided region of image.
	 * 
	 * @param	source			source graphic for spritesheet.
	 * 							It can be BitmapData, String or FlxGraphic.
	 * @param	frameSize		the size of tiles in spritesheet.
	 * @param	region			region of image to use for spritesheet generation. Default value is null,
	 * 							which means that whole image will be used for it.
	 * @param	frameSpacing	offsets between frames in spritesheet. Default value is null, which means no offsets between tiles
	 * @return	Newly created spritesheet frame collection
	 */
	// TODO: make it accept only FlxGraphic, String, or BitmapData
	public static function fromRectangle(source:Dynamic, frameSize:Point, region:Rectangle = null, frameSpacing:Point = null):TileFrames
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(source, false);
		if (graphic == null)	return null;
		return fromGraphic(graphic, frameSize, region, frameSpacing);
	}
	
	/**
	 * Searches TileFrames object for specified FlxGraphic object which have the same parameters (frame size, frame spacings, region of image, etc.).
	 * 
	 * @param	graphic			FlxGraphic object to search TileFrames for.
	 * @param	frameSize		The size of tiles in TileFrames.
	 * @param	region			The region of source image used for spritesheet generation.
	 * @param	atlasFrame		Optional FlxFrame object used for spritesheet generation.
	 * @param	frameSpacing	Spaces between tiles in spritesheet.
	 * @return	ImageFrame object which corresponds to specified arguments. Could be null if there is no such TileFrames.
	 */
	public static function findFrame(graphic:FlxGraphic, frameSize:Point, region:Rectangle = null, atlasFrame:FlxFrame = null, frameSpacing:Point = null):TileFrames
	{
		var tileFrames:Array<TileFrames> = cast graphic.getFramesCollections(FrameCollectionType.TILES);
		var sheet:TileFrames;
		
		for (sheet in tileFrames)
		{
			if (sheet.equals(frameSize, region, null, frameSpacing))
			{
				return sheet;
			}
		}
		
		return null;
	}
	
	/**
	 * TileFrames comparison method. For internal use.
	 */
	public function equals(frameSize:Point, region:Rectangle = null, atlasFrame:FlxFrame = null, frameSpacing:Point = null):Bool
	{
		if (atlasFrame != null)
		{
			region = atlasFrame.frame;
		}
		
		if (region == null)
		{
			region = RECT;
			RECT.x = RECT.y = 0;
			RECT.width = parent.width;
			RECT.height = parent.height;
		}
		
		if (frameSpacing == null)
		{
			frameSpacing = POINT1;
			POINT1.x = POINT1.y = 0;
		}
		
		return (this.atlasFrame == atlasFrame && this.region.equals(region) && this.frameSize.equals(frameSize) && this.frameSpacing.equals(frameSpacing));
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		atlasFrame = null;
		region = null;
		frameSize = null;
		frameSpacing = null;
	}
}