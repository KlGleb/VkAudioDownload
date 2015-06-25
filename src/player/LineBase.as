package player {
import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.Event;

/**
 * @author Alexey Kharkov
 */
internal class LineBase extends Sprite {
    internal static const COL1:uint = 0xdae2e8;
    internal static const COL2:uint = 0x5f7d9d;

    private var slider:Slider = null;
    private var _ratio:Number = 0;

    internal var par:AudioPlayer = null;
    internal var line:Sprite = null;
    internal var w:uint = 0;

    public function LineBase(par:AudioPlayer, x:uint, y:uint, w:uint, isVolume:Boolean):void {
        this.par = par;
        this.x = x;
        this.y = y;
        this.w = w;

        line = new Sprite();
        addChild(line);

        slider = new Slider(isVolume, w);
        addChild(slider);

        ratio = isVolume ? 1 : 0;

        reDraw();
        buttonMode = true;

        line.addEventListener(MouseEvent.MOUSE_DOWN, onDown);
    }

    public function set ratio(val:Number):void {
        _ratio = val;
    }

    public function get ratio():Number {
        return _ratio;
    }

    public function set pos(val:Number):void {
        slider.pos = val;
        reDraw();
    }

    public function get pos():Number {
        return slider.pos;
    }

    public function setPaused(b:Boolean):void {
        slider.setPaused(b);
    }

    // ----------------------------------------------------------------------- Virtual methods
    internal virtual function reDraw():void {
    }

    internal virtual function onSlider():void {
    }

    internal function get maxX():int {
        return slider.maxX * ratio;
    }

    // ----------------------------------------------------------------------- Event handlers
    private function onDown(e:MouseEvent):void {
        var xx:int = e.localX - slider.width / 2;
        slider.x = Math.round(Math.max(0, Math.min(xx, maxX)));

        if (xx <= maxX)
            slider.startSlide(e.stageX);
        else
            onSlider();
    }
}
}