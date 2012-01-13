package player
{
  import flash.display.Sprite;
  import vk.VK;

  /**
   * @author Alexey Kharkov
   */
  internal class VolumeLine extends LineBase
  {
    public static const W:uint = 42;
    
    public function VolumeLine( par:AudioPlayer, x:uint, y:uint ):void
    {
      super( par, x, y, W, true );
    }

    // ----------------------------------------------------------------------- Overrided methods
    internal override function reDraw():void
    {
      VK.Utils.fillRect( line, 0, -5, w, 15, Main.BG_COLOR, 0 );
      VK.Utils.fillRect( line, 0,  0, w, 1, Main.BG_COLOR );
      VK.Utils.fillRect( line, 0,  0, w, 1, COL2, 0.3 + pos * 0.7 );
    }

    internal override function onSlider():void
    {
      reDraw();
      par.onVolumeLine();
    }

  }
}