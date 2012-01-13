package player
{
  import flash.display.Sprite;
  import vk.VK;

  /**
   * @author Alexey Kharkov
   */
  internal class ProgressLine extends LineBase
  {
    public function ProgressLine( par:AudioPlayer, x:uint, y:uint, w:uint ):void
    {
      super( par, x, y, w, false );
    }
    
    // ----------------------------------------------------------------------- Overrided methods
    internal override function reDraw():void
    {
      VK.Utils.fillRect( line, 0, -5, w, 15, Main.BG_COLOR, 0 );
      VK.Utils.fillRect( line, 0,  0, w, 1, COL1 );
      VK.Utils.fillRect( line, 0,  0, w * ratio, 1, COL2 );
    }

    internal override function onSlider():void
    {
      reDraw();
      par.onProgressLine();
    }
    
  }
}