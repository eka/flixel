package flixel.graphics.frames;

import flash.geom.Rectangle;
import flixel.graphics.FlxGraphic;
import flixel.math.FlxPoint;

/**
 * Collection of clipped frames, which is used for clipping sprites.
 */
class ClippedFrames extends FlxFramesCollection
{
	/**
	 * Clipping rectangle for this frame collection.
	 */
	private var clipRect:Rectangle;
	/**
	 * Original (unclipped) frames.
	 */
	@:isVar
	public var original(get, set):FlxFramesCollection;
	
	private function new(original:FlxFramesCollection, clipRect:Rectangle)
	{
		super(original.parent, FrameCollectionType.CLIPPED);
		
		this.original = original;
		this.clipRect = clipRect;
		clipFrames();
	}
	
	private function clipFrames():Void 
	{
		var frame:FlxFrame;
		var frameRect:Rectangle = new Rectangle();
		var newFrameRect:Rectangle;
		var clippedRect1:Rectangle = new Rectangle();
		var clippedRect2:Rectangle;
		var helperRect:Rectangle = new Rectangle();
		var frameOffset:FlxPoint;
		var frameWidth:Float;
		var frameHeight:Float;
		
		var x:Float, y:Float, w:Float, h:Float;
		
		var rotated:Bool;
		var angle:Float = 0;
		
		for (frame in original.frames)
		{
			frameWidth = frame.sourceSize.x;
			frameHeight = frame.sourceSize.y;
			
			helperRect.setTo(0, 0, frameWidth, frameHeight);
			clippedRect1.setTo(frame.offset.x, frame.offset.y, frame.frame.width, frame.frame.height);
			
			var rotated:Bool = (frame.type == FrameType.ROTATED);
			angle = 0;
			
			if (rotated)
			{
				var rotatedFrame:FlxRotatedFrame = cast frame;
				angle = rotatedFrame.angle;
				
				clippedRect1.width = frame.frame.height;
				clippedRect1.height = frame.frame.width;
			}
			
			clippedRect2 = clippedRect1.intersection(clipRect);		
			frameRect = clippedRect2.intersection(helperRect);
			
			if (frameRect.width == 0 || frameRect.height == 0 || 
				clippedRect2.width == 0 || clippedRect2.height == 0)
			{
				frameRect.setTo(0, 0, frameWidth, frameHeight);
				addEmptyFrame(frameRect);
			}
			else
			{
				frameOffset = FlxPoint.get(clippedRect2.x, clippedRect2.y);
				
				x = frameRect.x;
				y = frameRect.y;
				w = frameRect.width;
				h = frameRect.height;
				
				if (angle == 0)
				{
					frameRect.x -= clippedRect1.x;
					frameRect.y -= clippedRect1.y;
				}
				if (angle == -90)
				{
					frameRect.x = clippedRect1.bottom - y - h;
					frameRect.y = x - clippedRect1.x;
					frameRect.width = h;
					frameRect.height = w;
				}
				else if (angle == 90)
				{
					frameRect.x = y - clippedRect1.y;
					frameRect.y = clippedRect1.right - x - w;
					frameRect.width = h;
					frameRect.height = w;
				}
				
				frameRect.x += frame.frame.x;
				frameRect.y += frame.frame.y;
				
				addAtlasFrame(frameRect, FlxPoint.get(frameWidth, frameHeight), frameOffset, frame.name, angle);
			}
		}
	}
	
	private function get_original():FlxFramesCollection
	{
		if (original != null && original.type == FrameCollectionType.CLIPPED)
		{
			var originalFrames:FlxFramesCollection = cast(original, ClippedFrames).original;
			if (originalFrames != null)
			{
				return originalFrames;
			}
		}
		
		return original;
	}
	
	private function set_original(value:FlxFramesCollection):FlxFramesCollection
	{
		return original = value;
	}
	
	/**
	 * Generates clipped version of provided frames collection.
	 * 
	 * @param	frames			Frames collection to clip.
	 * @param	clipRect		Clipping rectangle which will be applied to frames.
	 * @param	useOriginal		Whether to use "unclipped" version of frames (if provided frames collection is ClippedFrames collection).
	 * @return	Clipped version of frames.
	 */
	public static function clip(frames:FlxFramesCollection, clipRect:Rectangle, useOriginal:Bool = true):ClippedFrames
	{
		if (useOriginal && frames.type == FrameCollectionType.CLIPPED)
		{
			var original:FlxFramesCollection = cast(frames, ClippedFrames).original;
			if (original != null)
			{
				frames = original;
			}
		}
		
		var clippedFrames:ClippedFrames = ClippedFrames.findFrame(frames, clipRect);
		if (clippedFrames != null)
		{
			return clippedFrames;
		}
		
		return new ClippedFrames(frames, clipRect);
	}
	
	/**
	 * Searches ClippedFrames object for specified frames collection.
	 * 
	 * @param	frames			FlxFramesCollection object to search clipped frames for.
	 * @param	clipRect		Clipping rectangle.
	 * @return	ClippedFrames object which corresponds to specified arguments. Could be null if there is no such ClippedFrames object.
	 */
	public static function findFrame(frames:FlxFramesCollection, clipRect:Rectangle):ClippedFrames
	{
		var clippedFramesArr:Array<ClippedFrames> = cast frames.parent.getFramesCollections(FrameCollectionType.CLIPPED);
		var clippedFrames:ClippedFrames;
		
		for (clippedFrames in clippedFramesArr)
		{
			if (clippedFrames.equals(frames, clipRect))
			{
				return clippedFrames;
			}
		}
		
		return null;
	}
	
	/**
	 * ClippedFrames comparison method. For internal use.
	 */
	public function equals(original:FlxFramesCollection, clipRect:Rectangle):Bool
	{
		return (this.original == original && this.clipRect.equals(clipRect));
	}
	
	override public function destroy():Void 
	{
		super.destroy();
		clipRect = null;
		original = null;
	}
	
}